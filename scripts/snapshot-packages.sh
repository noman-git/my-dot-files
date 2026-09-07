#!/usr/bin/env bash
# Compare pkgs/*.txt with the packages installed on this machine.
#
#   scripts/snapshot-packages.sh          report differences, exit 1 if there are any
#   scripts/snapshot-packages.sh --write  also append unlisted native packages to
#                                         pkgs/unsorted.txt and unlisted AUR packages
#                                         to pkgs/aur.txt, so nothing is forgotten
#
# "unlisted" means installed explicitly but in no list. "missing" means listed
# but not installed. "dependency only" means listed and installed, but pacman
# has it marked as a dependency; a fresh install marks it explicit, and
# `sudo pacman -D --asexplicit <pkg>` aligns this machine.
set -euo pipefail

REPO="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
PKGS="$REPO/pkgs"
WRITE=0
[ "${1:-}" = "--write" ] && WRITE=1

pkg_list() { grep -hv '^[[:space:]]*#' "$@" | sed 's/[[:space:]]*#.*//' | awk 'NF' | sort -u; }

native_lists=()
for f in base hyprland fonts dev apps tools intel nvidia unsorted; do
  [ -f "$PKGS/$f.txt" ] && native_lists+=("$PKGS/$f.txt")
done

listed_native=$(pkg_list "${native_lists[@]}")
listed_aur=$(pkg_list "$PKGS/aur.txt")
explicit_native=$(pacman -Qqen | sort)
all_native=$(pacman -Qqn | sort)
explicit_aur=$(pacman -Qqem | sort)
all_aur=$(pacman -Qqm | sort)

unlisted_native=$(comm -23 <(echo "$explicit_native") <(echo "$listed_native"))
missing_native=$(comm -23 <(echo "$listed_native") <(echo "$all_native"))
deponly_native=$(comm -12 <(echo "$listed_native") <(comm -23 <(echo "$all_native") <(echo "$explicit_native")))
unlisted_aur=$(comm -23 <(echo "$explicit_aur") <(echo "$listed_aur"))
missing_aur=$(comm -23 <(echo "$listed_aur") <(echo "$all_aur"))
deponly_aur=$(comm -12 <(echo "$listed_aur") <(comm -23 <(echo "$all_aur") <(echo "$explicit_aur")))

report() { # title body
  [ -n "$2" ] || return 0
  printf '%s\n' "$1"
  printf '%s\n' "$2" | sed 's/^/  /'
}

report "native: installed explicitly but not in any list" "$unlisted_native"
report "native: listed but not installed" "$missing_native"
report "native: listed, installed as a dependency only" "$deponly_native"
report "aur: installed explicitly but not in pkgs/aur.txt" "$unlisted_aur"
report "aur: listed but not installed" "$missing_aur"
report "aur: listed, installed as a dependency only" "$deponly_aur"

if [ "$WRITE" = 1 ]; then
  if [ -n "$unlisted_native" ]; then
    { [ -f "$PKGS/unsorted.txt" ] || echo "# Added by scripts/snapshot-packages.sh --write. Sort into the other lists."; printf '%s\n' "$unlisted_native"; } >> "$PKGS/unsorted.txt"
    echo "wrote $PKGS/unsorted.txt"
  fi
  if [ -n "$unlisted_aur" ]; then
    printf '%s\n' "$unlisted_aur" >> "$PKGS/aur.txt"
    echo "updated $PKGS/aur.txt"
  fi
fi

if [ -z "$unlisted_native$missing_native$unlisted_aur$missing_aur" ]; then
  echo "package lists match this machine ($(echo "$listed_native" | wc -l) native, $(echo "$listed_aur" | wc -l) aur)"
  exit 0
fi
exit 1
