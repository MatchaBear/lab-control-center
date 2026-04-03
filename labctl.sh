#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
VIRSH_URI="${VIRSH_URI:-qemu:///system}"
LAB_ENV_FILE="${LAB_ENV_FILE:-$SCRIPT_DIR/lab.env}"
BOOTSTRAP_SERVICE="${BOOTSTRAP_SERVICE:-lab-bootstrap.service}"

usage() {
  cat <<'EOF2'
Usage: labctl.sh <command>

Commands:
  status      Show host+libvirt+bootstrap status
  vms         List VMs
  nets        List libvirt networks
  start       Start bootstrap service now
  restart     Restart bootstrap service
  stop        Stop all VMs listed in lab.env (graceful)
  env         Print lab.env
  help        Show this help
EOF2
}

virsh_system() {
  virsh -c "$VIRSH_URI" "$@"
}

load_env() {
  if [[ -f "$LAB_ENV_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$LAB_ENV_FILE"
    LAB_VMS=(${LAB_VMS:-})
  else
    LAB_VMS=()
  fi
}

cmd_status() {
  echo "== Host =="
  nproc || true
  free -h || true
  echo
  echo "== Bootstrap Service =="
  systemctl status --no-pager "$BOOTSTRAP_SERVICE" || true
  echo
  echo "== VMs =="
  virsh_system list --all || true
  echo
  echo "== Networks =="
  virsh_system net-list --all || true
}

cmd_vms() {
  virsh_system list --all
}

cmd_nets() {
  virsh_system net-list --all
}

cmd_start() {
  sudo systemctl start "$BOOTSTRAP_SERVICE"
  sudo systemctl status --no-pager "$BOOTSTRAP_SERVICE"
}

cmd_restart() {
  sudo systemctl restart "$BOOTSTRAP_SERVICE"
  sudo systemctl status --no-pager "$BOOTSTRAP_SERVICE"
}

cmd_stop() {
  load_env
  if [[ "${#LAB_VMS[@]}" -eq 0 ]]; then
    echo "No LAB_VMS found in $LAB_ENV_FILE"
    exit 0
  fi
  for vm in "${LAB_VMS[@]}"; do
    if virsh_system dominfo "$vm" >/dev/null 2>&1; then
      state="$(virsh_system domstate "$vm" | tr -d '\r')"
      if [[ "$state" == "running" ]]; then
        echo "Shutting down $vm..."
        virsh_system shutdown "$vm" || true
      else
        echo "$vm is $state"
      fi
    else
      echo "$vm not defined, skipping"
    fi
  done
}

cmd_env() {
  sed -n '1,200p' "$LAB_ENV_FILE"
}

main() {
  command="${1:-help}"
  case "$command" in
    status) cmd_status ;;
    vms) cmd_vms ;;
    nets) cmd_nets ;;
    start) cmd_start ;;
    restart) cmd_restart ;;
    stop) cmd_stop ;;
    env) cmd_env ;;
    help|-h|--help) usage ;;
    *) usage; exit 1 ;;
  esac
}

main "$@"
