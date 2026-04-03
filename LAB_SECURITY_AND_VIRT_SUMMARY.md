# Lab + Security Summary (Plain English)

Contributors: bermekbukair, Codex

Last updated: 2026-03-27 (Asia/Singapore)

## 1) What we did

- Updated system packages and snaps.
- Enabled firewall (`ufw`) with:
  - Block all incoming traffic by default.
  - Allow outgoing traffic by default.
- Enabled and verified AppArmor (Linux app sandboxing).
- Installed and enabled `fail2ban` (auto-blocks repeated suspicious login attempts).
- Created a boot-time lab bootstrap service so your VM can auto-start after reboot.
- Applied custom `sysctl` hardening values (kernel/network safety knobs).

## 2) Current machine security state (high level)

- System patched: yes (at time of check).
- Firewall active: yes.
- Incoming default policy: `deny`.
- Outgoing default policy: `allow`.
- AppArmor: loaded and enforcing many profiles.
- SSH server: not running (good for reducing remote attack surface unless you need it).

Important note:
- `rp_filter` is currently `2` from existing Ubuntu config. This is often better for virtualized/lab networking than strict mode `1`.

## 3) Current virtual lab state

Host capacity:
- CPU threads: `8`
- RAM: `31 GiB` total

VMs currently defined:
- `eve-ng` (running)

`eve-ng` metadata:
- UUID: `298e1124-2444-4023-a57d-bf47bc298013`
- vCPU: `8`
- RAM: `24 GiB`
- Autostart: enabled
- Disk: `/var/lib/libvirt/images/eve-ng.qcow2`

Disk usage (eve-ng):
- Virtual capacity: about `250 GiB`
- Allocated/used on host: about `87 GiB` (changes over time)

Libvirt network:
- Network: `default`
- Mode: NAT
- Bridge: `virbr0`
- Subnet: `192.168.122.0/24`
- DHCP range: `192.168.122.2` to `192.168.122.254`

## 4) Where everything is (full paths)

Lab automation scripts:
- `$REPO_DIR/bootstrap-lab.sh`
- `$REPO_DIR/install-systemd-bootstrap.sh`

This summary:
- `$REPO_DIR/LAB_SECURITY_AND_VIRT_SUMMARY.md`

Systemd unit (boot automation):
- `/etc/systemd/system/lab-bootstrap.service`

Libvirt VM/network XML:
- `/etc/libvirt/qemu/eve-ng.xml`
- `/etc/libvirt/qemu/networks/default.xml`
- `/etc/libvirt/qemu/networks/autostart/default.xml`

Custom sysctl hardening file:
- `/etc/sysctl.d/99-security-hardening.conf`

## 5) How boot automation works (ELI15)

Think of `systemd` as the machine's startup checklist.

When your PC boots:
1. `systemd` sees `lab-bootstrap.service`.
2. That service runs `bootstrap-lab.sh`.
3. Script checks libvirt network (`default`), makes sure it is up.
4. Script starts VM(s), currently `eve-ng`.

So your lab can recover automatically after reboot.

## 6) Useful check commands

```bash
systemctl status lab-bootstrap.service --no-pager
virsh -c qemu:///system list --all
virsh -c qemu:///system net-list --all
sudo ufw status verbose
sudo aa-status | sed -n '1,80p'
```

