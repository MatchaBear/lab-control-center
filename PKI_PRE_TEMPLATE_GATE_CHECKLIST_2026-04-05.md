# PKI Pre-Template Gate Checklist (2026-04-05)

Contributors: bermekbukair, Codex

## Purpose

Do **not** move to certificate templates, autoenrollment, EAP-TLS, or RadSec issuance until every item here is checked.

This file is the short operational gate.
The long evidence and failure history remain in:

- [WS2025_OFFLINE_ROOT_CA_BUILD_2026-04-05.md](/home/hadescloak/Desktop/Projects/lab-control-center/WS2025_OFFLINE_ROOT_CA_BUILD_2026-04-05.md)
- [WS2025_ISSUING_CA_BUILD_2026-04-05.md](/home/hadescloak/Desktop/Projects/lab-control-center/WS2025_ISSUING_CA_BUILD_2026-04-05.md)
- [WINDOWS_TIME_BASELINE_2026-04-05.md](/home/hadescloak/Desktop/Projects/lab-control-center/WINDOWS_TIME_BASELINE_2026-04-05.md)

## Root CA checklist

- [x] Host exists: `ws2025-rootca01`
- [x] CA exists: `LAB-ROOTCA-01`
- [x] Role type is standalone offline root
- [x] Time corrected to Singapore and `w32tm` healthy
- [x] Root CRL period is `1 year`
- [x] Root HTTP CDP is explicit:
  - `http://pki.lab.local/CertEnroll/LAB-ROOTCA-01.crl`
- [x] Root HTTP AIA is explicit:
  - `http://pki.lab.local/CertEnroll/ws2025-rootca01_LAB-ROOTCA-01.crt`

## Issuing CA checklist

- [x] Host exists: `ws25-ica01`
- [x] Joined to `lab.local`
- [x] CA exists: `LAB-ISSUINGCA-01`
- [x] `certsvc` is running
- [x] Correct rebuilt subordinate cert is active
- [x] Issuing base CRL period is `1 week`
- [x] Issuing delta CRL period is `1 day`
- [x] IIS publication point exists on issuing CA
- [x] `pki.lab.local` resolves to `192.168.122.196`

## Manual CRL / AIA checks

- [x] `http://pki.lab.local/CertEnroll/LAB-ROOTCA-01.crl` returns `200`
- [x] `http://pki.lab.local/CertEnroll/ws2025-rootca01_LAB-ROOTCA-01.crt` returns `200`
- [x] `http://pki.lab.local/CertEnroll/ws25-ica01.lab.local_LAB-ISSUINGCA-01.crt` returns `200`
- [x] DC-side `certutil -urlfetch -verify` against the active issuing CA cert shows:
  - AIA verified
  - CDP verified
  - `Leaf certificate revocation check passed`

## OCSP gate

- [x] OCSP role installed
- [x] OCSP responder signing certificate path fixed
- [x] Revocation configuration on OCSP responder completed
- [ ] AIA / OCSP URL design documented
- [ ] OCSP response tested from a Windows client

Current truth:

- `ADCS-Online-Cert` on `ws25-ica01` is `Installed`
- `OCSPSvc` is running
- `ocsp.msc` shows revocation configuration `LAB-ISSUINGCA-01` as `Working`
- the earlier `Bad signing certificate on Array controller` error was fixed by:
  - granting `WS25-ICA01` template permissions on `OCSP Response Signing`
  - forcing policy/autoenrollment refresh
  - manually enrolling the signer certificate
  - restarting `OCSPSvc`
- OCSP is now enabled at the server side
- client-side OCSP verification is still pending

## Decision

Current decision:

- **Still do not start certificate templates or enrollment yet**

Reason:

- manual HTTP CRL/AIA checks are now good
- OCSP server-side configuration is now good
- but client-side OCSP validation has not been captured yet

## Minimum next step

Next phase should be:

1. document the OCSP URL design explicitly
2. verify revocation over OCSP from a Windows client
3. verify manual CRL fetch still works after OCSP enablement
4. only then begin certificate templates and enrollment
