#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_PATH="$SCRIPT_DIR/bootstrap-lab.sh"
UNIT_PATH="/etc/systemd/system/lab-bootstrap.service"

if [[ ! -x "$SCRIPT_PATH" ]]; then
  chmod +x "$SCRIPT_PATH"
fi

cat > "$UNIT_PATH" <<EOF2
[Unit]
Description=Local Lab Bootstrap (libvirt/KVM)
After=network-online.target libvirtd.service
Wants=network-online.target

[Service]
Type=oneshot
User=root
Environment=VM_NETWORK=default
Environment=START_DELAY_SECONDS=20
Environment=LAB_VMS=eve-ng
ExecStart=$SCRIPT_PATH
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF2

systemctl daemon-reload
systemctl enable --now lab-bootstrap.service
systemctl status --no-pager lab-bootstrap.service
