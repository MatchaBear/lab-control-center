# NAC-First Static IP Plan and CML Endpoint Strategy

Contributors: bermekbukair, Codex

Last updated: 2026-04-02

## Decision Summary

- Use `192.168.122.0/24` as the single outer management and AAA subnet on this host.
- Keep only one active NAC family in steady state: either ClearPass or ISE.
- Use CML as the access-switch and endpoint fabric; do not keep EVE-NG and CML active together during heavy test windows.
- Use CML `Server` nodes first for the lightest endpoint emulation, add `Desktop` when you need a browser or packet capture, and use `Ubuntu` only when you need a fuller Linux guest.

## Why this shape fits this host

Observed on this host:

- CPU: `Intel i7-6700HQ`, 4 cores / 8 threads
- RAM: `31 GiB`
- Root disk: `1.8 TiB` NVMe
- Running VM allocations right now:
  - `eve-ng`: `8 vCPU / 24 GiB`
  - `cml-core01`: `4 vCPU / 16 GiB`
  - `cppm611-clabv`: `4 vCPU / 6 GiB`
  - `cppm612-clabv`: `4 vCPU / 6 GiB`

Implication:

- The host is already heavily oversubscribed on paper.
- Running `eve-ng` + `cml-core01` + both ClearPass versions + ISE together is not realistic.
- A NAC-first lab is realistic only if you time-slice the heavy platforms.

Recommended concurrent windows:

1. `cml-core01` + one ClearPass node + 2x CML switches + 2-4 lightweight endpoints
2. `cml-core01` + one ISE node + 2x CML switches + 2-4 lightweight endpoints
3. `eve-ng` only when CML is not your active switching and endpoint fabric

## Current live state observed on 2026-04-02

Current DHCP-learned addresses on `virbr0`:

- `eve-ng`: `192.168.122.100`
- `cml-core01`: `192.168.122.210`
- `cppm611-clabv`: `192.168.122.252` and `192.168.122.102`
- `cppm612-clabv`: `192.168.122.40` and `192.168.122.114`

These are useful for current access. For `cml-core01`, the observed live address `192.168.122.210` is also the documented access address to use unless and until a deliberate re-IP changes it.

Current CML access:

- CML UI: `https://192.168.122.210`
- CML web console: `http://cml-core01:9090`

## Outer Management and AAA Subnet

- Network: `192.168.122.0/24`
- Gateway: `192.168.122.1`
- DNS server for lab infra: `192.168.122.10`
- Keep this subnet for:
  - VM management
  - CML control-plane reachability
  - AAA traffic from switches to ClearPass or ISE
  - syslog, NTP, DNS, and PKI services

## Recommended Static IP Assignments

| Role | Hostname | Static IP | Notes |
| --- | --- | --- | --- |
| AD DS + DNS + issuing CA | `dns-adcs01.lab` | `192.168.122.10` | Immediate Microsoft identity anchor |
| Offline root CA | `rootca01.lab` | `192.168.122.11` | Reserved; normally powered off |
| Separate issuing CA | `issuingca01.lab` | `192.168.122.12` | Reserve for later 2-tier split |
| Syslog + SNMP | `logsnmp01.lab` | `192.168.122.20` | Optional early; useful once switches are alive |
| EVE-NG | `eve-ng.lab` | `192.168.122.30` | Keep static, but do not co-run with heavy CML windows |
| CML core | `cml-core01.lab` | `192.168.122.210` | Main CML GUI and API host; current live address |
| ClearPass 6.11 | `cppm611-clabv.lab` | `192.168.122.41` | Single active management NIC recommended |
| ClearPass 6.12 | `cppm612-clabv.lab` | `192.168.122.42` | Prefer this as the primary ClearPass build |
| ISE primary admin/policy | `ise-pan01.lab` | `192.168.122.60` | First ISE node to build |
| ISE secondary/policy | `ise-psn01.lab` | `192.168.122.61` | Add only in focused ISE test windows |
| ISE secondary reserve | `ise-pan02.lab` | `192.168.122.62` | Reserve only; do not build first |
| ISE secondary reserve | `ise-psn02.lab` | `192.168.122.63` | Reserve only; do not build first |
| External Linux jump/test box | `jump01.lab` | `192.168.122.70` | Optional host-side admin/test VM |
| CML switch mgmt SVI | `sw-ds01.lab` | `192.168.122.111` | CML internal switch mgmt via external connector |
| CML switch mgmt SVI | `sw-as01.lab` | `192.168.122.112` | CML access switch |
| CML switch mgmt SVI | `sw-as02.lab` | `192.168.122.113` | Reserve for second access switch |

## Important NIC Guidance

- For the first NAC build, use one management NIC on each ClearPass or ISE node.
- Do not keep two NICs on the same `192.168.122.0/24` subnet. That adds confusion and no benefit.
- Only add a second NIC later if you have a real guest, posture, or portal testing reason and can place it on a different subnet.

## CML Internal Access-Test Subnets

These are inside the CML topology, not host libvirt addresses:

| Purpose | Subnet | Example Endpoints |
| --- | --- | --- |
| Corp user VLAN | `10.20.10.0/24` | `ep-srv01=10.20.10.11`, `ep-srv02=10.20.10.12` |
| Corp desktop VLAN | `10.20.20.0/24` | `ep-desktop01=10.20.20.11` |
| Guest VLAN | `10.20.30.0/24` | `ep-guest01=10.20.30.11` |
| Quarantine VLAN | `10.20.40.0/24` | `ep-qa01=10.20.40.11` |
| IoT or printer VLAN | `10.20.50.0/24` | `ep-iot01=10.20.50.11` |

Notes:

- If you are doing pure wired `802.1X` or MAB, the endpoints do not need direct L3 reachability to ClearPass or ISE.
- The access switch needs reachability to ClearPass or ISE.
- Keep switch management or AAA source traffic on the outer `192.168.122.0/24` subnet via a CML external connector.

## Best CML Endpoint Choice for NAC-first work

Cisco’s current CML docs show:

- `Server`: Tiny Core Linux host node, very lightweight
- `Desktop`: Alpine XFCE desktop with `Firefox`, `wireshark`, `iperf`, `tcpdump`, `ssh`, and `sshd`
- `Ubuntu`: cloud-init driven Ubuntu node for fuller Linux behavior
- `TRex`: traffic generator, but Cisco explicitly notes "no client support"

Practical recommendation:

1. `Server` node first
- Best for simple IP endpoints, ping, static host tests, and basic NAC flow validation
- Lowest resource cost

2. `Desktop` node second
- Best for browser-based captive portal tests, packet capture, and inside-topology GUI checks
- Still lightweight enough for this host

3. `Ubuntu` node only when needed
- Best for custom tooling, scripts, or supplicant experiments
- Heavier than `Server` or `Desktop`

Inference from the Cisco docs:

- A CML `Server` or `Desktop` node is a real host VM and is valid as a lightweight virtual endpoint inside the topology.
- `TRex` is not the right answer for NAC endpoint emulation because Cisco labels it as a traffic generator with no client support.
- If you need Linux packages not present on Tiny Core or Alpine, use the CML `Ubuntu` node or upload a custom image.

## Recommended NAC-First Topology

Final shape to build first:

1. Outer host and libvirt layer
- `dns-adcs01.lab` at `192.168.122.10`
- `cml-core01.lab` at `192.168.122.210`
- `cppm612-clabv.lab` at `192.168.122.42`
- `logsnmp01.lab` at `192.168.122.20` when ready

2. Inside CML
- `sw-ds01` using `IOL-L2` or `IOSv-L2`
- `sw-as01` using `IOL-L2` or `IOSv-L2`
- one CML external connector into `192.168.122.0/24`
- `ep-srv01`
- `ep-desktop01`

3. Flow
- endpoint attaches to `sw-as01`
- switch authenticates to ClearPass or ISE on `192.168.122.42` or `192.168.122.60`
- identity and PKI come from `dns-adcs01.lab`
- logs go to `logsnmp01.lab`

## What to build first

1. Keep `cml-core01` at `192.168.122.210`
2. Re-IP `cppm612-clabv` to `192.168.122.42`
3. Keep `cppm611-clabv` parked at `192.168.122.41` as the comparison node, not the daily driver
4. Build `dns-adcs01.lab` at `192.168.122.10`
5. In CML, build a lab with:
   - `IOL-L2` or `IOSv-L2` x2
   - external connector x1
   - `Server` node x1
   - `Desktop` node x1
6. Make the switches use `192.168.122.42` as the first RADIUS target
7. Add `ise-pan01.lab` at `192.168.122.60` only after ClearPass flow is stable
8. Keep `eve-ng` stopped during CML plus NAC validation windows

## What not to do next

- Do not build ISE HA first
- Do not run both ClearPass versions and ISE at the same time
- Do not use `CAT9000v` as the initial switch fabric on this host
- Do not rely on CML bootstrap to invent the IP plan; Cisco documents that bootstrap does not create static IP plans

## Dashboard verdict

- Yes, a custom `lab-control-center` dashboard is realistic on this machine.
- No, a generic CPU/RAM dashboard is not worth the effort.
- The right version is a lab-focused TUI layered on top of `labctl.sh`.

Best first dashboard features:

1. show running VMs and their static IPs
2. show which stack is active: `ClearPass`, `ISE`, `CML`, `EVE`
3. ping or TCP checks for `192.168.122.10`, `192.168.122.210`, `192.168.122.42`, and `192.168.122.60`
4. show CML GUI URL and NAC GUI URLs
5. start and stop approved VM groups
6. show doc shortcuts from this folder

## One-line overview by topic

- Static IP plan: clean the outer lab onto `192.168.122.0/24` and stop dual-homing NAC nodes on the same subnet.
- NAC platform priority: make `cppm612-clabv` the first active policy engine, keep ISE for focused windows.
- Endpoint emulation: use CML `Server` first, `Desktop` second, `Ubuntu` only when you need more Linux capability.
- Switching fabric: use `IOL-L2` or `IOSv-L2` first, not `CAT9000v`.
- Machine fit: good for one active NAC stack plus lightweight CML endpoints, bad for all heavy platforms at once.
- Dashboard: worthwhile only as a lab-control TUI, not as a clone of `htop`.

## Cisco references used

- CML System Requirements:
  - https://developer.cisco.com/docs/modeling-labs/system-requirements/
- CML Reference Platforms and Images:
  - https://developer.cisco.com/docs/modeling-labs/reference-platforms-and-images/
- CML FAQ resource table:
  - https://developer.cisco.com/docs/modeling-labs/2-9/faq/
- CML Server node:
  - https://developer.cisco.com/docs/modeling-labs/server/
- CML Desktop node:
  - https://developer.cisco.com/docs/modeling-labs/2-7/desktop/
- CML Bootstrap configuration behavior:
  - https://developer.cisco.com/docs/modeling-labs/bootstrap-configuration-build/
