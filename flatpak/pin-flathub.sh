#!/usr/bin/env bash
# Pin the Flathub manifest to a published release: fills in the tarball URL and
# its sha256 in io.github.crazymevt.StudyBible.flathub.yml.
#
# Usage:
#   flatpak/pin-flathub.sh <tag>            # download the release asset and pin
#   flatpak/pin-flathub.sh <tag> <file>     # pin using a local StudyBible-Linux.tar.gz
#
# Requires: gh (when downloading) and sha256sum or shasum.
set -euo pipefail

REPO="crazymevt/StudyBible"
ASSET="StudyBible-Linux.tar.gz"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="$SCRIPT_DIR/io.github.crazymevt.StudyBible.flathub.yml"

TAG="${1:-}"
LOCAL_FILE="${2:-}"
if [[ -z "$TAG" ]]; then
  echo "usage: $0 <tag> [local-tarball]" >&2
  exit 2
fi

tmp=""
if [[ -n "$LOCAL_FILE" ]]; then
  FILE="$LOCAL_FILE"
else
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  echo "==> Downloading $ASSET from $REPO@$TAG"
  gh release download "$TAG" --repo "$REPO" --pattern "$ASSET" --dir "$tmp"
  FILE="$tmp/$ASSET"
fi

if command -v sha256sum >/dev/null 2>&1; then
  SHA="$(sha256sum "$FILE" | awk '{print $1}')"
else
  SHA="$(shasum -a 256 "$FILE" | awk '{print $1}')"
fi
URL="https://github.com/$REPO/releases/download/$TAG/$ASSET"

echo "==> tag:    $TAG"
echo "==> sha256: $SHA"

# Patch the single archive source's url + sha256 in place (portable, no GNU sed).
perl -0pi -e "s{url: https://github.com/\Q$REPO\E/releases/download/[^/]+/\Q$ASSET\E}{url: $URL}" "$MANIFEST"
perl -0pi -e "s{sha256: [0-9a-f]{64}}{sha256: $SHA}" "$MANIFEST"

echo "==> Pinned $MANIFEST"
grep -nE "url:|sha256:" "$MANIFEST"
