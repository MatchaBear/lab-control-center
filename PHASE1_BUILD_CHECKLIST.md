# Phase 1 Build Checklist (Do This Next)

Contributors: bermekbukair, Codex

Last updated: 2026-03-27

Use this after reading:
- [PHASE1_TOPOLOGY.md](./PHASE1_TOPOLOGY.md)

Goal:
- Create `dns-adcs01` and `logsnmp01`
- Keep `eve-ng` running as core network lab node
- Update bootstrap order for reboot-safe startup

---

## 0) Prepare ISO files

Put installation ISOs somewhere stable, example:
- `/var/lib/libvirt/boot/WinServer.iso`
- `/var/lib/libvirt/boot/ubuntu-24.04-live-server-amd64.iso`

Create folder if needed:
```bash
sudo mkdir -p /var/lib/libvirt/boot
```

---

## 1) Create `logsnmp01` (Ubuntu server)

```bash
sudo virt-install \
  --name logsnmp01 \
  --ram 4096 \
  --vcpus 2 \
  --cpu host \
  --os-variant ubuntu24.04 \
  --disk path=/var/lib/libvirt/images/logsnmp01.qcow2,size=60,format=qcow2,bus=virtio \
  --network network=default,model=virtio \
  --graphics vnc \
  --cdrom /var/lib/libvirt/boot/ubuntu-24.04-live-server-amd64.iso \
  --boot uefi
```

During OS install, set static IP:
- IP: `192.168.122.20/24`
- GW: `192.168.122.1`
- DNS: `192.168.122.10` (temporary use `192.168.122.1` until AD DNS is ready)

---

## 2) Create `dns-adcs01` (Windows Server)

```bash
sudo virt-install \
  --name dns-adcs01 \
  --ram 6144 \
  --vcpus 2 \
  --cpu host \
  --os-variant win2k22 \
  --disk path=/var/lib/libvirt/images/dns-adcs01.qcow2,size=80,format=qcow2,bus=sata \
  --network network=default,model=e1000e \
  --graphics vnc \
  --cdrom /var/lib/libvirt/boot/WinServer.iso \
  --boot uefi
```

Inside Windows:
- Static IP: `192.168.122.10/24`
- GW: `192.168.122.1`
- Preferred DNS: `127.0.0.1`

Then install roles:
- AD DS
- DNS
- ADCS (issuing CA for phase 1)

---

## 3) Update lab startup order

Edit:
```bash
sed -n '1,200p' $REPO_DIR/lab.env
```

Set:
```bash
LAB_VMS="dns-adcs01 logsnmp01 eve-ng"
START_DELAY_SECONDS=45
```

Apply:
```bash
sudo systemctl restart lab-bootstrap.service
systemctl status --no-pager lab-bootstrap.service
```

---

## 4) Validate VM/network state

```bash
virsh -c qemu:///system list --all
virsh -c qemu:///system net-list --all
$REPO_DIR/labctl.sh status
```

Expected:
- `dns-adcs01`, `logsnmp01`, `eve-ng` exist
- `default` network active
- bootstrap service healthy

---

## 5) Configure minimal services on `logsnmp01`

After Ubuntu install:
```bash
sudo apt update
sudo apt install -y rsyslog snmp snmpd snmptrapd
sudo systemctl enable --now rsyslog snmpd snmptrapd
```

This gives:
- Syslog receiver baseline
- SNMP daemon/trap receiver baseline

---

## 6) First integration tests

1. From host, test VM reachability:
```bash
ping -c 2 192.168.122.10
ping -c 2 192.168.122.20
```

2. Verify DNS from `logsnmp01` after AD DNS is up.
3. Send one test syslog from a node in EVE to `192.168.122.20`.
4. Send one SNMP trap to `192.168.122.20`.

---

## 7) If host gets too slow

Reduce `eve-ng` resources:
- vCPU from 8 -> 4 or 6
- RAM from 24 GiB -> 12-16 GiB

Do this before adding more vendor appliances.

---

## 8) Notes

- Keep VM names exactly as documented (important for automation).
- Keep using `default` network for phase 1 to avoid over-complicating.
- Add more vendors only after baseline services are stable.

