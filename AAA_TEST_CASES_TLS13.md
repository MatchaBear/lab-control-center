# AAA Test Cases (TLS1.3 Focus) + DS-AS L2 Validation

Contributors: bermekbukair, Codex

Last updated: 2026-03-27

## Purpose

This runbook is for your Phase 1 priorities:
1. Validate AAA with TLS1.3-capable paths.
2. Validate DS-AS late-plug uplink/downlink behavior (no L2 incident).

## Scope

- RADIUS over TLS (RadSec) baseline and certificate validation.
- TACACS over TLS1.3 where platform support exists (example: Cisco ISE + IOS XE guidance).
- L2 event testing for DS-AS topology.

---

## A) Prereq Checklist

1. PKI ready:
- `ROOTCA01` offline root created.
- `ISSUINGCA01` online issuing CA active.
- Chain/CRL distribution reachable.

2. AAA components ready:
- RADIUS server reachable.
- TACACS server reachable (if using TACACS over TLS test).

3. Network lab ready:
- EVE topology with DS and AS devices.
- Syslog/SNMP collection active.

4. Clock sync:
- NTP synchronized on all devices (critical for cert validation).

---

## B) Test Case Set: RADIUS over TLS (RadSec)

## TC-RADSEC-01: TLS handshake uses TLS1.3 (if stack supports it)

Steps:
1. Configure RADIUS client/server over TLS endpoint.
2. Use certs issued by your issuing CA.
3. Initiate auth transaction.
4. Capture handshake on server side.

Expected:
- Auth succeeds.
- TLS handshake completes.
- Negotiated protocol is TLS1.3 (or highest supported if peer limits apply).

Pass criteria:
- Successful auth + validated server certificate + expected TLS version.

## TC-RADSEC-02: Cert chain validation

Steps:
1. Rotate server cert to one signed by issuing CA.
2. Ensure client trust store has root+issuing chain.
3. Run auth.

Expected:
- Success with valid chain.
- Failure if chain broken (negative test).

Pass criteria:
- Positive and negative behavior both match design.

## TC-RADSEC-03: Revocation behavior

Steps:
1. Revoke test client/server cert.
2. Publish updated CRL.
3. Retry auth.

Expected:
- Revoked cert is rejected after CRL refresh interval.

Pass criteria:
- Deterministic deny on revoked cert.

---

## C) Test Case Set: TACACS over TLS1.3 (platform-dependent)

Note:
- TACACS+ base protocol is RFC 8907.
- TLS1.3 transport support is platform/vendor implementation dependent.

## TC-TAC-TLS13-01: TLS1.3 admin auth path

Steps:
1. Configure TACACS server (example: ISE) with TLS1.3 enabled where required.
2. Configure network device TACACS over TLS client settings.
3. Bind device trust to your CA chain.
4. Attempt login with test AAA account.

Expected:
- TACACS auth succeeds.
- TLS channel established with expected cert trust.

Pass criteria:
- Successful AAA against TACACS over TLS path.

## TC-TAC-TLS13-02: Fallback/Failure safety

Steps:
1. Break trust intentionally (wrong CA/cert).
2. Attempt admin login.
3. Verify local break-glass account still works.

Expected:
- TACACS over TLS auth fails securely.
- Operational recovery path (local account) works.

Pass criteria:
- No lockout scenario.

---

## D) DS-AS L2 Incident Test Cases (Primary)

## TC-L2-01: Late AS plug-in (main case)

Topology:
- DS is live and forwarding.
- AS disconnected initially.

Steps:
1. Collect baseline:
- STP root/state
- MAC table counts
- interface error counters
- syslog baseline
2. Plug AS uplink.
3. Observe for 5-10 minutes.

Expected (healthy):
- Controlled STP reconvergence only.
- No persistent loop.
- No sustained MAC flap storm.
- No broadcast storm escalation.

Pass criteria:
- Network stabilizes within acceptable convergence window.

## TC-L2-02: Uplink flap stress

Steps:
1. Flap AS uplink repeatedly (5-10 cycles).
2. Monitor STP, MAC churn, drops, CPU on switches.

Expected:
- No runaway instability.
- Predictable recovery each cycle.

## TC-L2-03: Loop defense validation

Steps:
1. Simulate accidental patch loop.
2. Verify BPDU guard/loop guard/storm-control behavior.

Expected:
- Protection features trigger.
- Blast radius stays contained.

---

## E) Observability and Evidence to capture

For each test, save:
1. Device configs snapshot.
2. Syslog excerpt around event window.
3. SNMP counters before/after.
4. Packet capture or TLS negotiation logs.
5. Pass/fail verdict + notes.

Store under:
- `$REPO_DIR/test-evidence/<date>/`

---

## F) Go/No-Go criteria for Phase 1 completion

Go if:
1. RadSec path stable with valid cert trust.
2. TACACS-over-TLS path validated on chosen platform pair.
3. DS-AS late-plug test does not produce sustained L2 incident.
4. Tests repeat consistently after host reboot/bootstrap.

No-Go if:
1. Cert trust/CRL behavior is inconsistent.
2. L2 test shows unresolved loops/flaps/storms.
3. Recovery procedures fail.

---

## References

- RADIUS over TLS (RadSec): RFC 6614
  - https://datatracker.ietf.org/doc/rfc6614/
- TACACS+ protocol: RFC 8907
  - https://datatracker.ietf.org/doc/rfc8907/
- Cisco TACACS over TLS 1.3 example guidance (2026 update)
  - https://www.cisco.com/c/es_mx/support/docs/security-vpn/terminal-access-controller-access-control-system-tacacs-/225097-configure-tacacs-over-tls-1-3-on-an.html

