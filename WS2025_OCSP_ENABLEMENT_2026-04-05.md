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

OCSP is now installed and the responder configuration exists.

Current verified state:

- `ADCS-Online-Cert` is installed on `ws25-ica01`
- `Install-AdcsOnlineResponder -Force` completed successfully
- `OCSPSvc` is installed and running
- revocation configuration `LAB-ISSUINGCA-01` exists in `ocsp.msc`
- responder status is now `Working`

Remaining work before templates/enrollment:

1. document the exact OCSP URL design
2. perform client-side OCSP validation
3. only then unlock templates and enrollment

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

## Transition from install phase to responder phase

### What changed

Later, the top-level feature finally showed:

```powershell
Get-WindowsFeature ADCS-Online-Cert
```

Observed result:

- `ADCS-Online-Cert = Installed`

This was the real sign that the payload was finally ready.

### Why this mattered

Earlier, trying:

```powershell
Install-AdcsOnlineResponder -Force
```

failed with:

- `The Online Responder cannot be installed before the installation files are added`

After the feature flipped to `Installed`, the exact same command became the correct next step.

### What was actually performed

On `ws25-ica01`:

```powershell
Install-AdcsOnlineResponder -Force
```

Observed result:

- command returned without a real error
- `ErrorString` came back empty

Interpretation:

- the Online Responder service-level installation completed

## Service-level verification after responder install

### What was actually checked

```powershell
Get-Service *ocsp*
Get-Command *ocsp* -ErrorAction SilentlyContinue
```

Observed result:

- service:
  - `OCSPSvc`
- display name:
  - `Online Responder Service`
- status:
  - `Running`
- local tools:
  - `ocsp.msc`
  - `ocspsvc.exe`

### What this means in plain English

At this point:

- the OCSP software is installed
- the OCSP service is alive
- the OCSP management console exists

But at that moment:

- it was **not** usable yet
- no revocation configuration had been created yet
- and there was still no responder signing certificate

## Revocation configuration creation

### What was suggested

Build the responder against the issuing CA, not the root CA.

Use:

- configuration name: `LAB-ISSUINGCA-01`
- existing enterprise CA selection
- CA object: `LAB-ISSUINGCA-01` on `ws25-ica01.lab.local`
- automatic signing certificate selection
- auto-enroll for an OCSP signing certificate
- template: `OCSPResponseSigning`

For revocation provider input:

- keep the LDAP base CRL entry that the wizard discovers
- also add the explicit HTTP base CRL:
  - `http://pki.lab.local/CertEnroll/LAB-ISSUINGCA-01.crl`

### What was actually performed

Inside `ocsp.msc` on `ws25-ica01`:

1. created revocation configuration `LAB-ISSUINGCA-01`
2. selected the existing enterprise CA `LAB-ISSUINGCA-01`
3. left automatic signing certificate selection enabled
4. left `Auto-Enroll for an OCSP signing certificate` enabled
5. added the HTTP CRL in addition to the LDAP CRL

### First observed result

The configuration was created, but the console showed:

- `Bad signing certificate on Array controller`

Meaning in plain English:

- the responder config existed
- but there was no usable `OCSP Response Signing` certificate bound to it

## Why the responder initially failed

### What was checked

The local machine personal store on `ws25-ica01` was inspected.

Observed result:

- only the issuing CA certificate was present
- no separate `OCSP Response Signing` certificate existed

PowerShell confirmation also returned nothing:

```powershell
Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.EnhancedKeyUsageList.FriendlyName -contains 'OCSP Signing' -or $_.EnhancedKeyUsageList.ObjectId -contains '1.3.6.1.5.5.7.3.9' }
```

### What this proved

The problem was not the responder wizard itself.

The real problem was:

- the responder could not sign responses because no signer certificate had been issued

## Why autoenrollment did not work at first

### What was suggested

Try the normal machine refresh first:

```powershell
gpupdate /force
certutil -pulse
```

### What was actually observed

That did **not** produce an OCSP signing cert.

Manual enrollment through `certlm.msc` showed:

- `OCSP Response Signing`
- `Status: Unavailable`
- detailed reason:
  - `The permissions on the certificate template do not allow the current user to enroll for this type of certificate.`

### What this means in plain English

The template existed and was published on the CA, but the issuing CA computer account did not have permission to enroll it.

## Template permission fix

### What was suggested

Grant the issuing CA computer account permission on the `OCSP Response Signing` template.

Use domain-admin context for template changes because template ACLs live in Active Directory, not only on the local CA server.

### What was actually performed

In `certtmpl.msc` as `LAB\Administrator`:

1. opened `OCSP Response Signing` template properties
2. on `General` tab, set short lab values:
   - validity period: `2 days`
   - renewal period: `1 day`
3. left:
   - `Publish certificate in Active Directory` checked
   - `Do not automatically reenroll if a duplicate certificate exists in Active Directory` unchecked
4. on `Security` tab, added computer account:
   - `WS25-ICA01`
5. granted:
   - `Read`
   - `Enroll`
   - `Autoenroll`

### Important lesson

The computer account may resolve in the GUI without showing the trailing `$`.
That is acceptable as long as it resolves to the computer object and not a user.

## Signer enrollment recovery

### What was actually performed

Back on `ws25-ica01` as local administrator:

```powershell
gpupdate /force
certutil -pulse
```

Autoenrollment still did not immediately place the signer certificate.

Then manual enrollment was retried in `certlm.msc`:

1. `Certificates (Local Computer)` -> `Personal` -> `Certificates`
2. `All Tasks` -> `Request New Certificate...`
3. selected `OCSP Response Signing`
4. clicked `Enroll`

Observed result:

- enrollment succeeded

## Final responder recovery

### What was actually performed

After the signer certificate was enrolled, the responder service was restarted:

```powershell
Restart-Service OCSPSvc
```

Then `ocsp.msc` was refreshed.

### Final observed result

The revocation configuration status changed to:

- `LAB-ISSUINGCA-01    Working`

### What this means in plain English

The OCSP responder is now:

- installed
- configured
- holding a valid OCSP signing certificate
- able to use the issuing CA revocation data source

## CA extension correction after OCSP came up

### Why this phase was needed

Even after the responder was `Working`, client verification with:

```powershell
certutil -urlfetch -verify <certfile>
```

still showed:

- `Certificate OCSP  No URLs "None"`

That looked wrong at first, but the reason matters:

- the CA had an HTTP AIA path configured
- the CA had an HTTP CDP path configured
- but those HTTP paths were not being embedded into issued certificates because the correct checkboxes were not enabled on the CA properties

### What was actually found

On `LAB-ISSUINGCA-01`:

```powershell
certutil -getreg CA\CACertPublicationURLs
certutil -getreg CA\CRLPublicationURLs
```

showed:

- HTTP AIA entry existed but had flag `0`
- HTTP CDP entry existed but had flag `0`

Meaning in plain English:

- the CA knew the HTTP publication paths
- but it was not stamping those HTTP paths into newly issued certificates

### What was actually changed in `certsrv.msc`

In:

- `LAB-ISSUINGCA-01` -> `Properties` -> `Extensions`

#### AIA page

For the `http://...` AIA line:

- checked:
  - `Include in the AIA extension of issued certificates`
  - `Include in the online certificate status protocol (OCSP) extension`

For the `ldap://...` AIA line:

- left:
  - `Include in the AIA extension of issued certificates`
- did **not** try to force LDAP into the OCSP extension

#### CDP page

For the `http://...` CDP line:

- checked:
  - `Include in CRLs. Clients use this to find Delta CRL locations`
  - `Include in the CDP extension of issued certificates`
- left unchecked:
  - `Publish CRLs to this location`
  - `Publish Delta CRLs to this location`
  - `Include in the IDP extension of issued CRLs`

For the `ldap://...` CDP line:

- kept the AD-oriented publish and include boxes enabled
- left `Include in the IDP extension of issued CRLs` unchecked

### What happened after Apply

The CA service restarted cleanly and accepted the changes.

Then the following was run on `ws25-ica01`:

```powershell
certutil -crl
copy C:\Windows\System32\CertSrv\CertEnroll\*.crl C:\inetpub\wwwroot\CertEnroll\
copy C:\Windows\System32\CertSrv\CertEnroll\*.crt C:\inetpub\wwwroot\CertEnroll\
```

### Important operational lesson

This copy step is currently manual because:

- AD CS publishes into:
  - `C:\Windows\System32\CertSrv\CertEnroll\`
- IIS serves:
  - `C:\inetpub\wwwroot\CertEnroll\`

So with the current lab design:

- yes, CA publication refresh requires a manual sync step

Better later fix:

- point the IIS `CertEnroll` path directly at the AD CS `CertEnroll` folder
- or automate the copy with a script or scheduled task

Do **not** forget this, because stale HTTP files can make PKI troubleshooting look random.

## Why verifying the issuing CA certificate still showed no OCSP

### What was actually tested

On the DC:

```powershell
Invoke-WebRequest -Uri "http://pki.lab.local/CertEnroll/ws25-ica01.lab.local_LAB-ISSUINGCA-01.crt" -OutFile "$env:TEMP\LAB-ISSUINGCA-01-ocsp-test-2.crt"
certutil -urlfetch -verify "$env:TEMP\LAB-ISSUINGCA-01-ocsp-test-2.crt"
```

Observed result:

- AIA verified
- CRL verified
- `Leaf certificate revocation check passed`
- but:
  - `Certificate OCSP  No URLs "None"`

### Why this is not a contradiction

This does **not** mean the OCSP responder is broken.

It means:

- the issuing CA certificate being tested was issued earlier by the root CA
- CA extension changes on `LAB-ISSUINGCA-01` only affect **new certificates issued by `LAB-ISSUINGCA-01`**
- they do **not** rewrite the already-issued issuing CA certificate

Plain-English rule:

- verifying the issuing CA certificate proves chain and CRL health
- it does **not** prove that new end-entity certificates will advertise OCSP

## Current go/no-go state after this phase

What is now true:

- root and issuing HTTP publication are healthy
- OCSP responder is installed and `Working`
- issuing CA extension settings are corrected for future certificates
- manual CRL validation is still good

What is still needed before calling OCSP fully client-validated:

- issue at least one **new** certificate from `LAB-ISSUINGCA-01`
- inspect that new cert for OCSP/AIA/CDP extensions
- verify that new cert uses the OCSP path successfully

## End-to-end OCSP proof on a newly issued leaf certificate

### Why another test was required

Verifying the issuing CA certificate itself was never enough to prove OCSP.

Reason:

- the issuing CA certificate was issued earlier by the root CA
- changing issuing-CA AIA/CDP/OCSP settings does not rewrite that older CA certificate
- only **new certificates issued by `LAB-ISSUINGCA-01`** can prove whether the corrected OCSP URL is being embedded properly

So a fresh leaf certificate had to be issued.

## Test leaf certificate issuance

### What was suggested

Publish a simple built-in template only for testing revocation behavior.

Use:

- template: `Web Server`
- one machine only for initial test:
  - `WS25-ICA01`

### What was actually performed

In `certsrv.msc` on `ws25-ica01`:

1. `Certificate Templates`
2. `New`
3. `Certificate Template to Issue`
4. selected:
   - `Web Server`

Initial enrollment attempts on both the DC and `ws25-ica01` failed with:

- no permission to request the certificate

### What was wrong

The template was published, but the test machine had no template permissions.

### What fixed it

In `certtmpl.msc` as `LAB\Administrator`:

1. opened `Web Server` template properties
2. on `Security` tab, added:
   - `WS25-ICA01`
3. granted:
   - `Read`
   - `Enroll`

Then on `ws25-ica01`:

```powershell
gpupdate /force
```

After that, `Web Server` became available in the local machine enrollment wizard.

## Subject/SAN lesson on the Web Server template

### What was observed

The `Web Server` template showed:

- `More information is required to enroll for this certificate`

### What this means

That template requires subject information, usually through SAN input.

### What was actually entered

During manual enrollment on `ws25-ica01`:

- no Subject value was filled
- SAN was added:
  - type: `DNS`
  - value: `ws25-ica01.lab.local`

This was enough for the test certificate to enroll successfully.

## First leaf certificate test and what it proved

### First test leaf certificate

Thumbprint:

- `DCD2E99CDBA6EBBBC6FE93631E1E8302AED1F82E`

This certificate was exported and verified from the DC.

### What the DC-side verification showed

The first new leaf certificate now contained revocation and AIA data from the issuing CA.

But the output also exposed two problems:

1. OCSP URL was wrong
2. HTTP delta CRL path was returning `404`

Observed wrong OCSP behavior:

- `Certificate OCSP`
- `Failed "OCSP"`
- `405 Method not allowed`
- URL used:
  - `http://ws25-ica01.lab.local/CertEnroll/ws25-ica01.lab.local_LAB-ISSUINGCA-01.crt`

### What this proved

The CA was stamping the **CA certificate download URL** into the OCSP extension.

That was wrong.

It happened because the AIA HTTP `.crt` line had been marked for:

- `Include in the online certificate status protocol (OCSP) extension`

Plain-English meaning:

- we accidentally told the CA to use the CA cert download path as the OCSP responder URL

## OCSP URL correction

### What was actually changed

In `certsrv.msc` on `LAB-ISSUINGCA-01`, under `Extensions` -> `Authority Information Access (AIA)`:

1. on the existing `http://...crt` line:
   - **unchecked**:
     - `Include in the online certificate status protocol (OCSP) extension`
   - left checked:
     - `Include in the AIA extension of issued certificates`

2. added a new dedicated OCSP URL:
   - `http://ocsp.lab.local/ocsp`

3. on that new OCSP line:
   - checked only:
     - `Include in the online certificate status protocol (OCSP) extension`
   - did **not** check:
     - `Include in the AIA extension of issued certificates`

Then:

- applied the change
- allowed CA service restart
- regenerated CRLs
- restarted `OCSPSvc`

## Final leaf certificate proof

### Why a second leaf certificate was needed

The first test leaf still had the old bad OCSP URL embedded.

So another **new** leaf certificate had to be issued after the CA extension fix.

### Final test leaf certificate

Thumbprint:

- `78CD7479B05DB42668D5D90FA44D50B4E8FBF0E2`

Exported to:

- `C:\CAConfig\ws25-ica01-webserver-test-ocsp-fixed.cer`

### Final verification result on the DC

The DC-side command:

```powershell
certutil -urlfetch -verify C:\Windows\Temp\ws25-ica01-webserver-test-ocsp-fixed.cer
```

showed:

- issuing CA AIA over LDAP and HTTP present
- base CRL validation good
- and most importantly:
  - `Certificate OCSP`
  - `Verified "OCSP"`
  - URL:
    - `http://ocsp.lab.local/ocsp`
- `Leaf certificate revocation check passed`

### Plain-English conclusion

This is the real end-to-end OCSP proof.

It proves:

- the responder is alive
- the CA is now embedding the correct OCSP URL into newly issued leaf certificates
- a Windows client can successfully use that OCSP URL

## Remaining non-blocking issue: HTTP delta CRL 404

### What is still imperfect

The final verification still showed:

- `Failed "CDP"`
- `404 Not found`
- URL:
  - `http://ws25-ica01.lab.local/CertEnroll/LAB-ISSUINGCA-01+.crl`

### What this means

The HTTP delta CRL publication path is not yet being served correctly under that hostname/path combination.

But this did **not** block revocation success because:

- LDAP delta CRL retrieval still worked
- HTTP base CRL retrieval still worked
- OCSP verification worked
- overall revocation checking still passed

### Current judgment

This delta-CRL `404` is a cleanup item, not a hard blocker.

Templates and enrollment can move forward once this state is recorded, because:

- manual CRL validation is good
- server-side OCSP is good
- client-side OCSP on a new leaf cert is good

## Operational lessons from this phase

### Lesson 1

`ADCS-Online-Cert = Installed` only means the OCSP role payload exists.
It does **not** mean the responder is usable yet.

### Lesson 2

`Bad signing certificate on Array controller` usually means:

- no usable responder signing cert exists
- or the responder has not rebound to it yet

### Lesson 3

Publishing the `OCSPResponseSigning` template on the CA is not enough by itself.
The issuing CA computer account also needs:

- `Read`
- `Enroll`
- `Autoenroll`

on that template.

### Lesson 4

For this lab, keeping both revocation sources is correct:

- LDAP base CRL for AD-integrated behavior
- HTTP base CRL for explicit, testable publication

Do not remove HTTP just because LDAP is present.

This is the difference between:

- “OCSP is installed”
- and
- “OCSP is actually configured and usable”

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
- [x] `ADCS-Online-Cert` feature fully installed
- [x] `Install-AdcsOnlineResponder` run successfully
- [ ] Responder revocation configuration created
- [ ] OCSP response checked from a Windows client

## Current stop/go decision

Current decision:

- **Do not move to endpoint templates or enrollment yet**

Reason:

- manual CRL publication is now good
- OCSP software is now installed
- but responder configuration and validation are still incomplete

## Final plain-English summary

Current truth:

- your PKI core is now healthy enough for OCSP work
- your revocation URLs over HTTP are working
- OCSP software is **installed**, but OCSP configuration is **not finished**

So the next safe move is:

- finish Online Responder installation
- finish OCSP configuration
- verify OCSP from a client
- only then proceed to certificate templates and enrollment
