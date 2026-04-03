#!/usr/bin/env bash
set -euo pipefail

comment_for_network() {
  printf 'lab-airgap:%s' "$1"
}

usage() {
  cat <<'EOF'
Usage: sudo lab-net-egress.sh <status|block|unblock> [network...]

Known networks:
  nac-mgmt
  nac-data

Examples:
  sudo ./lab-net-egress.sh status
  sudo ./lab-net-egress.sh block nac-data
  sudo ./lab-net-egress.sh unblock nac-mgmt nac-data
EOF
}

require_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "Run as root: sudo $0 $*" >&2
    exit 1
  fi
}

bridge_for_network() {
  case "$1" in
    nac-mgmt) echo "virbr123" ;;
    nac-data) echo "virbr124" ;;
    *)
      echo "Unknown network: $1" >&2
      exit 1
      ;;
  esac
}

ensure_iptables() {
  command -v iptables >/dev/null 2>&1 || {
    echo "Missing required command: iptables" >&2
    exit 1
  }
}

has_rule() {
  local bridge="$1"
  local comment="$2"
  iptables -w -C FORWARD -i "$bridge" -m comment --comment "$comment" -j REJECT >/dev/null 2>&1
}

add_rules() {
  local network="$1"
  local bridge="$2"
  local comment
  comment="$(comment_for_network "$network")"

  if has_rule "$bridge" "$comment"; then
    printf '%s already blocked on %s\n' "$network" "$bridge"
    return 0
  fi

  iptables -w -I FORWARD 1 -i "$bridge" -m comment --comment "$comment" -j REJECT
  iptables -w -I FORWARD 1 -o "$bridge" -m conntrack --ctstate ESTABLISHED,RELATED -m comment --comment "$comment" -j REJECT
  printf 'Blocked forwarded egress for %s on %s\n' "$network" "$bridge"
}

remove_rules() {
  local network="$1"
  local bridge="$2"
  local comment
  comment="$(comment_for_network "$network")"

  while iptables -w -C FORWARD -i "$bridge" -m comment --comment "$comment" -j REJECT >/dev/null 2>&1; do
    iptables -w -D FORWARD -i "$bridge" -m comment --comment "$comment" -j REJECT
  done

  while iptables -w -C FORWARD -o "$bridge" -m conntrack --ctstate ESTABLISHED,RELATED -m comment --comment "$comment" -j REJECT >/dev/null 2>&1; do
    iptables -w -D FORWARD -o "$bridge" -m conntrack --ctstate ESTABLISHED,RELATED -m comment --comment "$comment" -j REJECT
  done

  printf 'Unblocked forwarded egress for %s on %s\n' "$network" "$bridge"
}

status_network() {
  local network="$1"
  local bridge="$2"
  local comment
  comment="$(comment_for_network "$network")"

  if has_rule "$bridge" "$comment"; then
    printf '%s (%s): blocked\n' "$network" "$bridge"
  else
    printf '%s (%s): open\n' "$network" "$bridge"
  fi
}

main() {
  local action="${1:-}"
  shift || true

  case "$action" in
    status|block|unblock) ;;
    help|-h|--help|"")
      usage
      exit 0
      ;;
    *)
      usage
      exit 1
      ;;
  esac

  ensure_iptables

  local networks=("$@")
  if [[ "${#networks[@]}" -eq 0 ]]; then
    networks=("nac-mgmt" "nac-data")
  fi

  if [[ "$action" != "status" ]]; then
    require_root "$action" "${networks[@]}"
  fi

  local network bridge
  for network in "${networks[@]}"; do
    bridge="$(bridge_for_network "$network")"
    case "$action" in
      status) status_network "$network" "$bridge" ;;
      block) add_rules "$network" "$bridge" ;;
      unblock) remove_rules "$network" "$bridge" ;;
    esac
  done
}

main "$@"
