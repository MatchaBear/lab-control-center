# Lab Portability Playbook (Idiot-Proof)

Contributors: bermekbukair, Codex

Last updated: 2026-03-27

## TL;DR

Yes, you can host VM disks on a removable SSD (like SanDisk) and move the lab to another machine.

Best practice:
- Keep **configs/scripts** in your home folder (``).
- Keep **VM disks** on the removable SSD.
- Export each VM XML + disk image.
- Re-import on new host with the same VM names/network plan.

This is "portable", but not true "zero-click plug-and-play" unless both hosts are prepared with the same virtualization stack.

---

## 1) Can removable SSD host VMs?

Yes, but use these rules:
- Use USB 3.2/USB-C fast port only.
- Filesystem: `ext4` preferred on Linux host.
- Avoid exFAT for active VM disks (less robust for VM workloads).
- Always cleanly unmount/power-off before unplug.
- Keep SSD cooled; sustained VM I/O can throttle cheap enclosures.

Good:
- Running lab images
- Carrying backup/bundle between hosts

Not ideal:
- High IOPS multi-VM stress test with many appliances at once

---

## 2) What is portable vs not portable

Portable:
- `.qcow2` VM disk files
- VM XML definitions (with path edits)
- Your bootstrap scripts/docs in ``
- Most Linux/Windows generic VMs

Less portable / needs care:
- Vendor appliances with licensing/hardware fingerprint checks
- Different CPU vendors/features (Intel vs AMD passthrough differences)
- OVMF/UEFI firmware path mismatches between hosts
- Bridge/network names that differ per host

---

## 3) Standard bundle format (recommended)

Create one folder on SSD:

`/media/<user>/<SSD_LABEL>/lab-bundle/`

Inside:
- `images/` (all `.qcow2`)
- `xml/` (VM XML exports)
- `networks/` (libvirt network XML)
- `bootstrap/` (copy of ``)
- `manifest.txt` (what each VM is for, RAM/vCPU, boot order)

---

## 4) Source host: export checklist

1. Stop VMs cleanly:
```bash
virsh -c qemu:///system list --all
virsh -c qemu:///system shutdown eve-ng
```

2. Export VM XML:
```bash
mkdir -p /media/$USER/<SSD_LABEL>/lab-bundle/xml
virsh -c qemu:///system dumpxml eve-ng > /media/$USER/<SSD_LABEL>/lab-bundle/xml/eve-ng.xml
```

3. Copy VM disk(s):
```bash
mkdir -p /media/$USER/<SSD_LABEL>/lab-bundle/images
cp -av /var/lib/libvirt/images/eve-ng.qcow2 /media/$USER/<SSD_LABEL>/lab-bundle/images/
```

4. Export libvirt network XML:
```bash
mkdir -p /media/$USER/<SSD_LABEL>/lab-bundle/networks
virsh -c qemu:///system net-dumpxml default > /media/$USER/<SSD_LABEL>/lab-bundle/networks/default.xml
```

5. Copy bootstrap folder:
```bash
mkdir -p /media/$USER/<SSD_LABEL>/lab-bundle/bootstrap
cp -av $REPO_DIR/* /media/$USER/<SSD_LABEL>/lab-bundle/bootstrap/
```

---

## 5) New host prerequisites (must install first)

On target host (Ubuntu/Debian style):
```bash
sudo apt update
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients virt-manager bridge-utils
sudo systemctl enable --now libvirtd
```

User permissions:
```bash
sudo usermod -aG libvirt,kvm $USER
```
Then log out and log back in once.

Also ensure:
- CPU virtualization enabled in BIOS/UEFI (VT-x/AMD-V)
- Enough RAM and disk
- Same/compatible QEMU/libvirt major versions preferred

---

## 6) New host import (plug-and-play style)

1. Mount SSD and create destination:
```bash
sudo mkdir -p /var/lib/libvirt/images
```

2. Copy disk to local SSD/NVMe (recommended for performance):
```bash
sudo cp -av /media/$USER/<SSD_LABEL>/lab-bundle/images/eve-ng.qcow2 /var/lib/libvirt/images/
sudo chown libvirt-qemu:kvm /var/lib/libvirt/images/eve-ng.qcow2
sudo chmod 600 /var/lib/libvirt/images/eve-ng.qcow2
```

3. Edit XML path if needed, then define VM:
```bash
cp /media/$USER/<SSD_LABEL>/lab-bundle/xml/eve-ng.xml /tmp/eve-ng.xml
# edit /tmp/eve-ng.xml if disk path changed
virsh -c qemu:///system define /tmp/eve-ng.xml
virsh -c qemu:///system autostart eve-ng
```

4. Define/start network:
```bash
virsh -c qemu:///system net-define /media/$USER/<SSD_LABEL>/lab-bundle/networks/default.xml
virsh -c qemu:///system net-autostart default
virsh -c qemu:///system net-start default
```

5. Install bootstrap automation:
```bash
mkdir -p ~/lab-bootstrap
cp -av /media/$USER/<SSD_LABEL>/lab-bundle/bootstrap/* ~/lab-bootstrap/
sudo ~/lab-bootstrap/install-systemd-bootstrap.sh
```

6. Validate:
```bash
virsh -c qemu:///system list --all
systemctl status --no-pager lab-bootstrap.service
```

---

## 7) Can I run directly from removable SSD without copying local?

Yes, but with caveats:
- Works, but slower and riskier if cable disconnects.
- VM corruption risk is higher on accidental unplug.

If you still want direct-run:
- Keep stable mount path (same label each time).
- Update VM XML disk source path to mounted SSD path.
- Do not unplug while VM is running.

Recommended compromise:
- Carry bundle on SSD, copy active VMs locally on target host, run locally.

---

## 8) Compatibility guardrails

To maximize success between hosts:
- Keep VM names consistent.
- Keep network names consistent (`default` or your custom names).
- Avoid CPU-passthrough lock-in when portability is priority.
- Keep a `manifest.txt` with:
  - VM name
  - vCPU/RAM
  - disk filename
  - management IP
  - boot order

---

## 9) Recovery if import fails

Common issues:
- "permission denied" on disk -> fix owner/group/mode.
- "network not found" -> define/start network XML first.
- VM won’t boot after move -> check disk path in VM XML.
- Poor performance -> move qcow2 from USB SSD to internal NVMe.

Useful checks:
```bash
virsh -c qemu:///system dominfo eve-ng
virsh -c qemu:///system domblklist eve-ng --details
virsh -c qemu:///system net-list --all
journalctl -u libvirtd -n 120 --no-pager
```

---

## 10) Your current environment references

- Bootstrap scripts:
  - `$REPO_DIR/bootstrap-lab.sh`
  - `$REPO_DIR/install-systemd-bootstrap.sh`
- Current systemd unit:
  - `/etc/systemd/system/lab-bootstrap.service`
- Current VM disk:
  - `/var/lib/libvirt/images/eve-ng.qcow2`
- Current VM XML:
  - `/etc/libvirt/qemu/eve-ng.xml`

