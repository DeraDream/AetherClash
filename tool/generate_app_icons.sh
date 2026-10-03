#!/usr/bin/env bash
# Renders every launcher, window and store icon from assets_source/images/icon.
# Needs rsvg-convert (librsvg), cwebp and python3.
# This script intentionally avoids "dart run" so release icon generation never
# triggers native build hooks or requires the Clash.Meta submodule.
set -euo pipefail
cd "$(dirname "$0")/.."

src=assets_source/images/icon
res=android/app/src/main/res
mac=macos/Runner/Assets.xcassets/AppIcon.appiconset
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

cp "$src/app_icon.svg" "$tmp/app_icon.svg"
wrap() {
  local name=$1 clip=$2
  cat > "$tmp/$name.svg" <<SVG
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="1024" height="1024" viewBox="0 0 1024 1024">
  <defs><clipPath id="c">$clip</clipPath></defs>
  <g clip-path="url(#c)"><image xlink:href="app_icon.svg" width="1024" height="1024"/></g>
</svg>
SVG
}
wrap rounded '<rect width="1024" height="1024" rx="230" ry="230"/>'
wrap round '<circle cx="512" cy="512" r="512"/>'

render() { rsvg-convert -w "$2" -h "$3" -o "$4" "$1"; }
webp() {
  render "$1" "$2" "$2" "$tmp/out.png"
  cwebp -quiet -lossless "$tmp/out.png" -o "$3"
}

render "$tmp/rounded.svg" 512 512 assets/images/icon.png
render "$src/app_icon.svg" 512 512 android/app/src/main/ic_launcher-playstore.png

for size in 16 32 64 128 256 512 1024; do
  render "$src/app_icon_macos.svg" "$size" "$size" "$mac/app_icon_$size.png"
done

declare -A scale=([mdpi]=1 [hdpi]=1.5 [xhdpi]=2 [xxhdpi]=3 [xxxhdpi]=4)
for density in "${!scale[@]}"; do
  s=${scale[$density]}
  layer=$(python3 -c "print(int(108 * $s))")
  legacy=$(python3 -c "print(int(48 * $s))")
  tv=$(python3 -c "print(int(80 * $s))")
  mkdir -p "$res/mipmap-$density" "$res/mipmap-television-$density"
  render "$src/launcher_foreground.svg" "$layer" "$layer" "$res/mipmap-$density/ic_launcher_foreground.png"
  render "$src/launcher_background.svg" "$layer" "$layer" "$res/mipmap-$density/ic_launcher_background.png"
  webp "$tmp/rounded.svg" "$legacy" "$res/mipmap-$density/ic_launcher.webp"
  webp "$tmp/round.svg" "$legacy" "$res/mipmap-$density/ic_launcher_round.webp"
  webp "$tmp/rounded.svg" "$tv" "$res/mipmap-television-$density/ic_launcher.webp"
done
render "$src/banner.svg" 320 180 "$res/mipmap-xhdpi/ic_banner.png"

write_ico() {
  local output=$1
  shift
  python3 - "$output" "$@" <<'PY'
import struct
import sys

output, *paths = sys.argv[1:]
entries = []
for p in paths:
    data = open(p, "rb").read()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise SystemExit(f"not a PNG: {p}")
    width, height = struct.unpack(">II", data[16:24])
    if width != height or not 1 <= width <= 256:
        raise SystemExit(f"invalid ICO source size {width}x{height}: {p}")
    entries.append((width, data))

entries.sort(key=lambda item: item[0])
header = struct.pack("<HHH", 0, 1, len(entries))
offset = 6 + 16 * len(entries)
directory = bytearray()
payload = bytearray()
for size, data in entries:
    dimension = 0 if size == 256 else size
    directory += struct.pack(
        "<BBBBHHII",
        dimension,
        dimension,
        0,
        0,
        1,
        32,
        len(data),
        offset,
    )
    payload += data
    offset += len(data)

with open(output, "wb") as f:
    f.write(header)
    f.write(directory)
    f.write(payload)
PY
}

# Tray/status icons. Keep the same scale/layout as the previous Dart generator.
for name in status_1 status_2 status_3; do
  tray_pngs=()
  for scale_factor in 1 2 3 4; do
    size=$((18 * scale_factor))
    if [ "$scale_factor" -eq 1 ]; then
      directory="assets/images/tray/unix"
    else
      directory="assets/images/tray/unix/${scale_factor}.0x"
    fi
    mkdir -p "$directory"
    render "$src/$name.svg" "$size" "$size" "$directory/$name.png"
  done

  for size in 16 20 24 32 40 48 64; do
    png="$tmp/${name}_${size}.png"
    render "$src/$name.svg" "$size" "$size" "$png"
    tray_pngs+=("$png")
  done
  mkdir -p assets/images/tray/windows
  write_ico "assets/images/tray/windows/$name.ico" "${tray_pngs[@]}"
done

# Windows application icon with all shell-requested sizes.
app_pngs=()
for size in 16 20 24 32 40 48 64 96 128 256; do
  png="$tmp/app_${size}.png"
  render "$tmp/rounded.svg" "$size" "$size" "$png"
  app_pngs+=("$png")
done
mkdir -p windows/runner/resources
write_ico windows/runner/resources/app_icon.ico "${app_pngs[@]}"
cp windows/runner/resources/app_icon.ico assets/images/icon.ico
