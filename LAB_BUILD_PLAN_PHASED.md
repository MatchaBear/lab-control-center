# Phased Lab Build Plan (Current Host)

Contributors: bermekbukair, Codex

Last updated: 2026-03-27

## Reality Check (Important)

Your host is:
- 8 CPU threads
- 31 GiB RAM
- One heavy VM already running (`eve-ng`, 8 vCPU / 24 GiB RAM)

Your requested full stack (Checkpoint, Palo Alto, FortiGate, F5, Cisco IOS-XE x2, Aruba ClearPass, Cisco ISE, Windows, macOS, ADCS 2-tier, DNS/SNMP/Syslog, plus Juniper/Arista/HPE) is **not feasible simultaneously** on this host.

Practical design:
- Keep this machine as a **core control-plane lab host**.
- Run only a **subset concurrently**.
- Burst vendor-heavy network simulation to a second node/cloud later if needed.

## Target Architecture (What to run locally first)

Phase 1 (now, local and feasible):
- EVE-NG (network control)
- AD/DNS (Windows Server VM)
- ADCS Issuing CA (same Windows VM initially)
- Syslog + SNMP manager (Linux VM)
- 1-2 virtual firewalls only

Phase 2 (after validation):
- Split ADCS into 2-tier (offline root + issuing)
- Add ISE or ClearPass (choose one first)
- Add second firewall vendor

Phase 3 (scale-out):
- Add IOS-XE/Juniper/Arista/HPE by moving heavy nodes to external compute
- Keep this host as orchestrator/jump/syslog/PKI anchor

## What You Already Have

- Reboot-safe bootstrap service:
  - `/etc/systemd/system/lab-bootstrap.service`
- Bootstrap script:
  - `$REPO_DIR/bootstrap-lab.sh`
- Bootstrap env:
  - `$REPO_DIR/lab.env`
- Current startup list from `lab.env`:
  - `LAB_VMS="eve-ng"`

## How To Control Boot Startup Order

Edit:
- `$REPO_DIR/lab.env`

Example:
```bash
LAB_VMS="dns-adcs01 logsnmp01 eve-ng fw-pa01"
START_DELAY_SECONDS=45
```

Apply:
```bash
sudo systemctl restart lab-bootstrap.service
systemctl status --no-pager lab-bootstrap.service
```

## Immediate Next Build Steps

1. Right-size `eve-ng` first (recommended):
- Reduce to ~4-6 vCPU and 12-16 GiB RAM so host has headroom.

2. Create two lightweight infra VMs:
- `dns-adcs01` (Windows Server)
- `logsnmp01` (Ubuntu/Debian)

3. Wire core services:
- DNS zones + forwarders
- Syslog receiver (rsyslog/syslog-ng)
- SNMP poll + trap receiver (LibreNMS/Observium/Telegraf+snmptrapd)

4. Add one firewall vendor image and validate:
- Mgmt reachability
- Syslog export
- SNMP polling
- NTP + DNS + AAA integration

5. Only then expand to second/third vendor appliances.

## Cost-Efficient Notes

- Biggest savings: avoid running all vendors at once locally.
- EVE-NG Community + KVM is fine for initial path.
- macOS virtualization/licensing is constrained; prefer physical test endpoint or cloud macOS service if required.

