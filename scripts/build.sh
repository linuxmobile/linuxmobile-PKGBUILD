#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pkg="${1:?usage: build.sh <package>}"

export PATH="$root/scripts:$PATH"

# Use sccache for Cargo when available. Rust incremental outputs are not cacheable
# by sccache, so disable them for predictable cache hits.
if command -v sccache >/dev/null 2>&1; then
  export RUSTC_WRAPPER="${RUSTC_WRAPPER:-sccache}"
  export CARGO_INCREMENTAL="${CARGO_INCREMENTAL:-0}"
fi

cd "$root/packages/$pkg"

build_status=0
makepkg \
  --config "$root/config/makepkg.conf" \
  --syncdeps \
  --noconfirm \
  --cleanbuild \
  --clean || build_status=$?

# Report cache effectiveness even when a build fails.
if command -v sccache >/dev/null 2>&1 && [[ "${RUSTC_WRAPPER:-}" == "sccache" ]]; then
  sccache --show-stats || true
fi
if command -v ccache >/dev/null 2>&1; then
  ccache --show-stats || true
fi

exit "$build_status"
