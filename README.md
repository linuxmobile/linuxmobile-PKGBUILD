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
isocast kavita kernwatch koe lui mdrs microsoft-edge-beta multiviewer netwatch \
obs-pipewire-audio-capture omalive omarchy-bitwarden omatuner oxfmt ps_mem \
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
isocast kavita kernwatch koe lui mdrs microsoft-edge-beta multiviewer netwatch \
obs-pipewire-audio-capture omalive omarchy-bitwarden omatuner oxfmt ps_mem \
rawmakase rgrc rhun rlottie rusty-inbox sonora strata syswatch
```

After that, remove the AUR repository from `pacman.conf` and from `yay` or `paru`.

## Packages

| Package                    | Source          | x86-64-v3 |
| -------------------------- | --------------- | --------- |
| anix                       | upstream .deb   | no        |
| antigravity-cli            | upstream binary | no        |
| blurcam                    | source          | yes       |
| chromium-widevine-helper   | source          | n/a (any) |
| hibiki                     | source          | yes       |
| isocast                    | source          | yes       |
| kavita                     | source          | yes       |
| kernwatch                  | source          | yes       |
| koe                        | source          | yes       |
| lui                        | source          | yes       |
| mdrs                       | source          | yes       |
| microsoft-edge-beta        | upstream binary | no        |
| multiviewer                | upstream binary | no        |
| netwatch                   | source          | yes       |
| obs-pipewire-audio-capture | source          | yes       |
| omalive                    | source          | yes       |
| omarchy-bitwarden          | source          | n/a (QML) |
| omatuner                   | source          | yes       |
| oxfmt                      | source          | yes       |
| ps_mem                     | source          | n/a (any) |
| rawmakase                  | source          | yes       |
| rgrc                       | source          | yes       |
| rhun                       | source          | yes       |
| rlottie                    | source          | yes       |
| rusty-inbox                | source          | yes       |
| sonora                     | source          | yes       |
| strata                     | source          | yes       |
| syswatch                   | source          | yes       |

Packages whose upstream only publishes binaries cannot be recompiled. Compiled packages use `-march=x86-64-v3` and `-C target-cpu=x86-64-v3`.

`omarchy-bitwarden` installs the QML plugin files under `/usr/share/omarchy/plugins/icyleaf.bitwarden` and does
not modify user configuration. It uses the `omawarden-bin` engine from the AUR. Omarchy loads third-party plugins
from `~/.config/omarchy/plugins`, so enable it with the normal Omarchy plugin workflow if you want the shell to load it.

## Local build

```bash
./scripts/build.sh <package>
```

The script uses `config/makepkg.conf` and targets x86-64-v3.

## Publishing

Every push to `main` builds only the packages changed by that push. Manual runs and the weekly schedule rebuild every package.
Both modes run in `archlinux:latest`, generate the database with `repo-add`, and update the assets of the `repo` release.
