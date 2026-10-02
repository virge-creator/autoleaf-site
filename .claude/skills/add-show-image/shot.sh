#!/usr/bin/env bash
# Screenshot helper for the /shows/ album.
#
#   shot.sh capture <url> <out.png> <portrait|landscape|landscape-1610>
#   shot.sh sheet <out.png>        # contact sheet of src/assets/shows (duplicate check)
#
# Uses Playwright's chrome-headless-shell. Missing system libraries and an emoji
# font are fetched once (apt-get download, no root) into $CACHE.
set -euo pipefail

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/autoleaf-shot"
REPO="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
SHOWS="$REPO/src/assets/shows"

find_browser() {
  local b
  b=$(find "$HOME/.cache/ms-playwright" -type f -name chrome-headless-shell 2>/dev/null | sort | tail -1)
  if [ -z "$b" ]; then
    echo "chrome-headless-shell not found; installing via Playwright..." >&2
    npx -y playwright install chromium-headless-shell >&2
    b=$(find "$HOME/.cache/ms-playwright" -type f -name chrome-headless-shell | sort | tail -1)
  fi
  echo "$b"
}

bootstrap() {
  BROWSER=$(find_browser)
  local arch libdir
  arch=$(dpkg-architecture -qDEB_HOST_MULTIARCH 2>/dev/null || echo "$(uname -m)-linux-gnu")
  libdir="$CACHE/root/usr/lib/$arch"
  mkdir -p "$CACHE/debs" "$CACHE/root" "$CACHE/fontcache"

  # Fetch packages for any shared library the browser can't resolve.
  local missing
  missing=$(LD_LIBRARY_PATH="$libdir" ldd "$BROWSER" | awk '/not found/{print $1}')
  for lib in $missing; do
    local pkg
    pkg=$(apt-file search -l "$lib" 2>/dev/null | head -1 || true)
    if [ -z "$pkg" ]; then
      case "$lib" in
        libatk-1.0.so.0) pkg="libatk1.0-0t64 libatk1.0-0" ;;
        libatspi.so.0) pkg="libatspi2.0-0t64 libatspi2.0-0" ;;
        libXdamage.so.1) pkg="libxdamage1" ;;
        libasound.so.2) pkg="libasound2t64 libasound2" ;;
        *) pkg="" ;;
      esac
    fi
    for p in $pkg; do
      (cd "$CACHE/debs" && apt-get download "$p" >/dev/null 2>&1) && break || true
    done
  done
  # libasound2t64 is sometimes missing from the mirror in its -updates version.
  if LD_LIBRARY_PATH="$libdir" ldd "$BROWSER" | grep -q 'libasound.so.2 => not found'; then
    local v
    v=$(apt-cache show libasound2t64 2>/dev/null | awk '/^Filename:/{print $2}' | tail -1)
    [ -n "$v" ] && (cd "$CACHE/debs" && curl -sfLO "http://ports.ubuntu.com/ubuntu-ports/$v" || curl -sfLO "http://archive.ubuntu.com/ubuntu/$v") || true
  fi
  if ! ls "$CACHE"/debs/fonts-noto-color-emoji_*.deb >/dev/null 2>&1; then
    (cd "$CACHE/debs" && apt-get download fonts-noto-color-emoji >/dev/null 2>&1) || true
  fi
  for d in "$CACHE"/debs/*.deb; do [ -e "$d" ] && dpkg-deb -x "$d" "$CACHE/root"; done

  if LD_LIBRARY_PATH="$libdir" ldd "$BROWSER" | grep -q 'not found'; then
    echo "Still missing libraries:" >&2
    LD_LIBRARY_PATH="$libdir" ldd "$BROWSER" | grep 'not found' >&2
    exit 1
  fi

  local emoji
  emoji=$(dirname "$(find "$CACHE/root" -name NotoColorEmoji.ttf | head -1)" 2>/dev/null || true)
  cat > "$CACHE/fonts.conf" <<EOF
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <include ignore_missing="yes">/etc/fonts/fonts.conf</include>
  ${emoji:+<dir>$emoji</dir>}
  <cachedir>$CACHE/fontcache</cachedir>
</fontconfig>
EOF
  export LD_LIBRARY_PATH="$libdir" FONTCONFIG_FILE="$CACHE/fonts.conf"
}

render() { # url out width height scale
  timeout 120 "$BROWSER" --headless --no-sandbox --hide-scrollbars \
    --window-size="$3,$4" --force-device-scale-factor="$5" \
    --virtual-time-budget=20000 --screenshot="$2" "$1" 2>&1 | grep -o '[0-9]* bytes written.*' || true
  [ -s "$2" ] || { echo "screenshot failed: $1" >&2; exit 1; }
}

cmd="${1:-}"; shift || true
case "$cmd" in
  capture)
    url="$1"; out="$2"; mode="${3:-landscape}"
    bootstrap
    case "$mode" in
      portrait)       render "$url" "$out" 1080 1920 2 ;;  # 2160x3840
      landscape)      render "$url" "$out" 1920 1080 2 ;;  # 3840x2160
      landscape-1610) render "$url" "$out" 1920 1200 2 ;;  # 3840x2400
      *) echo "unknown mode: $mode" >&2; exit 2 ;;
    esac
    ;;
  sheet)
    out="$1"
    bootstrap
    html="$CACHE/sheet.html"
    {
      echo '<html><body style="margin:0;background:#111;color:#eee;font:14px sans-serif;display:flex;flex-wrap:wrap;gap:8px;padding:8px">'
      for f in "$SHOWS"/*.{png,jpg,jpeg,webp,PNG,JPG,JPEG,WEBP}; do
        [ -e "$f" ] || continue
        echo "<figure style=\"margin:0;width:300px\"><img src=\"file://$f\" style=\"width:300px;height:220px;object-fit:contain;background:#000\"><figcaption>$(basename "$f")</figcaption></figure>"
      done
      echo '</body></html>'
    } > "$html"
    n=$(grep -c '<figure' "$html" || true)
    render "file://$html" "$out" 1580 $(( (n + 4) / 5 * 262 + 16 )) 1
    ;;
  *)
    sed -n '2,8p' "$0"; exit 2 ;;
esac
