# Target Host Import Guide (Idiot-Proof, After Prerequisites)

Contributors: bermekbukair, Codex

Last updated: 2026-03-27

Use this only after:
- [TARGET_HOST_PREREQ_IDIOTPROOF.md](./TARGET_HOST_PREREQ_IDIOTPROOF.md)
- [LAB_PORTABILITY_PLAYBOOK.md](./LAB_PORTABILITY_PLAYBOOK.md)

Goal:
- Import your lab bundle from removable SSD into target host.
- Start VMs reliably.
- Re-enable reboot auto-start bootstrap.

---

## Step 0: Confirm prerequisites are complete

Quick checks:
```bash
virsh -c qemu:///system list --all
virsh -c qemu:///system net-list --all
systemctl is-active libvirtd
```

Expected:
- Commands run successfully.
- `libvirtd` is active.

---

## Step 1: Mount your removable SSD

Plug in SSD and verify mount path:
```bash
lsblk -o NAME,RM,HOTPLUG,TYPE,SIZE,MOUNTPOINTS
```

Assume mount path is:
- `/media/$USER/<SSD_LABEL>`

Your bundle should exist at:
- `/media/$USER/<SSD_LABEL>/lab-bundle`

Check:
```bash
ls -la /media/$USER/<SSD_LABEL>/lab-bundle
```

---

## Step 2: Import libvirt network first

If `default` network doesn’t exist, import it:
```bash
virsh -c qemu:///system net-define /media/$USER/<SSD_LABEL>/lab-bundle/networks/default.xml
virsh -c qemu:///system net-autostart default
virsh -c qemu:///system net-start default
```

Verify:
```bash
virsh -c qemu:///system net-list --all
```

---

## Step 3: Copy VM disk images to local storage (recommended)

Create destination:
```bash
sudo mkdir -p /var/lib/libvirt/images
```

Copy all qcow2:
```bash
sudo cp -av /media/$USER/<SSD_LABEL>/lab-bundle/images/*.qcow2 /var/lib/libvirt/images/
```

Fix ownership and permissions:
```bash
sudo chown libvirt-qemu:kvm /var/lib/libvirt/images/*.qcow2
sudo chmod 600 /var/lib/libvirt/images/*.qcow2
```

Why local copy:
- Better performance
- Less risk if USB disconnects

---

## Step 4: Import VM definitions (XML)

For each VM XML in bundle:
```bash
mkdir -p /tmp/lab-import
cp -av /media/$USER/<SSD_LABEL>/lab-bundle/xml/*.xml /tmp/lab-import/
```

Before define:
- Open each XML and verify disk path points to actual location (`/var/lib/libvirt/images/...`).

Define:
```bash
for f in /tmp/lab-import/*.xml; do
  virsh -c qemu:///system define "$f"
done
```

Verify:
```bash
virsh -c qemu:///system list --all
```

---

## Step 5: Enable VM autostart

Example:
```bash
virsh -c qemu:///system autostart eve-ng
```

For all imported VMs:
```bash
for vm in $(virsh -c qemu:///system list --all --name | sed '/^$/d'); do
  virsh -c qemu:///system autostart "$vm"
done
```

---

## Step 6: Restore bootstrap automation on target host

Copy bootstrap folder:
```bash
mkdir -p ~/lab-bootstrap
cp -av /media/$USER/<SSD_LABEL>/lab-bundle/bootstrap/* ~/lab-bootstrap/
```

Install service:
```bash
sudo ~/lab-bootstrap/install-systemd-bootstrap.sh
```

Check:
```bash
systemctl status --no-pager lab-bootstrap.service
```

---

## Step 7: Edit startup order for this host capacity

Edit:
```bash
sed -n '1,200p' ~/lab-bootstrap/lab.env
```

Set your order, for example:
```bash
LAB_VMS="dns-adcs01 logsnmp01 eve-ng"
START_DELAY_SECONDS=45
```

Apply:
```bash
sudo systemctl restart lab-bootstrap.service
```

---

## Step 8: Start/verify lab

Start one VM first:
```bash
virsh -c qemu:///system start eve-ng
```

Then verify:
```bash
virsh -c qemu:///system list --all
virsh -c qemu:///system dominfo eve-ng
```

Optional network check:
```bash
virsh -c qemu:///system domifaddr eve-ng
```

---

## Step 9: Troubleshooting (most common)

1. `permission denied` on disk:
```bash
sudo chown libvirt-qemu:kvm /var/lib/libvirt/images/<disk>.qcow2
sudo chmod 600 /var/lib/libvirt/images/<disk>.qcow2
```

2. `network 'default' not found`:
```bash
virsh -c qemu:///system net-define /media/$USER/<SSD_LABEL>/lab-bundle/networks/default.xml
virsh -c qemu:///system net-start default
virsh -c qemu:///system net-autostart default
```

3. VM definition exists but won’t boot:
- Re-check XML disk source path.
- Re-check available RAM/CPU.

4. Very slow performance:
- Stop running too many VMs.
- Reduce vCPU/RAM of heavy appliances.
- Move from USB direct-run to local NVMe storage.

---

## Step 10: What this guide is for (use cases)

Use this guide when:
- You bought a new host and want to move lab quickly.
- Your main host fails and you need recovery on backup host.
- You rotate between multiple lab hosts (office/home).
- You want repeatable migration without remembering commands.

Do not use this guide for:
- Fresh base hardening (use the prerequisite guide first).
- Vendor license troubleshooting (handled per vendor).

