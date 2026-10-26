#!/usr/bin/env python3
"""Fetch permitted RSS feeds and upsert short, attributed article metadata to Supabase.
No third-party Python dependencies. Never place the service role key in source control.
"""
from __future__ import annotations
import argparse, email.utils, html, json, os, re, sys, time
from datetime import datetime, timezone
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import urlparse
from urllib.request import Request, urlopen
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent
CONFIG = json.loads((ROOT / "sources.json").read_text(encoding="utf-8"))
FENER_TERMS = ("fenerbahçe", "fenerbahce", "sarı-lacivert", "sari-lacivert")
SPORT_TERMS = [
    (("kadın futbol", "kadin futbol"), "kadin-futbol"),
    (("basketbol",), "basketbol"), (("voleybol",), "voleybol"),
    (("yüzme", "yuzme"), "yuzme"), (("atletizm",), "atletizm"),
    (("kürek", "kurek"), "kures"), (("yelken",), "yelken"),
    (("boks",), "boks"), (("masa tenisi",), "masa-tenisi"),
    (("tenis",), "tenis"), (("eskrim",), "eskrim"),
    (("jimnastik",), "jimnastik"), (("güreş", "gures"), "gures"),
]

def clean_text(value: str | None) -> str:
    if not value: return ""
    value = re.sub(r"(?is)<(script|style).*?>.*?</\1>", " ", value)
    value = re.sub(r"(?s)<[^>]+>", " ", value)
    value = html.unescape(value)
    return re.sub(r"\s+", " ", value).strip()

def normalized(value: str) -> str:
    return value.casefold().replace("ı", "i").replace("ş", "s").replace("ğ", "g").replace("ü", "u").replace("ö", "o").replace("ç", "c")

def classify_sport(text: str, default: str) -> str:
    norm = normalized(text)
    for words, slug in SPORT_TERMS:
        if any(normalized(w) in norm for w in words): return slug
    return default

def parse_date(raw: str | None) -> str | None:
    if raw:
        try:
            dt = email.utils.parsedate_to_datetime(raw)
            if dt.tzinfo is None: dt = dt.replace(tzinfo=timezone.utc)
            return dt.astimezone(timezone.utc).isoformat(timespec="seconds")
        except (TypeError, ValueError, OverflowError):
            try:
                dt = datetime.fromisoformat(raw.replace("Z", "+00:00"))
                if dt.tzinfo is None: dt = dt.replace(tzinfo=timezone.utc)
                return dt.astimezone(timezone.utc).isoformat(timespec="seconds")
            except ValueError: pass
    return None

def parse_feed(xml_bytes: bytes, feed: dict, max_summary: int = 360) -> list[dict]:
    root = ET.fromstring(xml_bytes)
    items = root.findall(".//item")
    # Atom feeds are handled too, although configured feeds are RSS.
    if not items:
        ns = {"a": "http://www.w3.org/2005/Atom"}
        items = root.findall(".//a:entry", ns)
        atom = True
    else: atom = False
    output = []
    for item in items:
        if atom:
            get = lambda key: (item.findtext(f"a:{key}", default="", namespaces={"a":"http://www.w3.org/2005/Atom"}) or "")
            title, desc, published = get("title"), get("summary"), get("updated") or get("published")
            link_el = item.find("a:link", {"a":"http://www.w3.org/2005/Atom"})
            link = link_el.attrib.get("href", "") if link_el is not None else ""
        else:
            title = item.findtext("title", default="") or ""
            desc = item.findtext("description", default="") or item.findtext("{http://purl.org/rss/1.0/modules/content/}encoded", default="") or ""
            published = item.findtext("pubDate", default="") or item.findtext("published", default="")
            link = item.findtext("link", default="") or ""
        title = clean_text(title)
        summary = clean_text(desc)[:max_summary]
        full_text = f"{title} {summary}"
        if not title or not link or urlparse(link).scheme not in ("https", "http"): continue
        if feed.get("must_mention_fenerbahce", True) and not any(t in normalized(full_text) for t in ("fenerbahce", "sari-lacivert")): continue
        sport = classify_sport(full_text, feed.get("default_sport", "genel"))
        output.append({
            "title": title[:250], "summary": summary,
            "sport_slug": sport, "source_name": feed["name"],
            "canonical_url": link.strip(), "published_at": parse_date(published),
            "language": "tr"
        })
    return output

def fetch(url: str, timeout: int = 18) -> bytes:
    req = Request(url, headers={"User-Agent": CONFIG.get("user_agent", "FenerVerseFreeBot/1.0"), "Accept": "application/rss+xml, application/xml, text/xml;q=0.9, */*;q=0.5"})
    with urlopen(req, timeout=timeout) as response:
        if response.status != 200: raise RuntimeError(f"HTTP status {response.status}")
        data = response.read(4_000_000)
        if not data: raise RuntimeError("Empty feed")
        return data

def upsert(rows: list[dict], base_url: str, service_key: str) -> int:
    import urllib.parse
    endpoint = base_url.rstrip("/") + "/rest/v1/articles?on_conflict=canonical_url"
    payload = json.dumps(rows, ensure_ascii=False).encode("utf-8")
    req = Request(endpoint, data=payload, method="POST", headers={
        "apikey": service_key, "Authorization": f"Bearer {service_key}",
        "Content-Type": "application/json", "Prefer": "resolution=merge-duplicates,return=minimal"
    })
    with urlopen(req, timeout=25) as response:
        if response.status not in (200, 201, 204): raise RuntimeError(f"Supabase returned HTTP {response.status}")
        return len(rows)

def log_run(base_url: str, service_key: str, status: str, seen: int, written: int, message: str) -> None:
    try:
        endpoint = base_url.rstrip("/") + "/rest/v1/automation_runs"
        row = [{"job_name": "rss_sync", "status": status, "items_seen": seen,
                "items_written": written, "message": message[:500],
                "started_at": RUN_STARTED, "finished_at": datetime.now(timezone.utc).isoformat(timespec="seconds")}]
        req = Request(endpoint, data=json.dumps(row).encode("utf-8"), method="POST", headers={
            "apikey": service_key, "Authorization": f"Bearer {service_key}",
            "Content-Type": "application/json", "Prefer": "return=minimal"})
        with urlopen(req, timeout=10) as response:
            if response.status not in (200, 201, 204): raise RuntimeError(f"HTTP {response.status}")
    except Exception as exc:
        print(f"WARN automation_runs kaydı yazılamadı: {exc}", file=sys.stderr)

RUN_STARTED = datetime.now(timezone.utc).isoformat(timespec="seconds")

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true", help="Fetch and print counts without writing to Supabase")
    args = parser.parse_args()
    base = os.environ.get("SUPABASE_URL", "").strip()
    key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "").strip()
    if not args.dry_run and (not base or not key):
        print("ERROR: SUPABASE_URL ve SUPABASE_SERVICE_ROLE_KEY ortam değişkenleri gerekli.", file=sys.stderr)
        return 2
    seen, rows, failures = 0, {}, []
    for feed in CONFIG["feeds"]:
        try:
            entries = parse_feed(fetch(feed["url"]), feed, int(CONFIG.get("summary_max_chars", 360)))[:int(CONFIG.get("max_items_per_feed", 80))]
            seen += len(entries)
            for entry in entries: rows[entry["canonical_url"]] = entry
            print(f"OK {feed['name']}: {len(entries)} kayıt")
        except Exception as exc:  # one failed source should not block other feeds
            failures.append((feed["name"], str(exc)))
            print(f"WARN {feed['name']}: {exc}", file=sys.stderr)
    deduped = list(rows.values())
    written = 0
    if args.dry_run:
        print("DRY RUN: veritabanına yazılmadı.")
        for row in deduped[:5]: print(" -", row["sport_slug"], row["title"][:100])
    elif deduped:
        written = upsert(deduped, base, key)
        print(f"Supabase upsert tamamlandı: {written} benzersiz adres")
    status = "failed" if failures and not deduped else ("partial" if failures else "success")
    if not args.dry_run and base and key:
        log_run(base, key, status, seen, written, "; ".join(f"{n}: {e}" for n, e in failures) or "RSS senkronizasyonu tamamlandı")
    print(f"Özet: {seen} feed kaydı, {len(deduped)} benzersiz içerik, {len(failures)} kaynak hatası")
    return 1 if failures and not deduped else 0

if __name__ == "__main__": raise SystemExit(main())
