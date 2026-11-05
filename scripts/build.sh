#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pkg="${1:?usage: build.sh <package>}"

export PATH="$root/scripts:$PATH"

cd "$root/packages/$pkg"
exec makepkg \
  --config "$root/config/makepkg.conf" \
  --syncdeps \
  --noconfirm \
  --cleanbuild \
  --clean
