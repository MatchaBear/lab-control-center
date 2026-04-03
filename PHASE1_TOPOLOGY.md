# Phase 1 Topology (Implement Now)

Contributors: bermekbukair, Codex

Last updated: 2026-03-27

## Scope

Build a stable core lab on this host first:
- `dns-adcs01` (Windows Server: AD DS + DNS + ADCS issuing role)
- `logsnmp01` (Ubuntu: Syslog + SNMP manager/trap receiver)
- `eve-ng` (network appliance playground/orchestration)

Keep this phase small and resilient. Add heavy vendors later.

## Host Limits (Why this shape)

- Host CPU threads: `8`
- Host RAM: `31 GiB`
- Current heavy VM: `eve-ng` uses `8 vCPU / 24 GiB`

Recommendation:
- Resize `eve-ng` to `4-6 vCPU` and `12-16 GiB` for headroom.

## Management Network

- libvirt network: `default`
- mode: NAT (`virbr0`)
- subnet: `192.168.122.0/24`
- gateway: `192.168.122.1`

## Phase 1 VM Plan

1. `dns-adcs01`
- OS: Windows Server 2022/2025
- vCPU: 2
- RAM: 6 GiB
- Disk: 80 GiB
- IP: `192.168.122.10/24`
- DNS: `127.0.0.1` and `192.168.122.10`
- Role: AD DS + DNS + ADCS issuing CA

2. `logsnmp01`
- OS: Ubuntu Server 24.04
- vCPU: 2
- RAM: 4 GiB
- Disk: 60 GiB
- IP: `192.168.122.20/24`
- DNS: `192.168.122.10`
- Role: rsyslog/syslog-ng + snmptrapd + poller (LibreNMS/Telegraf-based)

3. `eve-ng`
- IP: `192.168.122.30/24` (or DHCP reservation)
- role: vendor virtual appliances and routing/security test topologies

## Boot Order

Use this order in `lab.env`:

```bash
LAB_VMS="dns-adcs01 logsnmp01 eve-ng"
START_DELAY_SECONDS=45
```

Why:
- Identity/DNS first
- Logging/monitoring second
- appliance fabric last

## Ports To Access From Host

- DNS server mgmt (RDP): `3389/tcp` -> `dns-adcs01`
- Linux admin (SSH): `22/tcp` -> `logsnmp01`
- EVE web UI: typically `80/443` on `eve-ng`

Keep UFW inbound default deny on host; use local/libvirt NAT paths only unless explicit exposure is needed.

## Acceptance Criteria (Phase 1 done)

1. `virsh list --all` shows all 3 VMs defined.
2. `lab-bootstrap.service` starts them in configured order.
3. `dns-adcs01` resolves names for `logsnmp01` and EVE nodes.
4. `logsnmp01` receives syslog and SNMP traps from at least one test node.
5. Reboot host once and verify full recovery path.

