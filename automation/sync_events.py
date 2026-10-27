
import json
import os
import sys
import time
import urllib.parse
import urllib.request
from datetime import datetime, timezone

SPORTSDB_BASE = "https://www.thesportsdb.com/api/v1/json/123"
SUPABASE_URL = os.environ["SUPABASE_URL"].rstrip("/")
SUPABASE_KEY = os.environ["SUPABASE_SERVICE_ROLE_KEY"]

# Takım adları kaynakta bulunamazsa ilgili takım için maç eklenmez.
# Bu liste, otomasyonun desteklediği arama hedefleridir.
TEAMS = [
    ("Fenerbahce", "futbol"),
    ("Fenerbahce Basketball", "basketbol"),
    ("Fenerbahce Beko", "basketbol"),
    ("Fenerbahce Women", "basketbol"),
    ("Fenerbahce Opet", "voleybol"),
    ("Fenerbahce Medicana", "voleybol"),
    ("Fenerbahce Women's Volleyball", "voleybol"),
    ("Fenerbahce Women's Football", "kadin-futbol"),
    ("Fenerbahce Athletics", "atletizm"),
    ("Fenerbahce Swimming", "yuzme"),
    ("Fenerbahce Rowing", "kures"),
    ("Fenerbahce Sailing", "yelken"),
    ("Fenerbahce Boxing", "boks"),
    ("Fenerbahce Table Tennis", "masa-tenisi"),
    ("Fenerbahce Tennis", "tenis"),
    ("Fenerbahce Fencing", "eskrim"),
    ("Fenerbahce Gymnastics", "jimnastik"),
    ("Fenerbahce Wrestling", "gures"),
    ("Fenerbahce Judo", "judo"),
]

def get_json(url):
    request = urllib.request.Request(
        url,
        headers={"User-Agent": "FenerVerse/1.0", "Accept": "application/json"},
    )
    with urllib.request.urlopen(request, timeout=25) as response:
        return json.loads(response.read().decode("utf-8"))

def parse_time(date_text, time_text):
    if not date_text:
        return None

    raw = date_text.strip()
    if time_text:
        raw += " " + time_text.strip()

    for fmt in ("%Y-%m-%d %H:%M:%S", "%Y-%m-%d %H:%M", "%Y-%m-%d"):
        try:
            value = datetime.strptime(raw, fmt).replace(tzinfo=timezone.utc)
            return value.isoformat()
        except ValueError:
            continue

    return None

def find_team(team_name):
    url = SPORTSDB_BASE + "/searchteams.php?" + urllib.parse.urlencode(
        {"t": team_name}
    )
    data = get_json(url)
    teams = data.get("teams") or []

    wanted = team_name.casefold()
    for team in teams:
        name = (team.get("strTeam") or "").casefold()
        if name == wanted:
            return team

    return teams[0] if teams else None

def fetch_events(team_id):
    url = SPORTSDB_BASE + "/eventsnext.php?" + urllib.parse.urlencode(
        {"id": team_id}
    )
    data = get_json(url)
    return data.get("events") or []

def normalize_event(event, sport_slug, team_name):
    event_id = event.get("idEvent")
    home = (event.get("strHomeTeam") or "").strip()
    away = (event.get("strAwayTeam") or "").strip()

    if not event_id or not home or not away:
        return None

    title = (event.get("strEvent") or f"{home} - {away}").strip()
    date_value = parse_time(
        event.get("dateEvent") or "",
        event.get("strTime") or "",
    )

    status_text = (event.get("strStatus") or "").casefold()
    home_score = to_int(event.get("intHomeScore"))
    away_score = to_int(event.get("intAwayScore"))

    if "postponed" in status_text:
        status = "postponed"
    elif "cancel" in status_text:
        status = "cancelled"
    elif "finished" in status_text or "ft" == status_text:
        status = "finished"
    elif status_text in ("1h", "2h", "ht", "live", "in progress"):
        status = "live"
    elif home_score is not None and away_score is not None:
        status = "finished"
    else:
        status = "scheduled"

    return {
        "external_id": f"thesportsdb:{event_id}",
        "title": title,
        "sport_slug": sport_slug,
        "home_team": home,
        "away_team": away,
        "starts_at": date_value,
        "status": status,
        "home_score": home_score,
        "away_score": away_score,
        "source_name": "TheSportsDB",
        "source_url": (
            "https://www.thesportsdb.com/event/" + str(event_id)
        ),
        "updated_at": datetime.now(timezone.utc).isoformat(),
    }

def to_int(value):
    if value in (None, "", "null"):
        return None
    try:
        return int(value)
    except (TypeError, ValueError):
        return None

def upsert_events(rows):
    if not rows:
        return 0

    url = SUPABASE_URL + "/rest/v1/events?on_conflict=external_id"
    body = json.dumps(rows).encode("utf-8")

    request = urllib.request.Request(
        url,
        data=body,
        method="POST",
        headers={
            "apikey": SUPABASE_KEY,
            "Authorization": "Bearer " + SUPABASE_KEY,
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Prefer": "resolution=merge-duplicates,return=minimal",
        },
    )

    with urllib.request.urlopen(request, timeout=30) as response:
        if not 200 <= response.status < 300:
            raise RuntimeError(f"Supabase HTTP {response.status}")

    return len(rows)

def main():
    all_rows = {}
    errors = []

    for team_name, sport_slug in TEAMS:
        try:
            team = find_team(team_name)

            if not team:
                print(f"[SKIP] Takım bulunamadı: {team_name}")
                continue

            team_id = team.get("idTeam")
            if not team_id:
                print(f"[SKIP] Takım kimliği yok: {team_name}")
                continue

            print(
                f"[TEAM] {team_name} -> "
                f"{team.get('strTeam')} (ID {team_id})"
            )

            events = fetch_events(team_id)

            for event in events:
                row = normalize_event(event, sport_slug, team_name)
                if row:
                    all_rows[row["external_id"]] = row

            # Ücretsiz servisin istek sınırlarını gözet.
            time.sleep(2)

        except Exception as error:
            message = f"{team_name}: {error}"
            errors.append(message)
            print("[ERROR]", message)

    rows = list(all_rows.values())
    print(f"[INFO] Alınan benzersiz maç kaydı: {len(rows)}")

    written = upsert_events(rows)
    print(f"[OK] Supabase'e yazılan/güncellenen maç: {written}")

    if errors and not rows:
        raise RuntimeError(
            "Hiç maç alınamadı. İlk hata: " + errors[0]
        )

if __name__ == "__main__":
    main()
