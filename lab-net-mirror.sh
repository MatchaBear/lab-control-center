#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: sudo lab-net-mirror.sh <status|enable|disable>

Mirrors traffic from the host-side lab bridges into the third NIC on:
  - cppm611-clabv (vnet6)
  - cppm612-clabv (vnet5)

Sources:
  - virbr0    (192.168.122.0/24)
  - virbr123  (192.168.123.0/24)
  - virbr124  (192.168.124.0/24)
  - wlp2s0    (host-visible Wi-Fi traffic only)

Notes:
  - Mirroring wlp2s0 does not expose all traffic on 192.168.68.0/24.
    It only mirrors traffic this host actually sees on its Wi-Fi NIC.
  - This mirrors both ingress and egress on each source device.
EOF
}

require_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "Run as root: sudo $0 $*" >&2
    exit 1
  fi
}

require_cmds() {
  command -v tc >/dev/null 2>&1 || {
    echo "Missing required command: tc" >&2
    exit 1
  }
  command -v ip >/dev/null 2>&1 || {
    echo "Missing required command: ip" >&2
    exit 1
  }
}

targets=(vnet5 vnet6)
sources=(virbr0 virbr123 virbr124 wlp2s0)

device_exists() {
  ip link show dev "$1" >/dev/null 2>&1
}

ensure_clsact() {
  local dev="$1"
  tc qdisc add dev "$dev" clsact 2>/dev/null || true
}

delete_filters() {
  local dev="$1"
  tc filter del dev "$dev" ingress pref 10 matchall 2>/dev/null || true
  tc filter del dev "$dev" egress pref 10 matchall 2>/dev/null || true
}

add_filters() {
  local dev="$1"
  ensure_clsact "$dev"
  delete_filters "$dev"

  tc filter add dev "$dev" ingress pref 10 matchall \
    action mirred egress mirror dev "${targets[0]}" \
    action mirred egress mirror dev "${targets[1]}"

  tc filter add dev "$dev" egress pref 10 matchall \
    action mirred egress mirror dev "${targets[0]}" \
    action mirred egress mirror dev "${targets[1]}"
}

show_status() {
  local dev
  for dev in "${sources[@]}"; do
    if ! device_exists "$dev"; then
      printf '%s: missing\n' "$dev"
      continue
    fi

    printf '%s:\n' "$dev"
    tc filter show dev "$dev" ingress || true
    tc filter show dev "$dev" egress || true
    printf '\n'
  done
}

enable_all() {
  local dev
  for dev in "${sources[@]}"; do
    if device_exists "$dev"; then
      add_filters "$dev"
      printf 'Enabled mirror on %s -> %s, %s\n' "$dev" "${targets[0]}" "${targets[1]}"
    else
      printf 'Skipped missing device %s\n' "$dev"
    fi
  done
}

disable_all() {
  local dev
  for dev in "${sources[@]}"; do
    if device_exists "$dev"; then
      delete_filters "$dev"
      printf 'Disabled mirror on %s\n' "$dev"
    else
      printf 'Skipped missing device %s\n' "$dev"
    fi
  done
}

main() {
  local action="${1:-}"

  case "$action" in
    status)
      require_cmds
      show_status
      ;;
    enable)
      require_root "$action"
      require_cmds
      enable_all
      ;;
    disable)
      require_root "$action"
      require_cmds
      disable_all
      ;;
    help|-h|--help|"")
      usage
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
