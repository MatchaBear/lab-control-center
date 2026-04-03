# ClearPass VM TCP Fingerprinting and Mirror Runbook

Contributors: bermekbukair, Codex

Last updated: 2026-04-03

## Purpose

This runbook documents the current lab approach for testing ClearPass TCP fingerprinting on the two ClearPass virtual appliances:

- `cppm611-clabv`
- `cppm612-clabv`

The goal is to expose a third NIC to each VM and feed mirrored traffic into that NIC so ClearPass can potentially use it as a SPAN-style interface for passive TCP fingerprinting.

## Current VM NIC Layout

### cppm611-clabv

- management NIC: `vnet3` on `nac-mgmt` (`192.168.123.0/24`)
- data NIC: `vnet4` on `nac-data` (`192.168.124.0/24`)
- third NIC: `vnet6` on `default` (`192.168.122.0/24`)

### cppm612-clabv

- management NIC: `vnet1` on `nac-mgmt` (`192.168.123.0/24`)
- data NIC: `vnet2` on `nac-data` (`192.168.124.0/24`)
- third NIC: `vnet5` on `default` (`192.168.122.0/24`)

## Important Design Notes

- The libvirt `default` network is `192.168.122.0/24`.
- The third NIC is attached at layer 2 to the `default` bridge.
- For SPAN-style use, the third NIC should remain without an IP address inside ClearPass.
- Simply attaching a third NIC does not create real fingerprinting visibility by itself.
- The third NIC must receive mirrored traffic to be useful for passive TCP fingerprinting.

## Why Mirroring Is Needed

TCP fingerprinting is passive. ClearPass does not create special probe traffic for it.

It learns from TCP handshakes and related headers that devices naturally generate. That means:

- some endpoint must initiate traffic
- ClearPass must be able to see that traffic
- a dedicated mirror or SPAN feed is needed when ClearPass is not inline

Without a mirror feed, ClearPass mostly sees traffic destined to ClearPass itself, not general endpoint traffic.

## Mirror Scope and Limitation

This lab can mirror:

- `192.168.122.0/24` via `virbr0`
- `192.168.123.0/24` via `virbr123`
- `192.168.124.0/24` via `virbr124`

This host cannot passively see all traffic across the house subnet `192.168.68.0/24`, because it is not the upstream switch or router for the whole LAN.

The runbook also mirrors `wlp2s0`, but that only gives:

- traffic to or from this host
- traffic routed through this host
- host-visible wireless traffic seen by this machine

It does not provide full-house passive capture.

## Mirror Control Script

Script path:

- [lab-net-mirror.sh](./lab-net-mirror.sh)

The script uses `tc` mirror actions to copy traffic from:

- `virbr0`
- `virbr123`
- `virbr124`
- `wlp2s0`

into both ClearPass third-NIC tap devices:

- `vnet5`
- `vnet6`

### Enable mirroring

```bash
sudo $REPO_DIR/lab-net-mirror.sh enable
```

### Check status

```bash
sudo $REPO_DIR/lab-net-mirror.sh status
```

### Disable mirroring

```bash
sudo $REPO_DIR/lab-net-mirror.sh disable
```

## Expected Outcome in ClearPass

After the third NIC is present and mirroring is enabled:

1. Open ClearPass:
   `Administration > Server Manager > Server Configuration > System`

2. Check the `Span Port` field.

3. If the third interface is recognized, it may appear as a selectable span port instead of only `None`.

4. If it does not appear immediately:
   - reboot the ClearPass VM
   - check again after boot completes

## Verification on the Host

### Verify third NICs are attached

```bash
virsh -c qemu:///system domiflist cppm611-clabv
virsh -c qemu:///system domiflist cppm612-clabv
```

Expected third interfaces:

- `cppm611-clabv`: `vnet6`
- `cppm612-clabv`: `vnet5`

### Verify the bridge devices

```bash
ip -br link show type bridge
bridge link
```

Expected bridge names:

- `virbr0`
- `virbr123`
- `virbr124`

### Verify mirror rules

```bash
sudo $REPO_DIR/lab-net-mirror.sh status
```

This should display `tc` filter entries on the source interfaces.

## Operational Guidance During Patch Work

Because both ClearPass VMs are being updated:

- keep the third NIC attached during the patch cycle if SPAN testing will continue after upgrade
- keep the third NIC without an IP unless a different test requires it
- after each patch, verify whether the `Span Port` field behavior changes
- if ClearPass still shows only `None`, that means the extra NIC is still not being accepted by the product UI for SPAN selection

## If ClearPass Still Shows `None`

If `Span Port` still shows only `None` after adding the third NIC and rebooting:

- the hypervisor side is providing the extra interface
- the mirror feed exists on the host side
- but ClearPass is still not exposing the interface as a usable SPAN port

At that point, the fallback options are:

- use other ClearPass profiling collectors instead of TCP fingerprinting
- use switch-side device fingerprinting and send the profiling data to ClearPass
- continue testing with mirrored traffic only as a packet-observation exercise, not as a guaranteed ClearPass SPAN feature

## Existing Related Files

- [CPPM611_DUAL_NIC_NETWORKS_2026.md](./CPPM611_DUAL_NIC_NETWORKS_2026.md)
- [lab-net-egress.sh](./lab-net-egress.sh)
- [lab-net-mirror.sh](./lab-net-mirror.sh)
