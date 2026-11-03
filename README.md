# linuxmobile PKGBUILD

Arch and CachyOS package repository built with GitHub Actions and published as a pacman repository through GitHub Releases.

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
sudo pacman -S anix antigravity-cli blurcam chromium-widevine-helper hibiki \
isocast kavita kernwatch lui mdrs microsoft-edge-beta multiviewer netwatch \
obs-pipewire-audio-capture omalive omatuner oxfmt ps_mem \
rawmakase rgrc rhun rlottie rusty-inbox sonora strata syswatch
```

## Migration from AUR

The new packages declare `provides`, `conflicts`, and `replaces` for the old AUR names. To replace them explicitly:

```bash
sudo pacman -Rns antigravity-cli chromium-widevine-helper f1multiviewer-bin hibiki-bin \
isocast-git kavita-bin kernwatch microsoft-edge-beta-bin obs-pipewire-audio-capture-bin \
oxfmt-bin ps_mem rawmakase rgrc rhun-bin rlottie rusty-inbox sonora-bin strata-bin syswatch
```

```bash
sudo pacman -S anix antigravity-cli blurcam chromium-widevine-helper hibiki \
isocast kavita kernwatch lui mdrs microsoft-edge-beta multiviewer netwatch \
obs-pipewire-audio-capture omalive omatuner oxfmt ps_mem \
rawmakase rgrc rhun rlottie rusty-inbox sonora strata syswatch
```

After that, remove the AUR repository from `pacman.conf` and from `yay` or `paru`.

## Packages

The repository targets **x86-64-v3 CPUs**. `arch=('x86_64')` in pacman metadata does not encode an ISA level, so pacman will not prevent installation on an older x86-64 processor. Do not install this repository on a CPU that lacks x86-64-v3 support.

| Package                    | Payload / build           | x86-64-v3 status                                         |
| -------------------------- | ------------------------- | -------------------------------------------------------- |
| anix                       | Upstream Debian package   | Upstream binary; not guaranteed                          |
| antigravity-cli            | Upstream binary archive   | Upstream binary; not guaranteed                          |
| blurcam                    | CMake/C++                 | Enforced by CI                                           |
| chromium-widevine-helper   | Python / assets           | n/a (`any`)                                              |
| cressida                   | Meson/C++                 | Enforced by CI                                           |
| hibiki                     | Rust                      | Enforced by CI                                           |
| isocast                    | Rust                      | Enforced by CI                                           |
| kavita                     | .NET ReadyToRun           | Not guaranteed; not pinned to v3                         |
| kernwatch                  | Rust                      | Enforced by CI                                           |
| lui                        | Zig                       | v3 target explicitly selected; GNU ISA note not asserted |
| mdrs                       | Rust                      | Enforced by CI                                           |
| microsoft-edge-beta        | Upstream Debian package   | Upstream binary; not guaranteed                          |
| multiviewer                | Upstream Electron archive | Upstream binary; not guaranteed                          |
| netwatch                   | Rust                      | Enforced by CI                                           |
| obs-pipewire-audio-capture | CMake/C++                 | Enforced by CI                                           |
| omalive                    | Rust                      | Enforced by CI                                           |
| omatuner                   | Rust                      | Enforced by CI                                           |
| oxfmt                      | Rust                      | Enforced by CI                                           |
| ps_mem                     | Python                    | n/a (`any`)                                              |
| rawmakase                  | Rust + ONNX Runtime       | Partial; bundled ONNX Runtime is upstream                |
| rgrc                       | Rust                      | Enforced by CI                                           |
| rhun                       | Assembly                  | Not guaranteed; instruction set not audited              |
| rlottie                    | CMake/C++                 | Enforced by CI                                           |
| rusty-inbox                | Rust                      | Enforced by CI                                           |
| sonora                     | Rust                      | Enforced by CI                                           |
| strata                     | Rust                      | Enforced by CI                                           |
| syswatch                   | Rust                      | Enforced by CI                                           |

C/C++ builds receive `-march=x86-64-v3` and the linker requirement `-Wl,-z,x86-64-v3`. Rust builds receive `-C target-cpu=x86-64-v3` and the equivalent linker argument. `lui` pins Zig's CPU target directly in its PKGBUILD. Rawmakase bundles an upstream ONNX Runtime library, while Kavita and Rhun need separate work before they can be described as fully v3-targeted.

CI checks the GNU `x86 ISA needed` property on every x86-64 ELF in packages marked `required`, with a documented exception for Rawmakase's bundled ONNX Runtime. Upstream binaries and architecture-independent packages are explicitly exempt from this check; the policy lives in `config/isa-policy.tsv`.

## Local build

```bash
./scripts/build.sh <package>
```

The script uses `config/makepkg.conf` and targets x86-64-v3. After building, run `./scripts/validate-package-isa.sh <package>` to check the package against `config/isa-policy.tsv`.

## Publishing

Every push to `main` builds only the packages changed by that push. Manual runs and the weekly schedule rebuild every package.
Both modes run in `archlinux:latest`, generate the database with `repo-add`, and update the assets of the `repo` release.
