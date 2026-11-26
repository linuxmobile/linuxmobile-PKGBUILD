# linuxmobile PKGBUILD

Arch based package repository built with GitHub Actions and published as a pacman repository through GitHub Releases.

## Installation

```bash
sudo install -Dm644 config/linuxmobile-mirrorlist /etc/pacman.d/linuxmobile-mirrorlist
sudo tee -a /etc/pacman.conf < config/linuxmobile.conf
sudo pacman -Sy
```

The resulting `/etc/pacman.conf` entry is:

```
[linuxmobile]
SigLevel = Optional DatabaseOptional
Include = /etc/pacman.d/linuxmobile-mirrorlist
```

Install the packages:

```bash
sudo pacman -S isocast
```

## Migration from AUR

The replacement packages declare `conflicts` and `replaces` for the old AUR names. To replace them explicitly:

```bash
sudo pacman -Rns f1multiviewer-bin hibiki-bin
```

```bash
sudo pacman -S multiviewer hibiki
```

After that, remove the AUR repository from `pacman.conf` and from `yay` or `paru`.

## Packages

The repository targets **x86-64-v3 CPUs**. `arch=('x86_64')` in pacman metadata does not encode an ISA level, so pacman will not prevent installation on an older x86-64 processor. Do not install this repository on a CPU that lacks x86-64-v3 support.

<!-- BEGIN GENERATED PACKAGE ISA STATUS -->
| Package | Payload / build | x86-64-v3 status |
| -------------------------- | --------------- | ---------------- |
| antigravity-cli | Upstream binary archive | Upstream binary; not guaranteed |
| ardia | Upstream binary archive | Upstream binary; not guaranteed |
| agentty | CMake/C++ | Enforced by CI (ELF ISA note) |
| blurcam | CMake/C++ | Enforced by CI (ELF ISA note) |
| chromium-widevine-helper | Python / assets | n/a (`any`) |
| cressida | Meson/C++ | Enforced by CI (ELF ISA note) |
| frame | Rust | Enforced by CI (ELF ISA note) |
| flow-control | Zig | v3 target selected; GNU ISA note not asserted |
| herdr-app | Rust, Zig | Enforced by CI (ELF ISA note) |
| herdr-tui | Rust, Zig | Enforced by CI (ELF ISA note) |
| hibiki | Rust | Enforced by CI (ELF ISA note) |
| isocast | Rust | Enforced by CI (ELF ISA note) |
| kernwatch | Rust | Enforced by CI (ELF ISA note) |
| ladybird | Upstream Debian package | Upstream binary; not guaranteed |
| lui | Zig | v3 target selected; GNU ISA note not asserted |
| mdrs | Rust | Enforced by CI (ELF ISA note) |
| microsoft-edge-beta | Upstream Debian package | Upstream binary; not guaranteed |
| monocode | Rust | Enforced by CI (ELF ISA note) |
| monstar | Zig | v3 target selected; GNU ISA note not asserted |
| multiviewer | Upstream Electron archive | Upstream binary; not guaranteed |
| netwatch | Rust | Enforced by CI (ELF ISA note) |
| obs-pipewire-audio-capture | CMake/C++ | Enforced by CI (ELF ISA note) |
| omalive | Rust | Enforced by CI (ELF ISA note) |
| omatuner | Rust | Enforced by CI (ELF ISA note) |
| oxfmt | Rust | Enforced by CI (ELF ISA note) |
| ps_mem | Python | n/a (`any`) |
| rgrc | Rust | Enforced by CI (ELF ISA note) |
| rhun | Assembly | Review required; ISA audit/tuning pending |
| rlottie | CMake/C++ | Enforced by CI (ELF ISA note) |
| sonora | Rust | Enforced by CI (ELF ISA note) |
| strata | Rust | Enforced by CI (ELF ISA note) |
| syswatch | Rust | Enforced by CI (ELF ISA note) |
| zmon | Zig | v3 target selected; GNU ISA note not asserted |
<!-- END GENERATED PACKAGE ISA STATUS -->

<!-- BEGIN GENERATED PACKAGE ISA NOTE -->
The ISA status table is generated from `config/isa-policy.tsv` during repository publication. `required` packages are checked for the GNU `x86 ISA needed` property.
<!-- END GENERATED PACKAGE ISA NOTE -->

C/C++ builds receive `-march=x86-64-v3` and the linker requirement `-Wl,-z,x86-64-v3`. Rust builds receive `-C target-cpu=x86-64-v3` and the equivalent linker argument. `flow-control`, `lui`, and `zmon` pin Zig's CPU target directly in their PKGBUILDs. Which packages CI checks, and which are exempt, is recorded in `config/isa-policy.tsv`.

## Local build

```bash
./scripts/build.sh <package>
```

The script uses `config/makepkg.conf` and targets x86-64-v3. After building, run `./scripts/validate-package-isa.sh <package>` to check the package against `config/isa-policy.tsv`.

## Updating packages

`scripts/update` checks upstream versions and refreshes the PKGBUILDs, checksums, and tracked `.SRCINFO` files:

```bash
./scripts/update all
./scripts/update cressida,isocast
./scripts/update --dry-run all
```

The script requires `git`, `python`, `makepkg`, and `updpkgsums` (from `pacman-contrib`). Upstream locations and per-package rules live in `config/update-sources.tsv`. Git packages are cloned and their `pkgver()` function is evaluated, while release packages use tags or the vendor's download manifest. Auxiliary versions such as MultiViewer's build id, Monocode's native version, and Lui's pinned commit are updated alongside `pkgver`.

## Publishing

Every push to `main` builds only the packages changed under `packages/` by that push.

To trigger a build manually for specific packages:

```bash
gh workflow run build.yml -f package=cressida
gh workflow run build.yml -f package=cressida,oxfmt
```

To trigger a full rebuild of every package:

```bash
gh workflow run build.yml -f package=all
```

The weekly schedule also rebuilds every package. Both modes run in `archlinux:latest`, generate the database with `repo-add`, and update the assets of the `repo` release.
