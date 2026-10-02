#!/usr/bin/env bash
# Install po0-clash on macOS from a GitHub Release dmg.
#
#   PO0CLASH_VERSION  release tag to install (default: latest release)
#   PO0CLASH_DMG      local dmg path or URL; skips the release lookup
#   PO0CLASH_REPO     owner/repo (default: DeraDream/po0-clash)
#   GH_TOKEN          token for a private repository when gh is unavailable
set -euo pipefail
# macOS ships bash 3.2, where "${a[@]}" on an empty array trips set -u;
# arrays below expand as ${a[@]+"${a[@]}"}.

repo="${PO0CLASH_REPO:-DeraDream/po0-clash}"
version="${PO0CLASH_VERSION:-latest}"
app_name="po0-clash.app"
target="/Applications/$app_name"

die() {
  echo "error: $*" >&2
  exit 1
}

[ "$(uname -s)" = "Darwin" ] || die "this installer only runs on macOS"

case "$(uname -m)" in
  arm64) arch="arm64" ;;
  x86_64) arch="amd64" ;;
  *) die "unsupported architecture $(uname -m)" ;;
esac

workdir="$(mktemp -d)"
mountpoint="$workdir/mnt"
cleanup() {
  if [ -d "$mountpoint" ]; then
    hdiutil detach "$mountpoint" -quiet >/dev/null 2>&1 || true
  fi
  rm -rf "$workdir"
}
trap cleanup EXIT

dmg="$workdir/po0-clash.dmg"

download_with_gh() {
  local tag_args=()
  [ "$version" = "latest" ] || tag_args=("$version")
  gh release download ${tag_args[@]+"${tag_args[@]}"} -R "$repo" \
    -p "po0-clash-*-macos-$arch.dmg" -D "$workdir" --clobber
  local found
  found="$(find "$workdir" -maxdepth 1 -name "po0-clash-*-macos-$arch.dmg" | head -n 1)"
  [ -n "$found" ] || return 1
  mv "$found" "$dmg"
}

download_with_api() {
  local endpoint auth=()
  if [ "$version" = "latest" ]; then
    endpoint="https://api.github.com/repos/$repo/releases/latest"
  else
    endpoint="https://api.github.com/repos/$repo/releases/tags/$version"
  fi
  [ -z "${GH_TOKEN:-}" ] || auth=(-H "Authorization: Bearer $GH_TOKEN")
  local release asset_url
  release="$(curl -fsSL ${auth[@]+"${auth[@]}"} -H "Accept: application/vnd.github+json" "$endpoint")" ||
    die "cannot read release $version of $repo (private repository? set GH_TOKEN or log in with gh)"
  # JavaScript for Automation ships with every macOS; jq and python do not.
  asset_url="$(osascript -l JavaScript -e '
    function run(argv) {
      const assets = JSON.parse(argv[0]).assets || [];
      const asset = assets.find((a) => a.name.startsWith("po0-clash-") && a.name.endsWith("-macos-" + argv[1] + ".dmg"));
      return asset ? asset.url : "";
    }' "$release" "$arch")"
  [ -n "$asset_url" ] || die "no po0-clash-*-macos-$arch.dmg asset in release $version"
  curl -fL --progress-bar ${auth[@]+"${auth[@]}"} -H "Accept: application/octet-stream" \
    -o "$dmg" "$asset_url"
}

if [ -n "${PO0CLASH_DMG:-}" ]; then
  case "$PO0CLASH_DMG" in
    http://* | https://*) curl -fL --progress-bar -o "$dmg" "$PO0CLASH_DMG" ;;
    *) cp "$PO0CLASH_DMG" "$dmg" ;;
  esac
elif command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  echo "Downloading $repo $version (macos-$arch) with gh..."
  download_with_gh || die "no po0-clash-*-macos-$arch.dmg asset in release $version"
else
  echo "Downloading $repo $version (macos-$arch)..."
  download_with_api
fi

mkdir -p "$mountpoint"
hdiutil attach "$dmg" -nobrowse -readonly -quiet -mountpoint "$mountpoint"
[ -d "$mountpoint/$app_name" ] || die "$app_name not found in the dmg"

if pgrep -x po0-clash >/dev/null 2>&1; then
  echo "Quitting the running po0-clash..."
  osascript -e 'quit app "po0-clash"' >/dev/null 2>&1 || true
  sleep 2
  pkill -x po0-clash >/dev/null 2>&1 || true
fi

sudo_cmd=()
if [ ! -w /Applications ] || { [ -e "$target" ] && [ ! -w "$target" ]; }; then
  sudo_cmd=(sudo)
fi

echo "Installing to $target..."
${sudo_cmd[@]+"${sudo_cmd[@]}"} rm -rf "$target"
${sudo_cmd[@]+"${sudo_cmd[@]}"} ditto "$mountpoint/$app_name" "$target"
# The build is not notarized; without this Gatekeeper refuses the first launch.
${sudo_cmd[@]+"${sudo_cmd[@]}"} xattr -dr com.apple.quarantine "$target" 2>/dev/null || true

echo "po0-clash installed. Opening..."
open "$target" || true
