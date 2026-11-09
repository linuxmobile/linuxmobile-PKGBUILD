#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pkg="${1:?usage: build.sh <package>}"

export PATH="$root/scripts:$PATH"

packages_root="$root/packages"
makepkg_conf="$root/config/makepkg.conf"

# Use sccache for Cargo when available. Rust incremental outputs are not cacheable
# by sccache, so disable them for predictable cache hits.
if command -v sccache >/dev/null 2>&1; then
  export RUSTC_WRAPPER="${RUSTC_WRAPPER:-sccache}"
  export CARGO_INCREMENTAL="${CARGO_INCREMENTAL:-0}"
fi

srcinfo() {
  (cd "$1" && makepkg --config "$makepkg_conf" --printsrcinfo 2>/dev/null)
}

# Map package names and provides to their local package directory. Loaded
# lazily so packages whose dependencies are all available pay no extra cost.
declare -A LOCAL_PROVIDERS=()
local_providers_loaded=false

load_local_providers() {
  [[ "$local_providers_loaded" == true ]] && return 0
  local dir info name
  for dir in "$packages_root"/*/; do
    [[ -f "$dir/PKGBUILD" ]] || continue
    info="$(srcinfo "$dir")" || continue
    while IFS= read -r name; do
      [[ -n "$name" ]] || continue
      [[ -n "${LOCAL_PROVIDERS[$name]:-}" ]] || LOCAL_PROVIDERS["$name"]="$(basename "$dir")"
    done < <(printf '%s\n' "$info" |
      sed -n -e 's/^pkgname = //p' -e 's/^\tprovides = //p' |
      awk '{ sub(/[<>=].*/, "", $1); print $1 }')
  done
  local_providers_loaded=true
}

# Return the directory of the local package that provides a dependency, if any.
find_local_provider() {
  load_local_providers
  local depdir="${LOCAL_PROVIDERS[$1]:-}"
  [[ -n "$depdir" ]] || return 1
  printf '%s\n' "$depdir"
}

# Build and install dependencies that are provided by packages in this repo but
# have not been published/installed yet. This keeps a full rebuild working even
# when a package depends on another package built in the same run (for example
# cressida -> rlottie).
install_local_dependencies() {
  local dir="$1" dep name depdir info
  info="$(srcinfo "$dir")" || return 0

  while IFS= read -r dep; do
    [[ -n "$dep" ]] || continue
    # Ignore version constraints and soname/provides requirements.
    name="${dep%%[<>=]*}"
    [[ "$name" == *".so"* ]] && continue
    pacman -T "$dep" >/dev/null 2>&1 && continue

    depdir="$(find_local_provider "$name")" || continue
    if [[ ":${PACKAGE_BUILD_STACK:-}:" == *":$depdir:"* ]]; then
      echo "==> Skipping circular local dependency: $depdir"
      continue
    fi

    echo "==> $pkg depends on local package '$name'; building $depdir first"
    PACKAGE_BUILD_STACK="${PACKAGE_BUILD_STACK:+$PACKAGE_BUILD_STACK:}$pkg" \
      bash "$root/scripts/build.sh" "$depdir"

    shopt -s nullglob
    local built=("$packages_root/$depdir"/*.pkg.tar.zst)
    shopt -u nullglob
    if [[ ${#built[@]} -eq 0 ]]; then
      echo "ERROR: $depdir did not produce a package" >&2
      return 1
    fi
    local pkgfile
    pkgfile="$(ls -t "${built[@]}" | head -n1)"
    if [[ "$(id -u)" -eq 0 ]]; then
      pacman -U --noconfirm "$pkgfile"
    else
      sudo pacman -U --noconfirm "$pkgfile"
    fi
  done < <(printf '%s\n' "$info" | sed -n -e 's/^\tdepends = //p' -e 's/^\tmakedepends = //p' -e 's/^\tcheckdepends = //p')
}

cd "$root/packages/$pkg"
install_local_dependencies "$root/packages/$pkg"

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
