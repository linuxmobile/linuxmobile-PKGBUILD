#!/usr/bin/env sh
set -e

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"

if [ -r "${XDG_CONFIG_HOME}/microsoft-edge-beta-flags.conf" ]; then
  EDGE_USER_FLAGS="$(cat "$XDG_CONFIG_HOME/microsoft-edge-beta-flags.conf")"
fi

exec /opt/microsoft/msedge-beta/microsoft-edge-beta $EDGE_USER_FLAGS "$@"
