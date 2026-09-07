#!/usr/bin/env bash
# System-level setup for an Arch machine, from the system/ tree in this repo.
#
#   sudo ./install_system.sh [--nvidia|--no-nvidia] [--dev-services] [--no-boot] [--pacman-only] [--dry-run]
#
# Every step is idempotent. Files are compared before they are written and
# each step reports what it changed. --dry-run needs no root and prints the
# diff of every file it would write.
#
# What it does:
#   pacman.conf     Color, VerbosePkgLists, ParallelDownloads = 5, ILoveCandy
#   /etc            uinput module + udev rule (xremap), sddm.conf, zram
#   /etc (nvidia)   runtime D3 power management, SDDM greeter on the primary GPU
#   /boot           nvidia_drm.modeset=1 on the kernel line and a rescue entry
#                   with the NVIDIA modules blacklisted (systemd-boot only)
#   sddm theme      pinned clone of JaKooLit/simple-sddm-2 plus our theme.conf
#   swww            symlinks to awww for the JaKooLit scripts
#   groups          uinput, input, wheel (+docker, nordvpn when relevant)
#   services        desktop set, plus docker/postgresql/valkey with --dev-services
#
# NVIDIA is detected from PCI vendor 0x10de with a display class. The flags
# override detection. mkinitcpio.conf is left alone: this setup depends on an
# empty MODULES=() so the NVIDIA driver is not in the initramfs.
set -euo pipefail

REPO="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
SYS="$REPO/system"

NVIDIA=auto
DEV_SERVICES=0
DO_BOOT=1
PACMAN_ONLY=0
DRY=0

RESCUE_ENTRY=zz-linux-nvidia-disabled.conf
NVIDIA_TOKEN='nvidia_drm.modeset=1'
BLACKLIST_TOKEN='modprobe.blacklist=nouveau,nvidia,nvidia_drm,nvidia_modeset,nvidia_uvm'
SDDM_THEME_REPO=https://github.com/JaKooLit/simple-sddm-2.git
SDDM_THEME_REV=fa1ffbda06bc363a5a4103a155a4b65d4f910514
SDDM_THEME_DIR=/usr/share/sddm/themes/simple_sddm_2
# Overridable so the boot logic can be tested against a scratch directory.
ENTRIES_DIR="${ENTRIES_DIR:-/boot/loader/entries}"
LOADER_CONF="${LOADER_CONF:-/boot/loader/loader.conf}"

log() { printf '%s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }
run() {
  if [ "$DRY" = 1 ]; then log "    dry-run: $*"; else "$@"; fi
}

usage() { sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'; }

parse_args() {
  local a
  for a in "$@"; do
    case "$a" in
      --nvidia) NVIDIA=yes ;;
      --no-nvidia) NVIDIA=no ;;
      --dev-services) DEV_SERVICES=1 ;;
      --no-boot) DO_BOOT=0 ;;
      --pacman-only) PACMAN_ONLY=1 ;;
      --dry-run) DRY=1 ;;
      -h|--help) usage; exit 0 ;;
      *) die "unknown option: $a" ;;
    esac
  done
}

detect_nvidia() {
  case "$NVIDIA" in
    yes) return 0 ;;
    no) return 1 ;;
  esac
  local d
  for d in /sys/bus/pci/devices/*; do
    [ -r "$d/vendor" ] && [ -r "$d/class" ] || continue
    if [ "$(cat "$d/vendor")" = "0x10de" ] && [[ "$(cat "$d/class")" == 0x03* ]]; then
      return 0
    fi
  done
  return 1
}

# install_file SRC DST [MODE]: write DST from SRC only when the content differs.
install_file() {
  local src="$1" dst="$2" mode="${3:-644}"
  if [ -f "$dst" ] && cmp -s "$src" "$dst"; then
    log "  unchanged $dst"
    return
  fi
  if [ -f "$dst" ]; then
    log "  update    $dst"
    if [ "$DRY" = 1 ]; then diff -u "$dst" "$src" | sed 's/^/      /' || true; fi
  else
    log "  create    $dst"
    if [ "$DRY" = 1 ]; then sed 's/^/      | /' "$src"; fi
  fi
  run install -Dm"$mode" "$src" "$dst"
}

remove_file() {
  if [ -e "$1" ] || [ -L "$1" ]; then
    log "  remove    $1"
    run rm -f "$1"
  fi
}

configure_pacman() {
  log "pacman.conf"
  local f=/etc/pacman.conf changed=0 opt
  for opt in Color VerbosePkgLists; do
    if grep -q "^#$opt\$" "$f"; then
      log "  enable $opt"
      run sed -i "s/^#$opt\$/$opt/" "$f"
      changed=1
    fi
  done
  if grep -q '^#ParallelDownloads' "$f"; then
    log "  enable ParallelDownloads = 5"
    run sed -i 's/^#ParallelDownloads.*/ParallelDownloads = 5/' "$f"
    changed=1
  fi
  if ! grep -q '^ILoveCandy' "$f"; then
    log "  add ILoveCandy"
    run sed -i '/^Color$/a ILoveCandy' "$f"
    changed=1
  fi
  [ "$changed" = 1 ] || log "  unchanged"
}

install_etc_common() {
  log "etc (all machines)"
  install_file "$SYS/etc/modules-load.d/uinput.conf" /etc/modules-load.d/uinput.conf
  install_file "$SYS/etc/udev/rules.d/99-uinput.rules" /etc/udev/rules.d/99-uinput.rules
  install_file "$SYS/etc/sddm.conf" /etc/sddm.conf
  install_file "$SYS/etc/systemd/zram-generator.conf" /etc/systemd/zram-generator.conf
}

install_etc_nvidia() {
  if [ "$HAS_NVIDIA" = 1 ]; then
    log "etc (nvidia)"
    install_file "$SYS/etc/modprobe.d/nvidia-pm.conf" /etc/modprobe.d/nvidia-pm.conf
    install_file "$SYS/etc/X11/xorg.conf.d/10-sddm-intel-only.conf" /etc/X11/xorg.conf.d/10-sddm-intel-only.conf
  else
    log "etc (nvidia): no NVIDIA GPU, skipped"
  fi
}

has_systemd_boot() {
  bootctl is-installed >/dev/null 2>&1 || [ -f "$LOADER_CONF" ] || [ -d "$ENTRIES_DIR" ]
}

configure_boot() {
  log "boot"
  if [ "$DO_BOOT" = 0 ]; then log "  skipped (--no-boot)"; return; fi
  if ! has_systemd_boot; then log "  systemd-boot not found, skipped"; return; fi
  local dir="$ENTRIES_DIR" entry tmp options
  entry=$(grep -lsE '^linux[[:space:]]+/vmlinuz-linux$' "$dir"/*.conf 2>/dev/null \
            | grep -v "/$RESCUE_ENTRY\$" | head -1 || true)
  if [ -z "$entry" ]; then
    entry="$dir/linux.conf"
    local partuuid fstype
    partuuid=$(findmnt -no PARTUUID /)
    fstype=$(findmnt -no FSTYPE /)
    [ -n "$partuuid" ] || die "cannot read the root PARTUUID"
    log "  no entry for /vmlinuz-linux found, rendering $entry from the template"
    tmp=$(mktemp)
    sed "s/@ROOT_PARTUUID@/$partuuid/; s/@ROOT_FSTYPE@/$fstype/" \
      "$SYS/boot/loader/entries/linux.conf.in" > "$tmp"
    install_file "$tmp" "$entry" 755
    rm -f "$tmp"
    options=$(grep -E '^options[[:space:]]' "$SYS/boot/loader/entries/linux.conf.in" \
                | sed -E "s/^options[[:space:]]+//; s/@ROOT_PARTUUID@/$partuuid/; s/@ROOT_FSTYPE@/$fstype/")
  else
    log "  main entry: $entry"
    options=$(grep -E '^options[[:space:]]' "$entry" | head -1 | sed -E 's/^options[[:space:]]+//')
  fi

  if [ "$HAS_NVIDIA" = 1 ]; then
    if ! grep -qw "$NVIDIA_TOKEN" <<<"$options"; then
      log "  add $NVIDIA_TOKEN to $(basename "$entry")"
      run sed -i -E "/^options[[:space:]]/ s/\$/ $NVIDIA_TOKEN/" "$entry"
      options="$options $NVIDIA_TOKEN"
    fi
    local rescue_opts
    rescue_opts=$(sed "s/ *$NVIDIA_TOKEN//" <<<"$options")
    tmp=$(mktemp)
    {
      echo "title   Arch Linux (NVIDIA disabled, rescue)"
      if [ -f "$entry" ]; then
        grep -E '^(linux|initrd)[[:space:]]' "$entry"
      else
        grep -E '^(linux|initrd)[[:space:]]' "$SYS/boot/loader/entries/linux.conf.in"
      fi
      echo "options $rescue_opts $BLACKLIST_TOKEN"
    } > "$tmp"
    install_file "$tmp" "$dir/$RESCUE_ENTRY" 755
    rm -f "$tmp"
  else
    if grep -qw "$NVIDIA_TOKEN" <<<"$options"; then
      log "  remove $NVIDIA_TOKEN from $(basename "$entry") (no NVIDIA GPU)"
      run sed -i -E "/^options[[:space:]]/ s/ *$NVIDIA_TOKEN//" "$entry"
    fi
    remove_file "$dir/$RESCUE_ENTRY"
  fi

  tmp=$(mktemp)
  sed "s/@DEFAULT_ENTRY@/$(basename "$entry")/" "$SYS/boot/loader/loader.conf" > "$tmp"
  install_file "$tmp" "$LOADER_CONF" 755
  rm -f "$tmp"
}

install_sddm_theme() {
  log "sddm theme"
  if [ ! -d "$SDDM_THEME_DIR" ]; then
    log "  clone $SDDM_THEME_REPO at $SDDM_THEME_REV"
    run git clone -q --revision="$SDDM_THEME_REV" "$SDDM_THEME_REPO" "$SDDM_THEME_DIR"
  else
    log "  present   $SDDM_THEME_DIR"
  fi
  if [ -d "$SDDM_THEME_DIR" ] && [ "$(stat -c %U "$SDDM_THEME_DIR")" != root ]; then
    log "  chown root:root $SDDM_THEME_DIR"
    run chown -R root:root "$SDDM_THEME_DIR"
  fi
  install_file "$SYS/usr/share/sddm/themes/simple_sddm_2/theme.conf" "$SDDM_THEME_DIR/theme.conf"
}

setup_swww_compat() {
  log "swww symlinks (JaKooLit scripts call swww, the package is awww)"
  if [ ! -x /usr/bin/awww ]; then log "  awww not installed, skipped"; return; fi
  local b
  for b in swww swww-daemon; do
    if [ -e "/usr/bin/$b" ] || [ -L "/usr/bin/$b" ]; then
      log "  present   /usr/bin/$b"
    else
      log "  link      /usr/bin/$b -> /usr/bin/${b/swww/awww}"
      run ln -s "/usr/bin/${b/swww/awww}" "/usr/bin/$b"
    fi
  done
}

setup_groups() {
  log "groups"
  if ! getent group uinput >/dev/null; then
    log "  create group uinput"
    run groupadd uinput
  fi
  if [ -z "$TARGET_USER" ]; then log "  no SUDO_USER, user membership skipped"; return; fi
  local groups="wheel input uinput" g
  [ "$DEV_SERVICES" = 1 ] && groups="$groups docker"
  pacman -Q nordvpn-bin >/dev/null 2>&1 && groups="$groups nordvpn"
  for g in $groups; do
    if ! getent group "$g" >/dev/null; then log "  group $g does not exist, skipped"; continue; fi
    if id -nG "$TARGET_USER" | tr ' ' '\n' | grep -qx "$g"; then
      log "  member    $g"
    else
      log "  add $TARGET_USER to $g"
      run usermod -aG "$g" "$TARGET_USER"
    fi
  done
}

enable_services() {
  log "services"
  local units="NetworkManager.service bluetooth.service sddm.service power-profiles-daemon.service systemd-timesyncd.service fstrim.timer" u
  [ "$DEV_SERVICES" = 1 ] && units="$units docker.service postgresql.service valkey.service"
  pacman -Q nordvpn-bin >/dev/null 2>&1 && units="$units nordvpnd.service"
  for u in $units; do
    if ! systemctl list-unit-files --no-legend "$u" 2>/dev/null | grep -q .; then
      log "  $u not installed, skipped"
      continue
    fi
    if systemctl is-enabled -q "$u" 2>/dev/null; then
      log "  enabled   $u"
    else
      log "  enable    $u"
      run systemctl enable "$u"
    fi
  done
}

reload() {
  log "reload udev, uinput module, systemd"
  run udevadm control --reload
  run udevadm trigger --subsystem-match=misc
  run modprobe uinput
  run systemctl daemon-reload
}

check_mkinitcpio() {
  log "mkinitcpio.conf"
  local mods
  mods=$(grep -E '^MODULES=' /etc/mkinitcpio.conf || true)
  if [ "$mods" = "MODULES=()" ]; then
    log "  MODULES=() as expected: the NVIDIA driver is not in the initramfs, nvidia_drm.modeset=1 on the kernel line is enough"
  else
    log "  WARNING: $mods"
    log "  this setup expects an empty MODULES list so the NVIDIA driver loads after early boot; review before rebooting"
  fi
}

main() {
  parse_args "$@"
  if [ "$DRY" = 0 ] && [ "$(id -u)" != 0 ]; then die "run with sudo (or add --dry-run)"; fi
  TARGET_USER="${SUDO_USER:-}"
  if [ "$DRY" = 1 ] && [ -z "$TARGET_USER" ]; then TARGET_USER="$(id -un)"; fi
  if detect_nvidia; then HAS_NVIDIA=1; else HAS_NVIDIA=0; fi

  log "repo:   $REPO"
  log "nvidia: $([ "$HAS_NVIDIA" = 1 ] && echo yes || echo no) (mode: $NVIDIA)"
  log "user:   ${TARGET_USER:-none}"
  [ "$DRY" = 1 ] && log "DRY RUN: nothing is written"
  echo

  configure_pacman
  if [ "$PACMAN_ONLY" = 1 ]; then return; fi
  install_etc_common
  install_etc_nvidia
  configure_boot
  install_sddm_theme
  setup_swww_compat
  setup_groups
  enable_services
  reload
  check_mkinitcpio
  echo
  log "done"
}

main "$@"
