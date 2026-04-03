# CPPM Host Port Map 2026-04-03

Last updated: 2026-04-03
Contributors: bermekbukair, Codex

## Goal

Record the current host-side port forwards for the two ClearPass lab VMs so another agent can recover the access path quickly without re-discovering live listeners, firewall rules, service names, or selective firewall exceptions.

## Host context

Ubuntu host:
- Hostname: `zbuntu-g3`
- LAN IP: `192.168.68.127`

Primary client currently allowed for selective SSH forwards:
- Mac IP: `192.168.68.112`

## ClearPass VM mapping

`cppm611-clabv`
- Management IP: `192.168.123.41`
- GUI: `443/tcp`
- SSH: `22/tcp`

`cppm612-clabv`
- Management IP: `192.168.123.42`
- GUI: `443/tcp`
- SSH: `22/tcp`

## Active host port forwards

GUI forwards:
- `192.168.68.127:8441` -> `192.168.123.41:443` (`cppm611-clabv` GUI)
- `192.168.68.127:8442` -> `192.168.123.42:443` (`cppm612-clabv` GUI)

SSH forwards:
- `192.168.68.127:2223` -> `192.168.123.41:22` (`cppm611-clabv` SSH)
- `192.168.68.127:2224` -> `192.168.123.42:22` (`cppm612-clabv` SSH)

## Reserved or already-used host ports

Do not overlap these without deliberately replacing them:
- `22` -> Ubuntu host SSH
- `2222` -> EVE-NG SSH forward
- `2223` -> `cppm611-clabv` SSH forward
- `2224` -> `cppm612-clabv` SSH forward
- `8222` -> CML SSH forward
- `8441` -> `cppm611-clabv` GUI forward
- `8442` -> `cppm612-clabv` GUI forward
- `8443` -> CML HTTPS forward
- `9090` -> CML Cockpit forward

## Persistent systemd services

GUI:
- `cppm611-gui-8441.service`
- `cppm612-gui-8442.service`

SSH:
- `cppm611-ssh-2223.service`
- `cppm612-ssh-2224.service`

Firewall persistence:
- `lab-fw-cppm-ssh.service`
- helper script: `/usr/local/sbin/lab-fw-cppm-ssh.sh`

## Firewall behavior

Important detail:
- This host has active `ufw` and `iptables-nft` chains, but the `ufw` command itself is not available in the shell.
- Because of that, the SSH allow rules for `2223` and `2224` are persisted by a dedicated boot-time script instead of relying on `ufw allow`.

Current intended SSH exposure:
- allow `192.168.68.112` -> `2223/tcp`
- allow `192.168.68.112` -> `2224/tcp`

Current helper logic:
- checks whether the rule already exists in `ufw-user-input`
- inserts the allow rule only if missing
- re-runs automatically at boot through `lab-fw-cppm-ssh.service`

## Quick verification commands

Check listeners:

```bash
ss -ltn | egrep ':2222|:2223|:2224|:8222|:8441|:8442|:8443|:9090'
```

Check systemd services:

```bash
systemctl status --no-pager \
  cppm611-gui-8441.service \
  cppm612-gui-8442.service \
  cppm611-ssh-2223.service \
  cppm612-ssh-2224.service \
  lab-fw-cppm-ssh.service
```

Check firewall chain:

```bash
iptables -S ufw-user-input
```

## Client usage examples

From the Mac:

GUI:
- `https://192.168.68.127:8441`
- `https://192.168.68.127:8442`

SSH:

```bash
ssh -p 2223 <cppm611_user>@192.168.68.127
ssh -p 2224 <cppm612_user>@192.168.68.127
```

## Important notes for future agents

- `cppm611-clabv` originally had management and data NIC wiring reversed at the libvirt level.
- That was corrected so the ClearPass internal MAC-to-port view now matches the libvirt network attachment.
- `cppm611-clabv` management side now reaches `192.168.123.1` correctly.
- The ClearPass rescue GRUB entry was observed broken and should not be treated as the normal boot path.
- The normal operational entry is the non-rescue ClearPass image.
- GUI forwarding was made persistent first, then SSH forwarding, then selective firewall persistence was added for the SSH ports.

## Related files

- [CPPM611_DUAL_NIC_NETWORKS_2026.md](/home/hadescloak/Desktop/Projects/lab-control-center/CPPM611_DUAL_NIC_NETWORKS_2026.md)
- [SSH_FORWARD_EVE_FIX.md](/home/hadescloak/Desktop/Projects/lab-control-center/SSH_FORWARD_EVE_FIX.md)
- [cppm611_update_connectivity_report_2026-04-03.md](/home/hadescloak/Desktop/Projects/lab-control-center/cppm611_update_connectivity_report_2026-04-03.md)
