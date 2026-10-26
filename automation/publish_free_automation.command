#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
printf '\nFENERVERSE · ÜCRETSİZ OTOMASYON KURULUMU\n'
printf 'Bu işlem kodu herkese açık bir GitHub deposuna gönderebilir. Anahtarlar kaynak koda yazılmaz.\n\n'
if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI bulunamadı. Homebrew kuruluysa şu komutu çalıştır: brew install gh"
  exit 1
fi
if ! gh auth status >/dev/null 2>&1; then
  echo "Önce GitHub girişini tamamlayalım: gh auth login"
  gh auth login
fi
read -r -p "GitHub depo adı [fenerverse-free-automation]: " REPO_NAME
REPO_NAME=${REPO_NAME:-fenerverse-free-automation}
read -r -p "Supabase Project URL (https://....supabase.co): " SUPABASE_URL_VALUE
if [[ ! "$SUPABASE_URL_VALUE" =~ ^https://[^/]+\.supabase\.co/?$ ]]; then
  echo "URL biçimi doğrulanamadı. Supabase Dashboard'daki Project URL'yi gir."
  exit 1
fi
read -r -s -p "Supabase service_role key (girdi gizli): " SUPABASE_SERVICE_KEY_VALUE
printf '\n'
if [[ -z "$SUPABASE_SERVICE_KEY_VALUE" ]]; then echo "Service role key boş olamaz."; exit 1; fi
if [[ ! -d .git ]]; then git init -b main; fi
git branch -M main
git add .
if ! git diff --cached --quiet; then git commit -m "Add FenerVerse free automation"; fi
if git remote get-url origin >/dev/null 2>&1; then
  echo "Origin remote mevcut: $(git remote get-url origin)"
  gh repo set-default "$(git remote get-url origin | sed -E 's#.*github.com[:/]([^/]+/[^/.]+)(\.git)?#\1#')" || true
  git push -u origin main || true
else
  gh repo create "$REPO_NAME" --public --source . --remote origin --push
fi
REPO_FULL=$(gh repo view --json nameWithOwner -q .nameWithOwner)
printf '%s' "$SUPABASE_URL_VALUE" | gh secret set SUPABASE_URL --repo "$REPO_FULL"
printf '%s' "$SUPABASE_SERVICE_KEY_VALUE" | gh secret set SUPABASE_SERVICE_ROLE_KEY --repo "$REPO_FULL"
unset SUPABASE_SERVICE_KEY_VALUE
unset SUPABASE_URL_VALUE
echo
printf 'Tamamlandı. GitHub deposu: https://github.com/%s\n' "$REPO_FULL"
printf 'Actions sekmesinde FenerVerse Free RSS Sync iş akışını aç; Run workflow ile test edebilirsin.\n'
printf 'Not: Supabase SQL kurulumu henüz yapılmadıysa Backend/SETUP.sql dosyasını SQL Editor içinde çalıştır.\n'
