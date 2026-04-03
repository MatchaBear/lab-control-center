# CPPM 6.11 Dual-NIC NAT Networks

Contributors: bermekbukair, Codex

Last updated: 2026-04-02

## Goal

Give `cppm611-clabv` two distinct libvirt NAT networks:

- management on `192.168.123.0/24`
- data on `192.168.124.0/24`

Both are reachable from this Ubuntu host and can be toggled into an internet-blocked mode later.

## New libvirt networks

1. `nac-mgmt`
- Subnet: `192.168.123.0/24`
- Gateway on host: `192.168.123.1`
- Bridge: `virbr123`
- Intended use: ClearPass management, switch AAA source interfaces, host admin access

2. `nac-data`
- Subnet: `192.168.124.0/24`
- Gateway on host: `192.168.124.1`
- Bridge: `virbr124`
- Intended use: ClearPass data interface, captive portal or guest-flow experiments, isolated service-side tests

## Recommended static IPs

For `cppm611-clabv`:

- management NIC: `192.168.123.41/24`
- default gateway: `192.168.123.1`
- data NIC: `192.168.124.41/24`

Important:

- Put the default gateway on the management interface only.
- Do not add a second default gateway on the data interface.
- Keep `192.168.122.0/24` for general lab infra such as `dns-adcs01`, `cml-core01`, and other non-CPPM services.

## Why this is better than keeping both NICs on `192.168.122.0/24`

- clearer management versus data separation
- easier packet capture and policy testing
- easier to block egress later without disturbing the rest of the lab
- less ambiguity than dual-homing the same appliance on the same subnet

## Internet-blocking model

By default both new networks are NATed behind the host.

When you want an air-gap simulation:

- block `nac-mgmt` if you want ClearPass management to lose outbound internet access
- block `nac-data` if you want the secondary network isolated from the internet
- keep host access intact because host-to-guest traffic is not forwarded traffic

Script:

```bash
sudo $REPO_DIR/lab-net-egress.sh status
sudo $REPO_DIR/lab-net-egress.sh block nac-mgmt nac-data
sudo $REPO_DIR/lab-net-egress.sh unblock nac-mgmt nac-data
```

## Install or re-install the networks

```bash
$REPO_DIR/install-lab-networks.sh
virsh -c qemu:///system net-list --all
```

## Files

- [libvirt-network-nac-mgmt.xml](./libvirt-network-nac-mgmt.xml)
- [libvirt-network-nac-data.xml](./libvirt-network-nac-data.xml)
- [install-lab-networks.sh](./install-lab-networks.sh)
- [lab-net-egress.sh](./lab-net-egress.sh)

## Current boundary

This work creates and manages the two new libvirt networks.

It does not yet rewire the existing NIC attachments on `cppm611-clabv`.

That should be done deliberately, because the VM currently has live connectivity and moving NICs changes reachability.
