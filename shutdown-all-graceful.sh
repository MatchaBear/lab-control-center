#!/usr/bin/env bash
set -euo pipefail

URI="${URI:-qemu:///system}"
INTERVAL_SECONDS="${INTERVAL_SECONDS:-15}"
MAX_ROUNDS="${MAX_ROUNDS:-18}" # default: up to 3 minutes

list_running() {
  virsh -c "$URI" list --name | sed '/^$/d'
}

echo "[graceful-stop] Starting graceful shutdown loop..."
round=1

while (( round <= MAX_ROUNDS )); do
  mapfile -t running < <(list_running)

  if [[ "${#running[@]}" -eq 0 ]]; then
    echo "[graceful-stop] All VMs are shut down."
    exit 0
  fi

  echo "[graceful-stop] Round $round: ${#running[@]} VM(s) still running."
  for vm in "${running[@]}"; do
    echo "  -> shutdown $vm"
    virsh -c "$URI" shutdown "$vm" >/dev/null || true
  done

  echo "[graceful-stop] Waiting ${INTERVAL_SECONDS}s before re-check..."
  sleep "$INTERVAL_SECONDS"
  ((round++))
done

echo "[graceful-stop] Timeout reached; these VMs are still running:"
list_running || true
echo "[graceful-stop] No force-stop was used."
exit 1
