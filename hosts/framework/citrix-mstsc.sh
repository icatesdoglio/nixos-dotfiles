#!/usr/bin/env bash
# citrix-mstsc: launch the "Remote Desktop Conn" ICA app published on
# TEAStore at a chosen window resolution, without the selfservice GUI.
#
# Usage: citrix-mstsc [WIDTH] [HEIGHT]
#   citrix-mstsc            -> 1920x1080
#   citrix-mstsc 2560 1440
set -euo pipefail

STORE="${CITRIX_STORE:-https://ctxp.teainc.org/citrix/teastore/discovery}"
WIDTH="${1:-1920}"
HEIGHT="${2:-1080}"
INI="$HOME/.ICAClient/wfclient.ini"

if [[ ! -f "$INI" ]]; then
  echo "citrix-mstsc: $INI not found -- log into Citrix Workspace at least once first" >&2
  exit 1
fi

# storebrowse has no per-launch resolution flag: session geometry comes from
# wfclient.ini's [Thinwire3.0] DesiredHRES/DesiredVRES (mstsc's /w /h
# equivalent). We patch it immediately before launch and put it back after.
resource="$(storebrowse -S "$STORE" 2>/dev/null \
  | grep -i "Remote Desktop Conn" \
  | head -n1 \
  | cut -d"'" -f2 || true)"

if [[ -z "$resource" ]]; then
  echo "citrix-mstsc: no subscribed 'Remote Desktop Conn' resource found on $STORE" >&2
  echo "(run 'storebrowse -S \"$STORE\"' to see what's actually subscribed)" >&2
  exit 1
fi

backup="$(mktemp)"
cp "$INI" "$backup"
restore() { mv "$backup" "$INI"; }
trap restore EXIT

sed -i \
  -e "s/^DesiredHRES.*/DesiredHRES = ${WIDTH}/" \
  -e "s/^DesiredVRES.*/DesiredVRES = ${HEIGHT}/" \
  -e "s/^UseFullScreen.*/UseFullScreen=False/" \
  "$INI"

echo "citrix-mstsc: launching '$resource' at ${WIDTH}x${HEIGHT}" >&2
storebrowse -L "$resource" "$STORE"

# storebrowse hands off to wfica and returns once the session is launching;
# give wfica a moment to have read wfclient.ini before we restore it.
sleep 3
