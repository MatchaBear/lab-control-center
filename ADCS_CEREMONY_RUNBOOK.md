# ADCS Ceremony Runbook (2-Tier: Offline Root + Online Issuing)

Contributors: bermekbukair, Codex

Last updated: 2026-03-27

Purpose:
- Build and operate Microsoft ADCS two-tier PKI in a controlled, repeatable way.
- Keep Root CA offline most of the time.

Scope:
- `ROOTCA01` = Standalone Root CA (offline, workgroup)
- `ISSUINGCA01` = Enterprise Subordinate CA (domain joined)

## Preconditions

1. AD DS + DNS is working.
2. `ISSUINGCA01` is domain joined.
3. Time sync and DNS resolution are healthy.
4. You prepared `CAPolicy.inf` files before CA role installation.

## Ceremony 1: Build Offline Root CA

On `ROOTCA01`:
1. Install AD CS role with Certification Authority only.
2. Choose:
- CA type: Standalone Root CA
- New private key
- Strong key length (RSA 4096 recommended in lab if performance acceptable)
3. Configure long validity (example: 10-20 years for root cert in lab).
4. Configure CRL/AIA publication paths.
5. Publish initial CRL.
6. Export root cert (`.cer`) + CRL (`.crl`) to removable media.

After ceremony:
- Power off `ROOTCA01`.

## Ceremony 2: Build Issuing CA (Pending Request)

On `ISSUINGCA01`:
1. Install AD CS role with Certification Authority only.
2. Choose:
- CA type: Enterprise Subordinate CA
- New private key
3. Generate subordinate CA request (`.req`) and leave CA pending.
4. Copy `.req` to removable media.

## Ceremony 3: Sign Subordinate CA on Root

1. Power on `ROOTCA01` (isolated admin window).
2. Submit subordinate request and issue subordinate CA certificate.
3. Publish/update root CRL.
4. Export:
- Subordinate CA cert (`.cer`)
- Root CA cert (`.cer`)
- Latest root CRL (`.crl`)
5. Copy artifacts to removable media.
6. Power off `ROOTCA01`.

## Ceremony 4: Complete Issuing CA Activation

On `ISSUINGCA01`:
1. Install signed subordinate cert.
2. Import root cert and CRL if needed.
3. Start CA service.
4. Verify CA status is active.
5. Publish issuing CRL and AIA.

## Ceremony 5: Publish Trust Chain

Publish to stable HTTP distribution point (recommended):
- Root cert
- Root CRL
- Issuing cert
- Issuing CRL

Also ensure AD-published locations are healthy for domain clients.

## Ceremony 6: Template and Autoenrollment

1. Enable only required certificate templates first.
2. Configure template permissions by security group.
3. Enable autoenrollment GPO for test OU.
4. Enroll one test client and verify full chain + revocation checks.

## Operational Ceremonies (Recurring)

1. Root CRL refresh:
- Bring up `ROOTCA01` only for CRL or subordinate renewal ceremonies.
- Publish updated CRL.
- Shut down root CA again.

2. Issuing CRL routine:
- Keep `ISSUINGCA01` online and monitor CRL validity windows.

3. Backup ceremony:
- Backup CA database + private key after major changes.

## Hardening Checklist

1. Root CA never internet-facing.
2. Root CA admin account separate from domain admin.
3. No day-to-day logons to root CA.
4. Protect removable media used for ceremony transfers.
5. Record every ceremony in a change log (date, operator, artifacts, hashes).

## Validation Checklist

1. Client trusts root and issuing chain.
2. Issued certs chain correctly.
3. CRL endpoints reachable by clients.
4. Revocation checks succeed.
5. Root CA remains powered off outside ceremonies.

## Notes for your lab goals

- This PKI supports certificate-based trust needed for:
  - RADIUS over TLS (RadSec)
  - TACACS+ over TLS deployments (vendor/platform dependent)

