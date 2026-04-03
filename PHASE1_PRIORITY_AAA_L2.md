# Phase 1 Priority Plan: AAA TLS1.3 + DS-AS L2 Incident Tests

Contributors: bermekbukair, Codex

Last updated: 2026-03-27

## Primary goals (your top priorities)

1. AAA lab goal:
- Test user/device admin auth with RADIUS and TACACS.
- Prefer TLS1.3-capable transport where supported.

2. Switching lab goal:
- Test DS-AS uplink/downlink behavior.
- Validate what happens when AS is plugged in later (late link-up event).
- Confirm no L2 incident (loops, STP churn, MAC flaps, broadcast storms).

## Reality constraints on this host

- Host: 8 threads / 31 GiB RAM.
- Running everything (ISE + many network vendors + PKI + EVE) together is not realistic.

Resource-aware strategy:
- Keep PKI and core infra small.
- Run heavy AAA platform only when needed for TLS1.3 TACACS tests.

## AAA protocol facts (important)

1. RADIUS over TLS is standardized (RadSec, RFC 6614).
2. TACACS+ base protocol is RFC 8907; TLS transport support is vendor/platform feature.
3. Cisco has current guidance for TACACS+ over TLS 1.3 with ISE + IOS XE (recent 2026 doc).

Implication:
- For strict "TACACS + TLS1.3", plan for Cisco ISE + compatible IOS XE.
- For lighter phase tests, use RADIUS TLS first and add TACACS TLS1.3 in a focused test window.

## Phase 1A (lightweight, immediate, revised priority)

Components:
1. Cisco switching test bed first (DS/AS behavior validation)
2. Aruba ClearPass next (AAA policy engine focus)
3. `ROOTCA01` (offline root, mostly powered off)
4. `ISSUINGCA01` (online issuing CA)
5. `eve-ng` (for multi-vendor expansion)
6. Containerized syslog/SNMP on host

Target outputs:
- PKI chain works
- ClearPass-backed AAA flow works
- RADIUS TLS tests work
- L2 DS-AS plug-later tests scripted/repeatable

## Phase 1B (focused TACACS TLS1.3 window)

Temporarily allocate resources to:
- Cisco ISE node (version/config supporting TLS1.3 for device admin)
- IOS XE nodes configured for TACACS over TLS

During this window:
- Reduce/stop non-essential VMs
- Keep only required infra online

## DS-AS L2 incident test matrix (must run)

For each scenario, capture logs/counters before/after:

1. Baseline:
- DS up, AS disconnected
- Verify stable STP root and topology

2. Late AS plug-in:
- Plug AS after DS is already forwarding
- Observe:
  - STP state transitions
  - MAC table churn/flaps
  - Broadcast/multicast spikes
  - Port-security events

3. Fast flap:
- Repeated AS link up/down
- Observe recovery time and error counters

4. Mispatch simulation:
- AS connected with accidental loop path
- Verify protections trigger correctly

## L2 guardrails to enable before testing

1. RSTP/MSTP explicitly configured.
2. Root guard on designated DS-facing boundaries where appropriate.
3. BPDU guard on edge/access ports.
4. Loop guard on non-designated links.
5. Storm-control for broadcast/multicast.
6. Portfast only on true edge ports.

## Minimal component sizing (recommended)

1. `ROOTCA01`: 1 vCPU / 2 GiB RAM / 40 GiB disk (offline)
2. `ISSUINGCA01`: 2 vCPU / 4 GiB RAM / 80 GiB disk
3. `eve-ng`: 4-6 vCPU / 12-16 GiB RAM (reduce from current 8/24)
4. ISE test window: allocate only when running TACACS TLS1.3 tests

## Cisco image choices from CML (resource-friendly first)

1. For DS-AS L2 behavior tests first:
- `IOSvL2` (very lightweight in CML; good for STP/MAC/loop behavior testing)

2. For IOS XE feature path on constrained host:
- `CAT8000V` (IOS XE router image; lighter than CAT9000v)

3. What to avoid on this host at the start:
- `CAT9000v` for x2 switch topology (too heavy: typically high RAM per node)

Note:
- You asked for latest IOS XE switches. On this host, use `IOSvL2` for L2 incident logic first, then schedule a focused window or second host for true CAT9Kv-scale tests.

## Acceptance criteria for Phase 1

1. PKI chain active and trusted in lab clients/devices.
2. RadSec test passes with cert validation.
3. TACACS TLS1.3 test passes on supported ISE/IOS XE pair.
4. DS-AS late plug event does not trigger uncontrolled L2 incident.
5. All tests are repeatable after host reboot using bootstrap flow.

## Reference signals (latest)

- RADIUS over TLS standard: RFC 6614
- TACACS+ base protocol: RFC 8907
- Cisco TACACS over TLS 1.3 with ISE/IOS XE guidance (updated Jan 2026):
  - https://www.cisco.com/c/es_mx/support/docs/security-vpn/terminal-access-controller-access-control-system-tacacs-/225097-configure-tacacs-over-tls-1-3-on-an.html
