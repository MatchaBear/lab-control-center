# Windows Server 2025 OCSP Enablement Guide (2026-04-05)

Contributors: bermekbukair, Codex

## Goal

Enable and validate OCSP for the lab PKI before moving to certificate templates and endpoint enrollment.

Target design for this lab:

- host OCSP on `ws25-ica01`
- keep manual CRL publication working through `http://pki.lab.local/CertEnroll/`
- add OCSP as an additional revocation path, not a replacement for CRLs

## Why this phase exists

Templates and enrollment are intentionally blocked until revocation is sane.

Minimum revocation baseline before templates:

- root and issuing CA publication points reachable over HTTP
- manual CRL checks clean
- OCSP role installed
- OCSP signer path planned and validated

## Lab context and assumptions

This guide assumes the earlier PKI phases are already complete.

Current lab roles:

- offline root CA host: `ws2025-rootca01`
- root CA common name: `LAB-ROOTCA-01`
- issuing CA host: `ws25-ica01`
- issuing CA common name: `LAB-ISSUINGCA-01`
- DNS/DC host: `dns-adcs01`
- HTTP publication alias: `pki.lab.local`

Current publication baseline:

- root CRL URL:
  - `http://pki.lab.local/CertEnroll/LAB-ROOTCA-01.crl`
- root AIA URL:
  - `http://pki.lab.local/CertEnroll/ws2025-rootca01_LAB-ROOTCA-01.crt`
- issuing CA cert URL:
  - `http://pki.lab.local/CertEnroll/ws25-ica01.lab.local_LAB-ISSUINGCA-01.crt`

What OCSP adds:

- a faster revocation-check path for clients
- a responder that answers certificate-status questions
- another dependency that must be healthy before templates and enrollment

What OCSP does **not** replace:

- CRL publication
- manual CRL validation
- AIA/CDP correctness

Keep CRLs working even after OCSP is enabled.

## Starting state before OCSP

Confirmed before this phase:

- `LAB-ROOTCA-01` publication over HTTP is working
- `LAB-ISSUINGCA-01` publication over HTTP is working
- DC-side `certutil -urlfetch -verify` against the issuing CA cert passes revocation checks after importing the lab root locally
- `ADCS-Online-Cert` on `ws25-ica01` is still `Available`

## Scope of this runbook

This file records:

- what was suggested
- what was actually executed
- what failed
- what still blocks moving to templates

## Current status

OCSP phase has started.

Next expected milestones:

1. Install `ADCS-Online-Cert`
2. Confirm role/cmdlets/components are present
3. Decide signer certificate path
4. Configure responder/revocation configuration
5. Verify OCSP response from a Windows client

## High-level sequence to follow

Do this in order:

1. confirm root and issuing publication are already healthy
2. install the Online Responder role payload
3. confirm the responder deployment cmdlet exists
4. publish the `OCSPResponseSigning` template on the issuing CA
5. install/configure the Online Responder service
6. enroll or assign the OCSP signing certificate
7. create revocation configuration
8. validate OCSP from a Windows client
9. only then unlock templates and enrollment

## Work performed so far

### Suggested approach

Suggested order for this lab:

1. install the Online Responder role service
2. confirm the responder deployment cmdlet exists
3. publish the OCSP signing certificate template on the issuing CA
4. configure the responder only after the role payload is fully staged

### What was actually performed

On `ws25-ica01`:

- checked feature state:
  - `Get-WindowsFeature ADCS-Online-Cert`
- confirmed deployment cmdlet availability:
  - `Install-AdcsOnlineResponder`
- published the OCSP signing template on the issuing CA:
  - `certutil -setcatemplates +\"OCSPResponseSigning\"`

Observed result:

- `Install-AdcsOnlineResponder` cmdlet is present
- `OCSPResponseSigning` was added to the CA template list

### Important nuance

Having the deployment cmdlet available does **not** mean the Online Responder role service is fully installed.

This was proven when:

```powershell
Install-AdcsOnlineResponder -Force
```

failed with:

- `The Online Responder cannot be installed before the installation files are added`

Meaning:

- the management/deployment module was present
- the actual role payload was still not fully staged by Windows servicing

## Online Responder role install state

### What was started

The following was started on `ws25-ica01`:

```powershell
Install-WindowsFeature ADCS-Online-Cert -IncludeManagementTools
```

### What was observed

At the time of this update:

- `Get-WindowsFeature ADCS-Online-Cert` still shows:
  - `Available`
- `TrustedInstaller` is still running
- `C:\Windows\Logs\DISM\dism.log` timestamps are still advancing

Example observed DISM behavior:

- `Initiating Changes on Package with values: 5, fffffff0`

Meaning:

- the Online Responder install is still in servicing
- it should not be treated as failed yet

## Idiot-proof poll commands

### Compact feature-state poll

Run on `ws25-ica01`:

```powershell
while ($true) { Get-Date; Get-WindowsFeature ADCS-Online-Cert | Format-Table Name,InstallState -AutoSize; Start-Sleep 15; Clear-Host }
```

### Better servicing poll when feature state is still noisy

Run on `ws25-ica01`:

```powershell
while ($true) { Get-Date; Get-Process TrustedInstaller,dism -ErrorAction SilentlyContinue; Get-Content C:\Windows\Logs\DISM\dism.log -Tail 5; Start-Sleep 15; Clear-Host }
```

How to read it:

- if `TrustedInstaller` is still present, servicing is still active
- if the latest `dism.log` timestamps keep increasing, it is still progressing
- only treat it as stuck if timestamps stop moving for a long time

## What “ready for responder configuration” looks like

Do **not** proceed just because one command exists.

Safe “ready” signs:

- `Get-WindowsFeature ADCS-Online-Cert` shows `Installed`
- `TrustedInstaller` is gone or clearly idle
- `Install-AdcsOnlineResponder -Force` no longer complains about missing installation files

Unsafe signs:

- feature still shows `Available`
- `TrustedInstaller` is still active
- `Install-AdcsOnlineResponder` says the installation files are not added

## OCSP signing certificate dependency

The responder needs an `OCSP Response Signing` certificate.

What was already done:

- the issuing CA now publishes the `OCSPResponseSigning` template

Command used:

```powershell
certutil -setcatemplates +"OCSPResponseSigning"
```

Why this matters:

- without that template, the responder has nothing appropriate to sign OCSP responses with
- enabling the role alone is not enough

How to check whether the template is published:

```powershell
certutil -catemplates
```

What you expect to find:

- `OCSPResponseSigning`

Possible confusion:

- `certutil -catemplates` may still show `Access is denied` text beside a template name in some remote contexts
- the important part is whether `OCSPResponseSigning` appears in the published list after the add operation

## Why templates are still blocked right now

Even though the PKI core is healthy now:

- root and issuing HTTP publication work
- client-side `urlfetch -verify` is clean after importing the lab root locally

Templates and enrollment are still blocked because:

- OCSP role payload is not fully staged yet
- Online Responder service has not been configured yet
- responder signing certificate has not yet been enrolled/assigned
- responder revocation configuration has not yet been created
- OCSP has not yet been tested from a client

## Step-by-step checklist for future continuation

When the role finally flips to `Installed`, continue with this exact order:

1. Verify role installed:

```powershell
Get-WindowsFeature ADCS-Online-Cert
```

2. Install the responder service:

```powershell
Install-AdcsOnlineResponder -Force
```

3. Confirm the service exists and is running:

```powershell
Get-Service *ocsp*
Get-Service *online*responder*
```

4. Confirm the OCSP signing template is still published:

```powershell
certutil -catemplates
```

5. Enroll or assign the OCSP Response Signing certificate.

6. Create the revocation configuration for `LAB-ISSUINGCA-01`.

7. Test OCSP from a Windows client before touching endpoint templates.

## Evidence to capture when you continue

Whoever continues this guide later should record:

- exact command used
- host it was run on
- output or screenshot
- whether it was only suggested or actually performed
- whether it failed
- what the failure actually meant
- what fixed it

This is important because OCSP is one of the easiest AD CS features to “half configure” and then forget why it broke.

## Dependency checklist before OCSP responder configuration

- [x] Root and issuing HTTP publication point working
- [x] Manual CRL/AIA verification working from the DC
- [x] `OCSPResponseSigning` template published on the issuing CA
- [ ] `ADCS-Online-Cert` feature fully installed
- [ ] `Install-AdcsOnlineResponder` run successfully
- [ ] Responder revocation configuration created
- [ ] OCSP response checked from a Windows client

## Current stop/go decision

Current decision:

- **Do not move to endpoint templates or enrollment yet**

Reason:

- manual CRL publication is now good
- OCSP prerequisites are only partially complete
- the Online Responder role itself is still being installed

## Final plain-English summary

Current truth:

- your PKI core is now healthy enough for OCSP work
- your revocation URLs over HTTP are working
- OCSP has **started**, but is **not finished**

So the next safe move is:

- finish Online Responder installation
- finish OCSP configuration
- verify OCSP from a client
- only then proceed to certificate templates and enrollment
