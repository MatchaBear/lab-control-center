# CML Controller Access And Interfaces

Last updated: 2026-04-04

## Current observed controller state

Current confirmed controller version:

- `Cisco Modeling Labs 2.9.1+build.7`

Current confirmed controller management address:

- `192.168.122.210`

Current confirmed controller services:

- CML UI: `https://192.168.122.210`
- Cockpit web console: `https://cml-core01:9090/`
- Console server SSH: `ssh admin@192.168.122.210`
- Linux shell SSH: `ssh -p 1122 sysadmin@192.168.122.210`

## Important port distinction

### Port `22`

SSH to port `22` on the CML controller does **not** open a normal Linux shell.

It opens the Cisco Modeling Labs console server.

Example:

```bash
ssh admin@192.168.122.210
```

Expected behavior:

- you land in the `consoles>` prompt
- you can run commands like `list`, `open`, `view`, and `connect`
- this is for node console access, not host shell access

This is why commands like `ifconfig` fail there.

### Port `1122`

If the CML SSH service is enabled in System Administration Cockpit, a real Linux shell is available on port `1122`.

Example:

```bash
ssh -p 1122 sysadmin@192.168.122.210
```

This is the correct path for:

- checking interfaces
- checking routes
- viewing logs
- low-level CML host troubleshooting

## Current controller interface interpretation

Observed from the controller shell:

- `bridge0` has `192.168.122.210/24`
- `virbr0` has `192.168.255.1/24`
- `docker0` exists but is down

Meaning:

- `bridge0` is the controller-side bridge carrying the host-reachable management address
- `virbr0` is the CML internal NAT network used by CML `NAT` external connectors
- `docker0` is expected because CML uses containerized services internally

## Why Ubuntu host cannot ping `192.168.255.1`

The Ubuntu host does not own the CML internal NAT bridge.

`192.168.255.1` exists inside the CML controller on its own `virbr0` interface.

That means:

- nodes inside CML using `NAT` can reach `192.168.255.1`
- the outer Ubuntu host cannot directly reach `192.168.255.1`

This is expected behavior.

## Commands to check interfaces on the controller

From the controller shell:

```bash
ip -br addr
ip route
hostname -I
```

For detailed interface output:

```bash
ip addr show
```

## Commands to use the console server

From the Ubuntu host:

```bash
ssh admin@192.168.122.210
```

Useful console server commands:

```text
list
open /<lab-name>/<node-name>/0
view /<lab-name>/<node-name>/0
connect <console-uuid>
```

## Practical guidance

- Use port `22` when you want node console access through the CML console server.
- Use port `1122` when you want a real Linux shell on the controller.
- Use `192.168.122.210` as the controller management IP.
- Treat `192.168.255.1` as the internal CML NAT gateway, not as a host-reachable management address.
