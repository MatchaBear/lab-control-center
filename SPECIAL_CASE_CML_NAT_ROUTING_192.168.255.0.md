# Special Case: Routing To CML NAT `192.168.255.0/24`

Last updated: 2026-04-04

## Purpose

This note describes a special-case design where the outer Ubuntu host, and optionally the home LAN, are made to reach the CML internal NAT subnet `192.168.255.0/24`.

This is not the normal management design, but it is technically possible with the current observed topology.

## Current relevant topology

Observed on this machine:

- Ubuntu host LAN: `192.168.68.127/24`
- Ubuntu libvirt bridge: `192.168.122.1/24`
- CML controller management bridge: `bridge0 = 192.168.122.210/24`
- CML internal NAT bridge: `virbr0 = 192.168.255.1/24`

That means the path can be:

`192.168.68.0/24` -> Ubuntu host -> `192.168.122.210` -> `192.168.255.0/24`

## Can it be routed?

Yes.

It can be routed because:

- Ubuntu can reach `192.168.122.210`
- the CML controller has interfaces on both `192.168.122.0/24` and `192.168.255.0/24`
- Linux can route between those subnets if forwarding and firewall rules allow it

## Step 1: make the Ubuntu host itself route to `192.168.255.0/24`

On the Ubuntu host:

```bash
sudo ip route add 192.168.255.0/24 via 192.168.122.210
```

That only affects the Ubuntu host itself.

## Step 2: if the whole home LAN should reach `192.168.255.0/24`

Your home router must also know that `192.168.255.0/24` is behind the Ubuntu host.

Static route on the home router:

- destination: `192.168.255.0/24`
- next hop: `192.168.68.127`

If the home router cannot add static routes, then the Ubuntu host may still reach `192.168.255.0/24`, but the rest of the home LAN will not do so cleanly without NAT tricks.

## Step 3: the CML controller must forward packets

On the CML controller:

```bash
sudo sysctl -w net.ipv4.ip_forward=1
```

Then permit forwarding if firewall policy blocks it:

```bash
sudo iptables -I FORWARD 1 -i bridge0 -o virbr0 -j ACCEPT
sudo iptables -I FORWARD 1 -i virbr0 -o bridge0 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
```

If `ufw` or another firewall policy is active, forwarding may still need to be opened there as well.

## Step 4: the Ubuntu host may also need forwarding

If traffic is passing from `192.168.68.0/24` through Ubuntu to the CML controller, the Ubuntu host may also need IPv4 forwarding enabled:

```bash
sudo sysctl -w net.ipv4.ip_forward=1
```

And forwarding may need to be allowed:

```bash
sudo iptables -I FORWARD 1 -s 192.168.68.0/24 -d 192.168.255.0/24 -j ACCEPT
sudo iptables -I FORWARD 1 -s 192.168.255.0/24 -d 192.168.68.0/24 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
```

## End-to-end route logic

For a client on `192.168.68.0/24`:

1. client sends `192.168.255.0/24` traffic to the home router
2. home router sends that traffic to Ubuntu `192.168.68.127`
3. Ubuntu routes it to CML `192.168.122.210`
4. CML forwards it to `virbr0`

## Reality check

This can work in principle, but common blockers are:

- no static route on the home router
- IP forwarding disabled on Ubuntu
- IP forwarding disabled on CML
- firewall rules blocking forwarding on Ubuntu
- firewall rules blocking forwarding on CML

## Practical warning

This is a special-case design for experimentation, not the cleanest management-plane design.

If the actual goal is direct host management of lab nodes, it is usually cleaner to use:

- `System Bridge` to `virbr0` / `192.168.122.0/24`, or
- your own routed inside lab subnets behind `R1`
