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
sudo pacman -S antigravity-cli chromium-widevine-helper hibiki isocast kavita microsoft-edge-beta multiviewer obs-pipewire-audio-capture oxfmt ps_mem rgrc rhun rlottie sonora strata
```

## Migration from AUR

The new packages declare `provides`, `conflicts`, and `replaces` for the old AUR names. To replace them explicitly:

```bash
sudo pacman -Rns antigravity-cli chromium-widevine-helper f1multiviewer-bin hibiki-bin isocast-git kavita-bin microsoft-edge-beta-bin obs-pipewire-audio-capture-bin oxfmt-bin ps_mem rgrc rhun-bin rlottie sonora-bin strata-bin
sudo pacman -S antigravity-cli chromium-widevine-helper hibiki isocast kavita microsoft-edge-beta multiviewer obs-pipewire-audio-capture oxfmt ps_mem rgrc rhun rlottie sonora strata
```

After that, remove the AUR repository from `pacman.conf` and from `yay` or `paru`.

## Packages

| Package                    | Source          | x86-64-v3 |
| -------------------------- | --------------- | --------- |
| antigravity-cli            | upstream binary | no        |
| chromium-widevine-helper   | source          | n/a (any) |
| hibiki                     | source          | yes       |
| isocast                    | source          | yes       |
| kavita                     | upstream binary | no        |
| microsoft-edge-beta        | upstream binary | no        |
| multiviewer                | upstream binary | no        |
| obs-pipewire-audio-capture | source          | yes       |
| oxfmt                      | upstream binary | no        |
| ps_mem                     | source          | n/a (any) |
| rgrc                       | source          | yes       |
| rhun                       | upstream binary | no        |
| rlottie                    | source          | yes       |
| sonora                     | upstream binary | no        |
| strata                     | upstream binary | no        |

Packages whose upstream only publishes binaries cannot be recompiled. Compiled packages use `-march=x86-64-v3` and `-C target-cpu=x86-64-v3`.

`vidicon` remains in AUR because its upstream repository no longer exists.

## Local build

```bash
./scripts/build.sh <package>
```

The script uses `config/makepkg.conf` and targets x86-64-v3.

## Publishing

Every push to `main`, manual run, or weekly schedule builds all packages in `archlinux:latest`, generates the database with `repo-add`, and updates the assets of the `repo` release.
