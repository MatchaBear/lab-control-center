# L2 Incident Test Results Log (DS-AS)

Contributors: bermekbukair, Codex

Last updated: 2026-03-28

Use this file to record repeatable Layer-2 incident tests and outcomes.

## Environment

- Platform: Cisco Modeling Labs Free
- Nodes:
  - DS1: IOL-L2 (`iol-l2-xe-17.16.01a`)
  - AS1: IOL-L2 (`iol-l2-xe-17.16.01a`)
- Uplink: `DS1 Et0/3 <-> AS1 Et0/0`
- VLANs: `1,10,20,30`
- STP mode: Rapid-PVST

## Baseline config notes

- DS1 root priority: VLAN 1/10 set to `4096`
- AS1 secondary priority: VLAN 1/10 set to `28672`
- Uplink configured as trunk on both sides
- Edge ports on AS1 (`Et0/1-3`) set with portfast+bpduguard (for edge-only use)

---

## Test Case 1: Late AS uplink plug (primary objective)

Date/Time:
- 2026-03-28

Action:
- AS1 uplink `Et0/0` shut/no shut after DS1 already forwarding

Pre-check:
- STP stable
- MAC tables stable
- no interface error counters

Post-check observations:
- Topology changes incremented briefly (expected)
- No persistent STP churn
- Root path restored on `AS1 Et0/0`
- MAC table stable across VLAN 1/10/20/30
- Interface error counters empty

Evidence snippets:
- AS1:
  - `show spanning-tree vlan 1,10 detail | i Number of topology changes|last change|from`
  - `show mac address-table dynamic`
- DS1:
  - same commands as above

Result:
- PASS

Conclusion:
- No L2 incident observed under late-plug uplink test.

---

## Test Case 2: Repeated uplink flap stress (10 cycles)

Date/Time:
- pending

Action:
- 10x rapid flap on AS1 `Et0/0`

Expected:
- Temporary topology changes only
- No prolonged broadcast storm / MAC flap storm
- Deterministic convergence each cycle

Evidence:
- pending

Result:
- pending

---

## Test Case 3: Dual-link loop-prevention behavior

Date/Time:
- pending

Action:
- Add second DS-AS link
- Verify STP blocks redundant path

Expected:
- One forwarding, one blocking/alternate as appropriate
- No loop impact

Evidence:
- pending

Result:
- pending

---

## Test Case 4: Mispatch / trunk mismatch blast-radius check

Date/Time:
- pending

Action:
- Introduce controlled mismatch (access/trunk or VLAN mismatch)

Expected:
- Fault isolated
- No uncontrolled L2 incident

Evidence:
- pending

Result:
- pending

---

## Pass/Fail Gate for Phase 1 L2 objective

Pass if:
1. Primary late-plug test passes.
2. Stress and dual-link tests pass without persistent churn.
3. No sustained packet storm or unresolved loop condition.

Fail if:
1. Convergence does not stabilize.
2. Continuous topology change occurs.
3. MAC table churn remains unstable after event window.

