#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pkg="${1:?usage: validate-package-isa.sh <package> [package-file]}"
pkgdir="$root/packages/$pkg"
pkgfile="${2:-}"
policy_file="$root/config/isa-policy.tsv"

if [[ -z "$pkgfile" ]]; then
  shopt -s nullglob
  package_files=("$pkgdir"/*.pkg.tar.zst)
  shopt -u nullglob
  if ((${#package_files[@]} != 1)); then
    printf 'error: expected exactly one package archive in %s, found %s\n' \
      "$pkgdir" "${#package_files[@]}" >&2
    exit 1
  fi
  pkgfile="${package_files[0]}"
fi

[[ -f "$pkgfile" ]] || { printf 'error: package archive not found: %s\n' "$pkgfile" >&2; exit 1; }
[[ -f "$policy_file" ]] || { printf 'error: missing ISA policy: %s\n' "$policy_file" >&2; exit 1; }

policy_line="$(awk -F'|' -v package="$pkg" '$1 == package { print; found=1; exit } END { if (!found) exit 1 }' "$policy_file")" || {
  printf 'error: package %s has no entry in %s\n' "$pkg" "$policy_file" >&2
  exit 1
}
IFS='|' read -r _ policy exception_path reason <<< "$policy_line"

case "$policy" in
  upstream|any|review)
    printf 'ISA check: %s (%s) — %s\n' "$pkg" "$policy" "$reason"
    exit 0
    ;;
  target)
    if ! grep -Fq -- '-Dcpu=x86_64_v3' "$pkgdir/PKGBUILD"; then
      printf 'error: %s is marked target, but its PKGBUILD does not pin Zig to x86_64_v3\n' "$pkg" >&2
      exit 1
    fi
    ;;
  r2r)
    workflow="$root/.github/workflows/build.yml"
    r2r_isa='--instruction-set:avx2,bmi,bmi2,f16c,fma,lzcnt,movbe'
    if ! grep -Fq -- 'PublishReadyToRunUseCrossgen2=true' "$workflow"; then
      printf 'error: %s is marked r2r, but the workflow does not enable Crossgen2 for Kavita\n' "$pkg" >&2
      exit 1
    fi
    if ! grep -Fq -- "PublishReadyToRunCrossgen2ExtraArgs=$r2r_isa" "$workflow"; then
      printf 'error: %s is marked r2r, but the workflow is missing its x86-64-v3 instruction-set baseline\n' "$pkg" >&2
      exit 1
    fi
    printf 'ISA check: %s (r2r) — application ReadyToRun is configured for v3; bundled native runtime files are not certified.\n' "$pkg"
    exit 0
    ;;
  required|partial)
    ;;
  *)
    printf 'error: unknown ISA policy "%s" for %s\n' "$policy" "$pkg" >&2
    exit 1
    ;;
esac

command -v bsdtar >/dev/null || { echo 'error: bsdtar is required (install libarchive)' >&2; exit 1; }
command -v readelf >/dev/null || { echo 'error: readelf is required (install binutils)' >&2; exit 1; }

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
bsdtar -xf "$pkgfile" -C "$tmpdir"

elf_count=0
checked_count=0
exception_seen=0
failed=0

while IFS= read -r -d '' file; do
  header="$(readelf -h "$file" 2>/dev/null)" || continue
  machine="$(awk -F: '/^[[:space:]]*Machine:/ { sub(/^[[:space:]]+/, "", $2); print $2; exit }' <<< "$header")"
  [[ "$machine" == 'Advanced Micro Devices X86-64' ]] || continue

  ((elf_count += 1))
  relpath="${file#"$tmpdir"/}"

  if [[ "$policy" == target ]]; then
    ((checked_count += 1))
    printf '  TARGET    %s (x86-64 ELF; PKGBUILD pins Zig to x86_64_v3)\n' "$relpath"
    continue
  fi

  if [[ "$policy" == partial && "$relpath" == "$exception_path" ]]; then
    exception_seen=1
    printf '  EXCEPTION %s (upstream ELF, not required to be v3)\n' "$relpath"
    continue
  fi

  notes="$(readelf -n --wide "$file" 2>/dev/null || true)"
  needed="$(sed -nE 's/.*x86 ISA needed:[[:space:]]*(.*)$/\1/p' <<< "$notes" | head -n1)"

  if [[ "$needed" =~ (^|[,[:space:]])x86-64-v3($|[,[:space:]]) ]]; then
    ((checked_count += 1))
    printf '  OK        %s [%s]\n' "$relpath" "$needed"
  else
    printf '  FAIL      %s [ISA needed: %s]\n' "$relpath" "${needed:-missing GNU x86 ISA property}" >&2
    failed=1
  fi
done < <(find "$tmpdir" -type f -print0)

if ((elf_count == 0)); then
  printf 'error: no x86-64 ELF files found in %s\n' "$pkgfile" >&2
  exit 1
fi

if [[ "$policy" == partial && "$exception_seen" -ne 1 ]]; then
  printf 'error: expected exception ELF was not found: %s\n' "$exception_path" >&2
  failed=1
fi

if ((failed != 0)); then
  printf 'ISA validation failed for %s (%s): %s of %s ELF file(s) passed.\n' \
    "$pkg" "$policy" "$checked_count" "$elf_count" >&2
  exit 1
fi

if [[ "$policy" == target ]]; then
  printf 'ISA validation passed for %s: Zig target is explicitly pinned; GNU ISA note was not asserted.\n' "$pkg"
else
  printf 'ISA validation passed for %s: %s of %s ELF file(s) declare x86-64-v3.\n' \
    "$pkg" "$checked_count" "$elf_count"
fi
