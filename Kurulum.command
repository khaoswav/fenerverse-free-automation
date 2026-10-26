#!/bin/bash
set -e
cd "$(dirname "$0")"
printf '\n  FENERVERSE · PROJE AÇICI\n'
printf '  =======================\n\n'
if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "HATA: Xcode komut satırı araçları bulunamadı. Xcode uygulamasının tam kurulu olduğundan emin ol."
  echo "App Store'dan Xcode'u aç, Settings > Locations > Command Line Tools bölümünü kontrol et."
  read -r -p "Çıkmak için Enter... " _
  exit 1
fi
if [ -d "FenerVerse.xcworkspace" ]; then
  open -a Xcode "FenerVerse.xcworkspace"
else
  open -a Xcode "FenerVerse.xcodeproj"
fi
