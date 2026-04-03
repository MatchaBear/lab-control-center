# Target Host Prerequisites (Idiot-Proof, Step-by-Step)

Contributors: bermekbukair, Codex

Last updated: 2026-03-27

Goal:
- Prepare another Linux machine so your lab bundle can be imported and run reliably.
- This guide covers only prerequisites + matching network/config structure.

Assumption:
- Target host OS is Ubuntu 24.04 (or close Debian/Ubuntu variant).

---

## Step 0: What you need before starting

- A target host with:
  - CPU virtualization support (Intel VT-x or AMD-V)
  - At least 32 GB RAM recommended for medium lab
  - Enough free disk space
- Your removable SSD with the lab bundle
- A user account with sudo privileges

---

## Step 1: Enable virtualization in BIOS/UEFI

1. Reboot target host into BIOS/UEFI setup.
2. Enable:
   - Intel: `VT-x` (and VT-d optional)
   - AMD: `SVM/AMD-V` (and IOMMU optional)
3. Save and boot into Linux.

Verify in Linux:
```bash
egrep -c '(vmx|svm)' /proc/cpuinfo
```

Expected:
- Number greater than `0`.

If result is `0`, virtualization is disabled in BIOS/UEFI.

---

## Step 2: Install KVM + libvirt stack

Run:
```bash
sudo apt update
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients virt-manager bridge-utils cpu-checker
```

Check KVM availability:
```bash
kvm-ok
```

Expected:
- `KVM acceleration can be used`

---

## Step 3: Start and enable libvirt services

Run:
```bash
sudo systemctl enable --now libvirtd
sudo systemctl status --no-pager libvirtd
```

Expected:
- Service is `active (running)`.

---

## Step 4: Add your user to required groups

Run:
```bash
sudo usermod -aG libvirt,kvm $USER
```

Then:
1. Log out completely.
2. Log back in.

Verify groups:
```bash
id
```

Expected:
- Your user includes `libvirt` and `kvm`.

---

## Step 5: Validate virsh access (system libvirt)

Run:
```bash
virsh -c qemu:///system list --all
```

Expected:
- Command works (may show no VMs yet).

If permission denied:
- Re-login again after group change.
- Re-check `id`.

---

## Step 6: Prepare storage path and permissions

We will use default storage location for best compatibility.

Run:
```bash
sudo mkdir -p /var/lib/libvirt/images
sudo ls -ld /var/lib/libvirt/images
```

Expected:
- Directory exists.

Important:
- When copying qcow2 files later, set owner to `libvirt-qemu:kvm` and mode `600`.

---

## Step 7: Create matching libvirt network structure

If your source used `default` network (most likely), create/ensure it exists.

Check:
```bash
virsh -c qemu:///system net-list --all
```

If `default` is missing, define and start it:
```bash
virsh -c qemu:///system net-define /media/$USER/<SSD_LABEL>/lab-bundle/networks/default.xml
virsh -c qemu:///system net-autostart default
virsh -c qemu:///system net-start default
```

Verify:
```bash
virsh -c qemu:///system net-list --all
virsh -c qemu:///system net-dumpxml default | sed -n '1,80p'
```

Expected:
- `default` is `active`, `autostart yes`.
- NAT network with expected subnet (for your case: often `192.168.122.0/24`).

---

## Step 8: Match machine-level config assumptions

To avoid import surprises:
- Keep same VM names as source (e.g., `eve-ng`).
- Keep same network names (e.g., `default`).
- Keep similar QEMU/libvirt versions when possible.
- Keep enough free RAM before starting VMs.

Quick resource check:
```bash
nproc
free -h
df -h /var/lib/libvirt/images
```

---

## Step 9: Optional but strongly recommended hardening baseline

Run:
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw --force enable
sudo ufw status verbose
```

Keep remote access rules explicit (only open what you need).

---

## Step 10: Final prerequisite validation checklist

All items must be true before importing VMs:

1. `egrep -c '(vmx|svm)' /proc/cpuinfo` > 0
2. `kvm-ok` says acceleration usable
3. `libvirtd` active and enabled
4. User is in `libvirt` and `kvm` groups
5. `virsh -c qemu:///system list --all` works
6. `/var/lib/libvirt/images` exists
7. `default` network exists, active, autostart enabled
8. Enough CPU/RAM/disk available

If all pass, target host is ready for lab import and bootstrap setup.

---

## Quick copy-paste block (minimum setup)

```bash
sudo apt update
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients virt-manager bridge-utils cpu-checker
sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt,kvm $USER
echo "Now logout/login once, then run:"
echo "virsh -c qemu:///system list --all"
```

