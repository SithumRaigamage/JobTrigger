#!/usr/bin/env bash
# Exports the JobTrigger logo (Phase 16, Concept B) from UI-UX/brand/*.svg to
# every PNG the app, the website and the store listings use. The PNGs are
# committed; rerun this after changing a source drawing.
#
#   scripts/export-icons.sh [ios|android|splash|web|store|all]   (default: all)
#
# Needs rsvg-convert (`brew install librsvg`) and python3 (stdlib only). A
# tool on the developer's machine, not a project dependency (CLAUDE.md §3).
# EXPORT_ROOT=<dir> writes the same relative paths under <dir> instead of
# the repo, to look at the result before replacing anything.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$REPO/UI-UX/brand"
OUT="${EXPORT_ROOT:-$REPO}"

command -v rsvg-convert >/dev/null || {
  echo "rsvg-convert not found: brew install librsvg" >&2
  exit 1
}

# render <svg> <px> <path relative to OUT>
render() {
  mkdir -p "$(dirname "$OUT/$3")"
  rsvg-convert -w "$2" -h "$2" "$SRC/$1" -o "$OUT/$3"
}

ios() {
  local set="JobTrigger-Frontend/ios/Runner/Assets.xcassets/AppIcon.appiconset"
  # Contents.json is the list of slots: size (points) × scale = pixels.
  python3 - "$REPO/$set/Contents.json" <<'EOF' |
import json, sys
for image in json.load(open(sys.argv[1]))["images"]:
    if "filename" in image:
        points = float(image["size"].split("x")[0])
        scale = int(image["scale"].rstrip("x"))
        print(image["filename"], round(points * scale))
EOF
  while read -r file px; do
    render icon.svg "$px" "$set/$file"
    # The App Store rejects icons with an alpha channel, even fully opaque.
    if file "$OUT/$set/$file" | grep -q RGBA; then
      echo "$set/$file has an alpha channel; the App Store rejects it" >&2
      exit 1
    fi
  done
}

android() {
  # Launchers below API 26 (and the Play Store's fallback) use these; API 26+
  # uses the adaptive icon in mipmap-anydpi-v26 instead.
  local res="JobTrigger-Frontend/android/app/src/main/res"
  render mark.svg 48 "$res/mipmap-mdpi/ic_launcher.png"
  render mark.svg 72 "$res/mipmap-hdpi/ic_launcher.png"
  render mark.svg 96 "$res/mipmap-xhdpi/ic_launcher.png"
  render mark.svg 144 "$res/mipmap-xxhdpi/ic_launcher.png"
  render mark.svg 192 "$res/mipmap-xxxhdpi/ic_launcher.png"
}

splash() {
  # iOS LaunchScreen.storyboard centres this on navy. 152 pt wide, the same
  # glyph width as the Android splash (ic_launcher_foreground at 288dp).
  local set="JobTrigger-Frontend/ios/Runner/Assets.xcassets/LaunchImage.imageset"
  mkdir -p "$OUT/$set"
  rsvg-convert -w 152 "$SRC/splash.svg" -o "$OUT/$set/LaunchImage.png"
  rsvg-convert -w 304 "$SRC/splash.svg" -o "$OUT/$set/LaunchImage@2x.png"
  rsvg-convert -w 456 "$SRC/splash.svg" -o "$OUT/$set/LaunchImage@3x.png"
}

web() {
  # Next.js serves these as the favicon and the iOS home-screen icon.
  render mark.svg 256 "JobTrigger-Web/src/app/icon.png"
  render icon.svg 180 "JobTrigger-Web/src/app/apple-icon.png"
}

store() {
  # Uploaded by hand to Google Play; the App Store takes the 1024 px iOS icon.
  render icon.svg 512 "UI-UX/brand/store/play-store-512.png"
}

case "${1:-all}" in
  ios) ios ;;
  android) android ;;
  splash) splash ;;
  web) web ;;
  store) store ;;
  all) ios && android && splash && web && store ;;
  *)
    echo "usage: $0 [ios|android|splash|web|store|all]" >&2
    exit 2
    ;;
esac
echo "exported ${1:-all} to $OUT"
