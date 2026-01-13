#!/usr/bin/env bash

STEP=1

# Read inner gaps (string like "35 35 35 35")
vals_in=$(hyprctl -j getoption general:gaps_in | jq -r '.custom')
read -r il it ir ib <<< "$vals_in"

# Read outer gaps (string like "5 5 5 5")
vals_out=$(hyprctl -j getoption general:gaps_out | jq -r '.custom')
read -r ol ot or ob <<< "$vals_out"

case "$1" in
  inc)
    il=$((il + STEP)); it=$((it + STEP)); ir=$((ir + STEP)); ib=$((ib + STEP))
    ol=$((ol + STEP)); ot=$((ot + STEP)); or=$((or + STEP)); ob=$((ob + STEP))
    ;;
  dec)
    il=$((il - STEP)); it=$((it - STEP)); ir=$((ir - STEP)); ib=$((ib - STEP))
    ol=$((ol - STEP)); ot=$((ot - STEP)); or=$((or - STEP)); ob=$((ob - STEP))
    # Clamp to 0
    for v in il it ir ib ol ot or ob; do
      [ "${!v}" -lt 0 ] && eval "$v=0"
    done
    ;;
  *)
    echo "Usage: $0 inc|dec"
    exit 1
    ;;
esac

hyprctl keyword general:gaps_in  "$il $it $ir $ib"
hyprctl keyword general:gaps_out "$ol $ot $or $ob"

