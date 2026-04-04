# How To Configure Endpoints On CML

Last updated: 2026-04-04

## What this document is for

Use this guide when you want to:

- understand the difference between `802.1X`, `MAB`, and `RADIUS`
- decide which CML endpoint type to use
- make `Server` or `Desktop` nodes behave as NAC endpoints
- understand why some nodes get `192.168.255.x` and others get `192.168.122.x`
- SSH to endpoints from the Ubuntu host

## The short conceptual model

- `RADIUS` is the AAA protocol between the switch and ClearPass or ISE.
- `802.1X` is an access-control method between the endpoint and the switch.
- `MAB` is a fallback access-control method where the switch authenticates the endpoint by MAC address.

So the normal flow is:

1. endpoint sends `EAPOL` to the switch for `802.1X`
2. switch sends `RADIUS` to ClearPass
3. ClearPass returns policy
4. switch authorizes or rejects the endpoint

With `MAB`, the endpoint does not run a supplicant. The switch sends the endpoint MAC to ClearPass over `RADIUS`.

## Venn-diagram view

If you think in Venn-diagram terms, `RADIUS` is the bigger picture.

- `802.1X` can use `RADIUS`
- `MAB` can use `RADIUS`
- ClearPass mainly sees the `RADIUS` side from the NAD or switch

The endpoint itself usually does not send `RADIUS` directly in a wired NAC design.

## Which CML endpoint to use

### `Server`

Use `Server` when you want:

- a lightweight Linux endpoint
- simple ping and reachability tests
- basic NAC validation
- possible SSH access if the node is on a host-reachable network

This is usually Tiny Core Linux.

### `Desktop`

Use `Desktop` when you want:

- a GUI
- browser-based captive portal tests
- easier packet capture
- a better chance of having useful Linux tools available

This is usually an Alpine-based desktop image.

### `Ubuntu`

Use `Ubuntu` when you want:

- a fuller Linux environment
- easier package installation
- better support for `wpa_supplicant`, cert handling, and advanced troubleshooting

For real wired `802.1X` supplicant work, `Ubuntu` is often the cleanest endpoint.

## NAT versus System Bridge in CML

### CML `NAT`

- CML hands out `192.168.255.0/24` addresses by default
- example gateway is `192.168.255.1`
- this is internal to CML
- it is useful for outbound connectivity from the node

This does **not** mean the Ubuntu host can reach those nodes directly.

### CML `System Bridge`

- the endpoint is bridged onto the selected external L2 segment
- on this machine, the practical working segment is `virbr0`
- `virbr0` provides `192.168.122.0/24`

If a CML endpoint is attached through a `System Bridge` external connector aimed at `virbr0`, it can receive a `192.168.122.x` address and become reachable from the Ubuntu host.

## Why the host cannot ping `192.168.255.1`

On this Ubuntu host, the routing table includes:

- `192.168.122.0/24` via `virbr0`
- `192.168.123.0/24` via `virbr123`
- `192.168.124.0/24` via `virbr124`

There is no host route for `192.168.255.0/24`.

That means:

- a CML node connected to CML `NAT` can reach `192.168.255.1`
- the Ubuntu host cannot directly ping `192.168.255.1`

This is expected in the current design.

## How to SSH remotely to CML endpoints

### If the endpoint is on CML `NAT`

- it will likely get `192.168.255.x`
- it is mainly for outbound access
- the Ubuntu host will usually not SSH directly to it

Use the CML console or VNC instead.

### If the endpoint is on `System Bridge` to `virbr0`

- it can get `192.168.122.x`
- the Ubuntu host can usually reach it directly

That is the cleanest path if your goal is:

- SSH from Ubuntu to the endpoint
- host-side browser access
- easier host-side troubleshooting

### Recommended rule

If you want remote SSH from the host, place the endpoint on a `System Bridge` external connector that targets `virbr0`, not on CML `NAT`.

## How to interact with the endpoint types

### `Server`

- use the CML console
- if it has a host-reachable IP and an SSH server running, use SSH from Ubuntu

### `Desktop`

- use the CML `VNC` tab for the GUI
- if it has a host-reachable IP and an SSH server running, use SSH from Ubuntu

## Basic wired `802.1X` idea on Linux

For wired `802.1X`, the endpoint normally needs:

- `wpa_supplicant`
- a wired supplicant config
- an active interface such as `eth0`

Check for the tool first:

```bash
which wpa_supplicant
which wpa_cli
ip link
```

If available, a basic PEAP example looks like this:

```conf
ctrl_interface=/var/run/wpa_supplicant
ap_scan=0

network={
    key_mgmt=IEEE8021X
    eap=PEAP
    identity="testuser"
    password="testpassword"
    phase2="auth=MSCHAPV2"
    eapol_flags=0
}
```

Then start it:

```bash
sudo ip link set eth0 up
sudo wpa_supplicant -D wired -i eth0 -c ./wired-dot1x.conf -dd
```

If successful:

- the endpoint sends `EAPOL`
- the switch relays it to ClearPass over `RADIUS`
- ClearPass logs the transaction
- the switch authorizes the port

## Example `EAP-TLS`

```conf
ctrl_interface=/var/run/wpa_supplicant
ap_scan=0

network={
    key_mgmt=IEEE8021X
    eap=TLS
    identity="host/lab-client"
    ca_cert="/path/ca.pem"
    client_cert="/path/client.pem"
    private_key="/path/client.key"
    private_key_passwd="secret"
    eapol_flags=0
}
```

## If `wpa_supplicant` is missing

Then the endpoint is a poor `802.1X` test client.

In that case:

- use `MAB` for that endpoint, or
- move the test to a fuller Ubuntu node

This is often the pragmatic choice.

## MAB testing approach

MAB is simpler for lightweight endpoints:

- the endpoint only needs to come online
- the switch learns the source MAC
- the switch sends a `RADIUS` request to ClearPass using the MAC as identity
- ClearPass returns allow, deny, VLAN, role, or other policy

This is usually easier than full wired `802.1X` on minimalist Linux images.

## Practical recommendation for this lab

Use all three ideas intentionally:

1. use a fuller Linux node for real `802.1X`
2. use `Server` or `Desktop` for `MAB` and basic endpoint simulation
3. keep ClearPass as the policy engine receiving `RADIUS` from the switch

That gives you:

- one real supplicant path
- one non-supplicant path
- one consistent ClearPass policy plane

## External connector behavior that matters

When you change an `External Connector` between `NAT` and `System Bridge`, stop and wipe that `ext-conn` node before starting it again.

The selected connector configuration is only applied cleanly when the node is unstarted and wiped.

## What `Wipe` means

`Wipe object` removes the node runtime state.

Practically, that means:

- the node is recreated on next start
- volatile runtime changes are discarded
- connector state and learned runtime details are reset

For `ext-conn` nodes, wiping is often required after changing the external network mapping.

## Current machine-specific notes

Observed behavior on this host:

- CML `NAT` gives nodes `192.168.255.x`
- `System Bridge` to `virbr0` can give nodes `192.168.122.x`
- the Ubuntu host can reach `192.168.122.x`
- the Ubuntu host cannot directly reach `192.168.255.x`

If direct SSH from Ubuntu is the priority, build around `System Bridge` to `virbr0`.
