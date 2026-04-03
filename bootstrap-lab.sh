#!/usr/bin/env bash
set -euo pipefail

# Simple, reboot-safe lab bootstrap for libvirt/KVM hosts.
# - ensures libvirt network is up
# - ensures selected VMs are autostart-enabled
# - starts selected VMs in sequence with delay

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
START_DELAY_SECONDS="${START_DELAY_SECONDS:-20}"
LAB_ENV_FILE="${LAB_ENV_FILE:-$SCRIPT_DIR/lab.env}"

# Override with: LAB_VMS="eve-ng adcs01 dns01"
LAB_VMS=(${LAB_VMS:-eve-ng})

log() {
  printf '[lab-bootstrap] %s\n' "$*"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    log "Missing required command: $1"
    exit 1
  }
}

virsh_system() {
  virsh -c qemu:///system "$@"
}

ensure_network() {
  local network="$1"

  if ! virsh_system net-info "$network" >/dev/null 2>&1; then
    log "Libvirt network '$network' not found."
    exit 1
  fi

  local state
  state="$(virsh_system net-info "$network" | awk -F': *' '/Active:/ {print $2}')"
  if [[ "$state" != "yes" ]]; then
    log "Starting network '$network'..."
    virsh_system net-start "$network"
  fi
  virsh_system net-autostart "$network" >/dev/null
}

ensure_vm_autostart() {
  local vm="$1"
  virsh_system dominfo "$vm" >/dev/null 2>&1 || {
    log "VM '$vm' not found; skipping."
    return 0
  }
  virsh_system autostart "$vm" >/dev/null || true
}

start_vm_if_needed() {
  local vm="$1"
  local state

  virsh_system dominfo "$vm" >/dev/null 2>&1 || {
    log "VM '$vm' not found; skipping."
    return 0
  }

  state="$(virsh_system domstate "$vm" | tr -d '\r')"
  if [[ "$state" == "running" ]]; then
    log "VM '$vm' already running."
    return 0
  fi

  log "Starting VM '$vm'..."
  virsh_system start "$vm" >/dev/null
}

main() {
  require_cmd virsh
  require_cmd awk

  if [[ -f "$LAB_ENV_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$LAB_ENV_FILE"
    LAB_VMS=(${LAB_VMS:-eve-ng})
  fi

  local networks
  if [[ -n "${VM_NETWORKS:-}" ]]; then
    networks=(${VM_NETWORKS})
  else
    networks=(${VM_NETWORK:-default})
  fi

  local network
  for network in "${networks[@]}"; do
    ensure_network "$network"
  done

  for vm in "${LAB_VMS[@]}"; do
    ensure_vm_autostart "$vm"
  done

  for vm in "${LAB_VMS[@]}"; do
    start_vm_if_needed "$vm"
    sleep "$START_DELAY_SECONDS"
  done

  log "Bootstrap complete."
}

main "$@"
