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

The new packages declare `provides`, `conflicts`, and `replaces` for the old AUR names. To replace them explicitly:

```bash
sudo pacman -Rns f1multiviewer-bin hibiki-bin
```

```bash
sudo pacman -S multiviewer
```

After that, remove the AUR repository from `pacman.conf` and from `yay` or `paru`.

## Packages

The repository targets **x86-64-v3 CPUs**. `arch=('x86_64')` in pacman metadata does not encode an ISA level, so pacman will not prevent installation on an older x86-64 processor. Do not install this repository on a CPU that lacks x86-64-v3 support.

<!-- BEGIN GENERATED PACKAGE ISA STATUS -->
| Package | Payload / build | x86-64-v3 status |
| -------------------------- | --------------- | ---------------- |
| anix | Upstream Debian package | Upstream binary; not guaranteed |
| antigravity-cli | Upstream binary archive | Upstream binary; not guaranteed |
| blurcam | CMake/C++ | Enforced by CI (ELF ISA note) |
| chromium-widevine-helper | Python / assets | n/a (`any`) |
| cressida | Meson/C++ | Enforced by CI (ELF ISA note) |
| frame | Rust | Enforced by CI (ELF ISA note) |
| hibiki | Rust | Enforced by CI (ELF ISA note) |
| isocast | Rust | Enforced by CI (ELF ISA note) |
| kavita | .NET ReadyToRun | Review required; ISA audit/tuning pending |
| kernwatch | Rust | Enforced by CI (ELF ISA note) |
| lui | Zig | v3 target selected; GNU ISA note not asserted |
| mdrs | Rust | Enforced by CI (ELF ISA note) |
| microsoft-edge-beta | Upstream Debian package | Upstream binary; not guaranteed |
| multiviewer | Upstream Electron archive | Upstream binary; not guaranteed |
| netwatch | Rust | Enforced by CI (ELF ISA note) |
| obs-pipewire-audio-capture | CMake/C++ | Enforced by CI (ELF ISA note) |
| omalive | Rust | Enforced by CI (ELF ISA note) |
| omatuner | Rust | Enforced by CI (ELF ISA note) |
| oxfmt | Rust | Enforced by CI (ELF ISA note) |
| ps_mem | Python | n/a (`any`) |
| quill | Rust | Enforced by CI (ELF ISA note) |
| rawmakase | Rust + ONNX Runtime | Partial; bundled upstream ELF excluded |
| rgrc | Rust | Enforced by CI (ELF ISA note) |
| rhun | Assembly | Review required; ISA audit/tuning pending |
| rlottie | CMake/C++ | Enforced by CI (ELF ISA note) |
| rusty-inbox | Rust | Review required; ISA audit/tuning pending |
| sonora | Rust | Enforced by CI (ELF ISA note) |
| strata | Rust | Enforced by CI (ELF ISA note) |
| syswatch | Rust | Enforced by CI (ELF ISA note) |
| zapfast | Rust | Enforced by CI (ELF ISA note) |
<!-- END GENERATED PACKAGE ISA STATUS -->

<!-- BEGIN GENERATED PACKAGE ISA NOTE -->
The ISA status table is generated from `config/isa-policy.tsv` during repository publication. `required` packages are checked for the GNU `x86 ISA needed` property. Kavita's .NET 10 application ReadyToRun is configured with the x86-64-v3 instruction-set baseline; bundled native runtime files are not certified as v3. Rhun remains under review until its hand-written assembly is audited and tuned.
<!-- END GENERATED PACKAGE ISA NOTE -->


C/C++ builds receive `-march=x86-64-v3` and the linker requirement `-Wl,-z,x86-64-v3`. Rust builds receive `-C target-cpu=x86-64-v3` and the equivalent linker argument. `lui` pins Zig's CPU target directly in its PKGBUILD. Rawmakase bundles an upstream ONNX Runtime library, while Kavita and Rhun need separate work before they can be described as fully v3-targeted.

CI checks the GNU `x86 ISA needed` property on every x86-64 ELF in packages marked `required`, with a documented exception for Rawmakase's bundled ONNX Runtime. Upstream binaries and architecture-independent packages are explicitly exempt from this check; the policy lives in `config/isa-policy.tsv`.

## Local build

```bash
./scripts/build.sh <package>
```

The script uses `config/makepkg.conf` and targets x86-64-v3. After building, run `./scripts/validate-package-isa.sh <package>` to check the package against `config/isa-policy.tsv`.

## Publishing

Every push to `main` builds only the packages changed under `packages/` by that push.

To trigger a build manually for specific packages:

```bash
gh workflow run build.yml -f package=cressida
gh workflow run build.yml -f package=cressida,zapfast
```

To trigger a full rebuild of every package:

```bash
gh workflow run build.yml -f package=all
```

The weekly schedule also rebuilds every package. Both modes run in `archlinux:latest`, generate the database with `repo-add`, and update the assets of the `repo` release.
