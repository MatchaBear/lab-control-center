# ISO & Image Acquisition Guide (2026, Free-First, Legal-Only)

Contributors: bermekbukair, Codex

Last updated: 2026-03-27

## Read this first

This guide prioritizes:
1. Free sources
2. Legal/licensed use
3. Lab practicality

Important:
- I will not help with pirated or unauthorized "shared image packs".
- Many vendor network images are licensed and cannot be legally redistributed in community drives/forums.

---

## 1) Free + legal baseline images (start here)

## A. Ubuntu Server ISO (free)

Use for:
- Utility VM, syslog/SNMP VM, automation/jump hosts

Official:
- https://ubuntu.com/download/server
- Verify checksum from:
  - https://releases.ubuntu.com/24.04/

## B. Windows Server Evaluation ISO (free evaluation)

Use for:
- AD DS / DNS / ADCS lab VMs

Official:
- https://www.microsoft.com/evalcenter/

Notes:
- Evaluation period is time-limited.
- Good for lab/testing, not production.

## C. CML-Free (free, limited node count)

Use for:
- Legal Cisco image access within CML-Free constraints

Official:
- https://developer.cisco.com/docs/modeling-labs/2-9/cml-free/

Critical license note:
- Cisco images from CML are licensed for CML use only (not for arbitrary external use).

---

## 2) Vendor images: legitimate free trial paths

These are usually "free trial", not permanently free.

## A. Palo Alto VM-Series trial
- https://www.paloaltonetworks.com/vm-series-trial

## B. Fortinet FortiGate-VM eval path
- https://www.fortinet.com/support/product-downloads

## C. Check Point / CloudGuard trial/lab portals
- https://www.checkpoint.com/
- CheckMates community often points to current lab/trial activations:
  - https://community.checkpoint.com/

## D. F5 BIG-IP VE trial
- https://www.f5.com/trials/big-ip-virtual-edition

## E. Juniper vSRX / vMX evaluation routes
- https://www.juniper.net/us/en/dm/free-vsrx-trial.html

## F. Arista lab/eval routes
- https://www.arista.com/en/support/software-download

## G. Cisco ISE evaluation (for TACACS TLS test windows)
- Access usually via Cisco software download/eval entitlement portal.
- Start from:
  - https://software.cisco.com/
  - https://www.cisco.com/c/en/us/products/security/identity-services-engine/index.html

---

## 3) Community sources: what is safe vs unsafe

Safe:
- Official vendor communities for setup guidance, trial activation, and compatibility notes.
- Documentation forums (no copyrighted image redistribution).

Unsafe / avoid:
- Random Google Drive/Mega/Telegram "image packs".
- Torrent/shared repositories with proprietary appliance images.
- "Cracked license" bundles.

Why avoid:
- Legal risk
- Malware risk
- Unknown tampering risk
- Unreliable version provenance

---

## 4) How to acquire files cleanly (procedure)

1. Download from official source URL.
2. Save to staging folder:
```bash
mkdir -p ~/Downloads/lab-images
```
3. Verify checksum/signature when available.
4. Move to libvirt boot storage:
```bash
sudo mkdir -p /var/lib/libvirt/boot
sudo cp -av ~/Downloads/lab-images/* /var/lib/libvirt/boot/
sudo ls -lh /var/lib/libvirt/boot
```
5. Record provenance in manifest (URL, version, checksum, date).

---

## 5) Recommended low-cost Phase 1 acquisition set

Get now:
1. Ubuntu Server ISO (free)
2. Windows Server Evaluation ISO (free eval)

Then optional trials (when you are ready to test specific features):
3. One firewall vendor trial image
4. Cisco ISE eval image (for TACACS over TLS window)

This minimizes storage and avoids downloading huge image sets prematurely.

---

## 6) If you specifically need "free forever" lab network NOS

Consider free/open options for structural testing:
- VyOS
- FRRouting-based routers
- Open vSwitch/Linux bridges
- MikroTik CHR free-tier constraints (check current license terms)

These can help test L2/L3 behavior while you reserve vendor trials for targeted test windows.

---

## 7) Where to store inventory metadata

Create:
- `$REPO_DIR/image-manifest.csv`

Columns:
- vendor, product, version, filename, sha256, source_url, license_type, expiry_date, notes

---

## 8) References (latest checked)

- Ubuntu Server downloads:
  - https://ubuntu.com/download/server
- Microsoft Evaluation Center:
  - https://www.microsoft.com/evalcenter/
- CML Free:
  - https://developer.cisco.com/docs/modeling-labs/2-9/cml-free/
- Palo Alto VM-Series trial:
  - https://www.paloaltonetworks.com/vm-series-trial
- Fortinet downloads:
  - https://www.fortinet.com/support/product-downloads
- Check Point community:
  - https://community.checkpoint.com/
- F5 VE trial:
  - https://www.f5.com/trials/big-ip-virtual-edition
- Juniper vSRX trial:
  - https://www.juniper.net/us/en/dm/free-vsrx-trial.html

