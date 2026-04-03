#!/usr/bin/env bash
set -euo pipefail

VIRSH_URI="${VIRSH_URI:-qemu:///system}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${ROOT_DIR:-$SCRIPT_DIR}"

NETWORK_XMLS=(
  "$ROOT_DIR/libvirt-network-nac-mgmt.xml"
  "$ROOT_DIR/libvirt-network-nac-data.xml"
)

log() {
  printf '[install-lab-networks] %s\n' "$*"
}

virsh_system() {
  virsh -c "$VIRSH_URI" "$@"
}

network_name_from_xml() {
  sed -n "s:.*<name>\\(.*\\)</name>.*:\\1:p" "$1" | head -n 1
}

define_if_missing() {
  local xml="$1"
  local net

  [[ -f "$xml" ]] || {
    log "Missing XML: $xml"
    exit 1
  }

  net="$(network_name_from_xml "$xml")"
  [[ -n "$net" ]] || {
    log "Could not parse network name from $xml"
    exit 1
  }

  if virsh_system net-info "$net" >/dev/null 2>&1; then
    log "Network '$net' already defined."
  else
    log "Defining network '$net' from $xml"
    virsh_system net-define "$xml"
  fi

  virsh_system net-autostart "$net" >/dev/null

  if [[ "$(virsh_system net-info "$net" | awk -F': *' '/Active:/ {print $2}')" != "yes" ]]; then
    log "Starting network '$net'"
    virsh_system net-start "$net"
  else
    log "Network '$net' already active."
  fi
}

main() {
  command -v virsh >/dev/null 2>&1 || {
    log "Missing required command: virsh"
    exit 1
  }

  for xml in "${NETWORK_XMLS[@]}"; do
    define_if_missing "$xml"
  done

  log "Done."
}

main "$@"
