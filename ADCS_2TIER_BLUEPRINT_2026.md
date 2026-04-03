# ADCS 2-Tier Blueprint (2026, Lab-Optimized)

Contributors: bermekbukair, Codex

Last updated: 2026-03-27

## What this document is for

This is the practical blueprint for your requirement:
- Two Windows Server CAs
  - `ROOTCA01` (offline root, standalone CA)
  - `ISSUINGCA01` (online enterprise subordinate CA)
- Minimal resource footprint
- Best-practice operations for a real-world-style PKI lab

---

## Key decisions (latest due diligence)

1. Yes, your Root CA can be shut down most of the time.
- This is a standard best practice for reducing compromise risk.

2. ADCS issuing CA should stay online.
- It handles enrollment, CRL/AIA publishing workflows, and cert issuance.

3. For AD environments, Windows DNS on DC is still the least-friction path.
- Alternatives exist, but complexity rises (especially with dynamic updates/SRV behavior).

4. You do not need a full extra Ubuntu VM for syslog/SNMP if you want to save resources.
- Containerized collector stack is valid and lighter.

---

## Minimum resource profile (lab-safe)

Given your host (8 threads, 31 GiB RAM), start with:

1. `ROOTCA01` (offline, powered off most of time)
- vCPU: 1
- RAM: 2 GiB
- Disk: 40 GiB
- Network: none by default (attach only during signing ceremonies)

2. `ISSUINGCA01` (online enterprise subordinate)
- vCPU: 2
- RAM: 4 GiB (6 GiB if you add NDES/Web Enrollment)
- Disk: 80 GiB
- Network: management network

3. Domain controller (AD DS + DNS) if separate:
- vCPU: 2
- RAM: 4-6 GiB
- Disk: 60-80 GiB

4. `eve-ng`
- Reduce to 4-6 vCPU and 12-16 GiB RAM before scaling vendors.

---

## Target topology (phase-correct)

- `DC01` (or your `dns-adcs01` split if you choose)
  - AD DS + DNS
- `ISSUINGCA01` (domain joined)
  - Enterprise Subordinate CA
- `ROOTCA01` (workgroup, offline)
  - Standalone Root CA
- HTTP distribution point for CRL/AIA (IIS on DC/Issuing or dedicated small service)

---

## Build sequence (high-level, correct order)

1. Build AD DS + DNS first (if not already done).
2. Build offline `ROOTCA01` (standalone root CA), generate root cert/CRL.
3. Build `ISSUINGCA01`, install AD CS as enterprise subordinate (pending request).
4. Transfer subordinate request to `ROOTCA01`, sign it, publish chain/CRLs.
5. Install signed subordinate cert back on `ISSUINGCA01`.
6. Publish AIA/CDP properly (HTTP + LDAP where appropriate).
7. Configure templates/autoenrollment via GPO.
8. Power off `ROOTCA01`; only power on for renewals/CRL ceremonies.

---

## On-the-ground best practices to follow

1. Keep Root CA offline and non-domain joined.
2. Use separate admin credentials for PKI admin duties.
3. Define `CAPolicy.inf` before installing each CA.
4. Use long validity for root cert, shorter for issuing CA and leaf certs.
5. Set CRL/Delta CRL cadence intentionally (root long, issuing shorter).
6. Publish CRL/AIA to highly available HTTP location.
7. Back up CA database + private keys immediately after build and after major changes.
8. Document every "CA ceremony" (who, when, what was signed/published).

---

## Practical resource-saving options

1. Keep `ROOTCA01` as a tiny VM and powered off.
2. Run syslog/SNMP as containers, not full VM, until needed.
3. Avoid NDES/CES/CEP in phase 1 unless required.
4. Use Server Core for CA VMs if you are comfortable managing it.

---

## Alternatives considered

1. Non-Windows DNS for AD
- Possible, but adds complexity and troubleshooting overhead.

2. Non-ADCS PKI (step-ca, Vault PKI, EJBCA)
- Useful PKI alternatives, but not equivalent to ADCS lab objective.

Conclusion:
- For your goal (real ADCS two-tier lab), Windows AD DS + DNS + ADCS is still the right core.

---

## What to build next in your repo

Create next docs/scripts in this folder:
- `ADCS_CEREMONY_RUNBOOK.md` (exact signing steps and transfer workflow)
- `ADCS_CAPOLICY_INF_TEMPLATES.md` (root + issuing templates)
- `ADCS_BACKUP_AND_RECOVERY.md` (keys/db/restore drill)

---

## Primary references used

- AD CS docs hub:
  - https://learn.microsoft.com/en-us/windows-server/identity/ad-cs/
- CA role and CA types:
  - https://learn.microsoft.com/en-us/windows-server/identity/ad-cs/certification-authority-role
- AD DS + DNS planning:
  - https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/plan/dns-and-ad-ds
  - https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/plan/integrating-ad-ds-into-an-existing-dns-infrastructure
- Dynamic DNS update behavior/security:
  - https://learn.microsoft.com/en-us/windows-server/networking/dns/dynamic-update
- CAPolicy.inf:
  - https://learn.microsoft.com/en-us/windows-server/networking/core-network-guide/cncg/server-certs/prepare-the-capolicy-inf-file
- Windows Server hardware minimums:
  - https://learn.microsoft.com/en-us/windows-server/get-started/hardware-requirements
- Historical two-tier test lab reference (still useful pattern):
  - https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-r2-and-2012/hh831348(v=ws.11)

