# Windows Server 2025 Issuing CA Build Notes (2026-04-05)

Contributors: bermekbukair, Codex

## Goal

Build the future issuing CA as:

- server hostname: `ws25-ica01`
- CA common name: `LAB-ISSUINGCA-01`
- CA type: `Enterprise Subordinate CA`
- domain membership: `lab.local`

This server is intended to become the online issuing CA that:

- issues machine certificates
- issues server certificates
- supports later EAP-TLS and RadSec-related certificate issuance workflows

## Initial confirmed machine state

Confirmed over SSH:

- hostname: `ws25-ica01`
- identity: `ws25-ica01\administrator`
- OS: `Windows Server 2025 Standard Evaluation`
- build: `26100`
- role: `StandaloneServer`
- domain state: `WORKGROUP`

Meaning:

- the server is reachable
- the server is not yet domain joined
- it is not yet ready to become an enterprise subordinate CA

## Naming clarification

The Windows hostname and the CA common name are different:

- Windows hostname: `ws25-ica01`
- future CA common name: `LAB-ISSUINGCA-01`

Meaning:

- the hostname stays within Windows NetBIOS limits
- the CA common name stays independent from the machine name

## Remote access completed

Confirmed remote access:

- RDP works to `192.168.122.196`
- SSH works to `Administrator@192.168.122.196`

Observed SSH service state:

- service: `sshd`
- status: `Running`
- startup type: `Automatic`

Meaning:

- future issuing-CA work can be done remotely without reopening the VM console

## Domain join requirement

The intended CA type for this server is:

- `Enterprise Subordinate CA`

That requires this server to be joined to the existing `lab.local` domain first.

This matches the existing lab PKI notes:

- the two-tier AD CS blueprint says the issuing CA is domain joined
- the AD CS ceremony runbook says the issuing CA is domain joined before subordinate setup

## Domain join completed

Domain join credentials were later supplied and used:

- domain: `LAB`
- account: `Administrator`

Result:

- `ws25-ica01` successfully joined `lab.local`
- reboot was required

Post-join state later confirmed:

- `CsDomain = lab.local`
- `CsDomainRole = MemberServer`
- `CsName = WS25-ICA01`

Meaning:

- the server is now in the correct role for an enterprise subordinate CA build

## Next intended sequence

1. Verify post-join domain membership and DNS resolution
2. Create issuing-CA `CAPolicy.inf`
3. Install `ADCS-Cert-Authority`
4. Configure as `Enterprise Subordinate CA`
5. Generate subordinate CA request file
6. Carry request to `ws2025-rootca01`
7. Sign request on `LAB-ROOTCA-01`
8. Return issued subordinate certificate to `ws25-ica01`
9. Complete issuing CA activation

## Work completed in this session

### Domain join and reboot completed

The issuing CA was joined to the domain by script and then rebooted.

Observed result:

- join succeeded with `DOMAIN_JOIN_OK`
- reboot was triggered immediately afterward

### SSH was restored after the domain-join reboot

After the reboot, the user confirmed over RDP that:

- `sshd` was started
- `sshd` startup type was set to `Automatic`
- firewall rule `sshd` was enabled

Meaning:

- remote automation could continue after the network profile changed

### Issuing CA preparation files created

The following helper files were created on the Ubuntu host:

- `/home/hadescloak/CAPolicy-issuingca.inf`
- `/home/hadescloak/install-issuingca-role.ps1`
- `/home/hadescloak/configure-issuingca.ps1`
- `/home/hadescloak/sign-subca-request.ps1`
- `/home/hadescloak/complete-issuingca.ps1`

Purpose:

- `CAPolicy-issuingca.inf` defines issuing CA policy defaults
- `install-issuingca-role.ps1` installs the AD CS role
- `configure-issuingca.ps1` generates the subordinate CA request
- `sign-subca-request.ps1` signs the subordinate request on the root CA
- `complete-issuingca.ps1` installs the returned subordinate certificate and starts the CA

### Issuing CA role install started

The preparation files were copied to `ws25-ica01` and the AD CS role installation was started.

Current observed state at the time of this update:

- `TrustedInstaller` is still running
- DISM log timestamps are still advancing
- `ADCS-Cert-Authority` still reports `Available`

Meaning:

- the role install is still in the Windows servicing phase
- it should be left alone until the feature flips to `Installed`

### Subordinate CA request generated successfully

After the role payload settled enough for ADCS deployment cmdlets to load:

- `Install-AdcsCertificationAuthority` was available
- a subordinate CA request file was successfully generated at:
  - `C:\CAConfig\LAB-ISSUINGCA-01.req`

Observed request file size:

- `1900` bytes

The request begins with:

- `-----BEGIN NEW CERTIFICATE REQUEST-----`

Meaning:

- the issuing CA successfully generated a real subordinate CA CSR
- this CSR was ready to be signed by the offline root

### Root CA signing succeeded

The request was copied from `ws25-ica01` to `ws2025-rootca01`.

The root CA database later confirmed:

- `RequestID = 3`
- `Disposition = Issued`
- `Request Common Name = LAB-ISSUINGCA-01`
- `Certificate Template = SubCA`

Meaning:

- the root CA did actually issue the subordinate CA certificate

### Root artifacts returned from the root CA

The following artifacts were copied back from the root CA side:

- `LAB-ISSUINGCA-01.cer`
- `LAB-ROOTCA-01.cer`
- `LAB-ROOTCA-01.crl`

These were placed on `ws25-ica01` under:

- `C:\CAConfig`

### Current blocker at the time of this update

The remaining incomplete step is:

- installing the returned subordinate CA certificate into the pending CA instance on `ws25-ica01`

What was observed:

- `certsvc` exists
- `certsvc` startup type is `Automatic`
- `certsvc` is still `Stopped`
- Application event log shows:
  - `Microsoft-Windows-CertificationAuthority`
  - Event ID `27`
  - message: `Hierarchical setup is incomplete`

Meaning:

- the CA instance exists
- the issued subordinate certificate has not yet been fully bound to the CA service

Important observation:

- the returned `.rsp` file from the root was only a pending CMC response
- the actual issued subordinate certificate had to be explicitly retrieved later as:
  - `LAB-ISSUINGCA-01.cer`

### Why automation is paused here

The final install step:

- `certutil -installcert C:\CAConfig\LAB-ISSUINGCA-01.cer`

appears to fall into an interactive console path on `ws25-ica01`.

Over SSH this path does not render a usable prompt, so:

- the command hangs
- the CA certificate does not land in `Cert:\LocalMachine\CA`
- `certsvc` stays stopped

This is now a narrow finish-step problem, not a broad build failure.

### Manual finish step currently required

From an RDP session on `ws25-ica01`, complete the CA certificate installation locally using the visible Windows console or Certification Authority management UI.

Artifacts already present on the server:

- `C:\CAConfig\LAB-ISSUINGCA-01.cer`
- `C:\CAConfig\LAB-ROOTCA-01.cer`
- `C:\CAConfig\LAB-ROOTCA-01.crl`

After that manual bind step succeeds, the next checks should be:

```powershell
Get-ChildItem Cert:\LocalMachine\CA
Get-Service certsvc
certutil -crl
```

Expected good result:

- `CN=LAB-ISSUINGCA-01` appears in `Cert:\LocalMachine\CA`
- `certsvc` reaches `Running`
- issuing CRL generation succeeds

## Final completion state

The manual finish step was later completed successfully on `ws25-ica01`.

Observed final commands and results:

```powershell
certutil -installcert C:\CAConfig\LAB-ISSUINGCA-01.cer
Start-Service certsvc
Get-Service certsvc
Get-ChildItem Cert:\LocalMachine\CA
certutil -crl
Get-ChildItem C:\Windows\System32\CertSrv\CertEnroll
```

Observed good results:

- `certutil -installcert C:\CAConfig\LAB-ISSUINGCA-01.cer` completed successfully
- `certsvc` is `Running`
- `CN=LAB-ISSUINGCA-01, DC=lab, DC=local` appears in `Cert:\LocalMachine\CA`
- issuing CRL generation succeeded
- CertEnroll now contains:
  - `LAB-ISSUINGCA-01+.crl`
  - `LAB-ISSUINGCA-01.crl`
  - `ws25-ica01.lab.local_LAB-ISSUINGCA-01.crt`

Meaning:

- the issuing CA is now online
- the CA certificate is bound to the CA service
- the CA can publish its CRL and certificate artifacts

## Important failure lesson: `.rsp` was not the final issued CA certificate

One important mistake happened during the ceremony:

- the first file copied back from the root CA was `LAB-ISSUINGCA-01.rsp`

Why that failed:

- that `.rsp` file was only a `CMC pending response`
- it was not the final issued subordinate CA certificate
- `certutil -dump` showed:
  - `CMC_STATUS_PENDING`
  - `Taken Under Submission`

Meaning:

- the file looked like a response from the root CA
- but it was only the submission/pending wrapper
- it could not complete the issuing CA installation

The correct fix was:

1. Query the root CA database:
   - confirm the request disposition was actually `Issued`
2. Retrieve the actual issued certificate by request ID from the root CA:
   - this produced `LAB-ISSUINGCA-01.cer`
3. Copy that real `.cer` back to `ws25-ica01`
4. Install the `.cer`, not the earlier `.rsp`

Practical rule for future ceremonies:

- do not assume the first `.rsp` copied from the root is the final subordinate CA certificate
- confirm whether the file is pending or issued before trying to bind it to the subordinate CA

## Important failure lesson: revocation prompt and why cancel first was correct

During the manual certificate-install step, a Windows prompt appeared:

- revocation checking could not complete
- the revocation server was offline

Why that happened:

- the issuing CA was trying to validate the root CA chain while the root CRL state was not yet trusted locally in a usable way
- the root CA was also offline, so online revocation lookups were not going to work automatically

Why `Cancel` first was the right move:

- clicking through immediately would have hidden the real PKI publication/trust issue
- the safe move was to stop first and make sure the root cert and root CRL were imported correctly

What was done to reduce the prompt problem:

```powershell
certutil -addstore -f Root C:\CAConfig\LAB-ROOTCA-01.cer
certutil -addstore -f CA C:\CAConfig\LAB-ROOTCA-01.cer
certutil -addstore -f CA C:\CAConfig\LAB-ROOTCA-01.crl
certutil -urlcache * delete
certutil -dump C:\CAConfig\LAB-ROOTCA-01.crl
certutil -store CA
certutil -store Root
```

Meaning:

- the root certificate was explicitly trusted
- the root CRL was explicitly placed in the CA store
- cached revocation data was cleared
- the local machine could now validate the root CRL object itself

Practical lesson for future ceremonies:

1. Import the root cert first.
2. Import the root CRL before installing the subordinate CA cert.
3. Clear URL cache if revocation behavior looks stale.
4. Only proceed with the subordinate cert install after verifying:
   - `certutil -store Root`
   - `certutil -store CA`
   - `certutil -dump <root CRL>`

This is the better path because:

- it reduces avoidable revocation prompts
- it makes later `pkiview.msc` troubleshooting easier
- it avoids masking a real CDP/CRL publication problem behind a one-time prompt acceptance

## Exact commands used from the Ubuntu host

### Verify issuing server identity and state

```bash
sshpass -p 'P@ssw0rd' ssh -o StrictHostKeyChecking=no Administrator@192.168.122.196 "hostname && whoami && powershell -NoProfile -Command \"Get-ComputerInfo | Select-Object WindowsProductName,WindowsVersion,OsBuildNumber,CsDomainRole,CsDomain,CsName | Format-List | Out-String -Width 200\""
```

### Verify SSH service state

```bash
sshpass -p 'P@ssw0rd' ssh -o StrictHostKeyChecking=no Administrator@192.168.122.196 "powershell -NoProfile -Command \"Get-Service sshd -ErrorAction SilentlyContinue | Select-Object Name,Status,StartType | Out-String -Width 200\""
```

### Join the issuing CA to the domain

```bash
sshpass -p 'P@ssw0rd' scp -O -o StrictHostKeyChecking=no /home/hadescloak/join-issuingca-domain.ps1 Administrator@192.168.122.196:/C:/Windows/Temp/join-issuingca-domain.ps1
sshpass -p 'P@ssw0rd' ssh -o StrictHostKeyChecking=no Administrator@192.168.122.196 "powershell -NoProfile -ExecutionPolicy Bypass -File C:\Windows\Temp\join-issuingca-domain.ps1"
sshpass -p 'P@ssw0rd' ssh -o StrictHostKeyChecking=no Administrator@192.168.122.196 shutdown /r /t 0
```

### Copy issuing CA preparation files

```bash
sshpass -p 'P@ssw0rd' scp -O -o StrictHostKeyChecking=no /home/hadescloak/CAPolicy-issuingca.inf Administrator@192.168.122.196:/C:/Windows/CAPolicy.inf
sshpass -p 'P@ssw0rd' scp -O -o StrictHostKeyChecking=no /home/hadescloak/install-issuingca-role.ps1 /home/hadescloak/configure-issuingca.ps1 /home/hadescloak/complete-issuingca.ps1 Administrator@192.168.122.196:/C:/Windows/Temp/
```

### Start and monitor the AD CS role install

```bash
sshpass -p 'P@ssw0rd' ssh -o StrictHostKeyChecking=no Administrator@192.168.122.196 "powershell -NoProfile -ExecutionPolicy Bypass -File C:\Windows\Temp\install-issuingca-role.ps1"
sshpass -p 'P@ssw0rd' ssh -o StrictHostKeyChecking=no Administrator@192.168.122.196 "powershell -NoProfile -Command \"Get-WindowsFeature ADCS-Cert-Authority | Select-Object Name,InstallState | Out-String -Width 200\""
sshpass -p 'P@ssw0rd' ssh -o StrictHostKeyChecking=no Administrator@192.168.122.196 "powershell -NoProfile -Command \"Get-Process TrustedInstaller,dism -ErrorAction SilentlyContinue | Select-Object Name,Id,CPU,StartTime | Format-Table -AutoSize | Out-String -Width 200\""
sshpass -p 'P@ssw0rd' ssh -o StrictHostKeyChecking=no Administrator@192.168.122.196 "powershell -NoProfile -Command \"Get-Content C:\Windows\Logs\DISM\dism.log -Tail 20\""
```

### Generate the subordinate CA request

```bash
sshpass -p 'P@ssw0rd' ssh -o StrictHostKeyChecking=no Administrator@192.168.122.196 "powershell -NoProfile -ExecutionPolicy Bypass -File C:\Windows\Temp\configure-issuingca.ps1"
sshpass -p 'P@ssw0rd' ssh -o StrictHostKeyChecking=no Administrator@192.168.122.196 "powershell -NoProfile -Command \"Get-ChildItem 'C:\CAConfig' | Select-Object Name,Length,LastWriteTime | Format-Table -AutoSize | Out-String -Width 200\""
```

### Sign the subordinate request on the root CA

```bash
sshpass -p 'P@ssw0rd' scp -O -o StrictHostKeyChecking=no Administrator@192.168.122.196:/C:/CAConfig/LAB-ISSUINGCA-01.req /home/hadescloak/LAB-ISSUINGCA-01.req
sshpass -p 'P@ssw0rd' scp -O -o StrictHostKeyChecking=no /home/hadescloak/sign-subca-request.ps1 Administrator@192.168.122.98:/C:/Windows/Temp/sign-subca-request.ps1
sshpass -p 'P@ssw0rd' ssh -o StrictHostKeyChecking=no Administrator@192.168.122.98 "powershell -NoProfile -Command \"New-Item -ItemType Directory -Path 'C:\CAInbox' -Force | Out-Null; New-Item -ItemType Directory -Path 'C:\CAOutbox' -Force | Out-Null\""
sshpass -p 'P@ssw0rd' scp -O -o StrictHostKeyChecking=no /home/hadescloak/LAB-ISSUINGCA-01.req Administrator@192.168.122.98:/C:/CAInbox/LAB-ISSUINGCA-01.req
sshpass -p 'P@ssw0rd' ssh -o StrictHostKeyChecking=no Administrator@192.168.122.98 "powershell -NoProfile -Command \"certutil -view -restrict \\\"Request.CommonName=LAB-ISSUINGCA-01\\\" -out \\\"RequestID,Disposition,Request.CommonName,CertificateTemplate\\\"\""
sshpass -p 'P@ssw0rd' ssh -o StrictHostKeyChecking=no Administrator@192.168.122.98 "powershell -NoProfile -Command \"Remove-Item 'C:\CAOutbox\LAB-ISSUINGCA-01.rsp' -Force -ErrorAction SilentlyContinue; certreq -retrieve -config 'ws2025-rootca01\\LAB-ROOTCA-01' 3 C:\CAOutbox\LAB-ISSUINGCA-01.cer\""
```

### Return issued subordinate cert and root chain

```bash
sshpass -p 'P@ssw0rd' scp -O -o StrictHostKeyChecking=no Administrator@192.168.122.98:/C:/CAOutbox/LAB-ISSUINGCA-01.cer /home/hadescloak/LAB-ISSUINGCA-01.cer
sshpass -p 'P@ssw0rd' scp -O -o StrictHostKeyChecking=no Administrator@192.168.122.98:/C:/CA-Exports/LAB-ROOTCA-01.cer /home/hadescloak/LAB-ROOTCA-01.cer
sshpass -p 'P@ssw0rd' scp -O -o StrictHostKeyChecking=no Administrator@192.168.122.98:/C:/CA-Exports/LAB-ROOTCA-01.crl /home/hadescloak/LAB-ROOTCA-01.crl
sshpass -p 'P@ssw0rd' scp -O -o StrictHostKeyChecking=no /home/hadescloak/LAB-ISSUINGCA-01.cer /home/hadescloak/LAB-ROOTCA-01.cer /home/hadescloak/LAB-ROOTCA-01.crl Administrator@192.168.122.196:/C:/CAConfig/
```

### Final manual bind and activation

```powershell
certutil -addstore -f Root C:\CAConfig\LAB-ROOTCA-01.cer
certutil -addstore -f CA C:\CAConfig\LAB-ROOTCA-01.cer
certutil -addstore -f CA C:\CAConfig\LAB-ROOTCA-01.crl
certutil -urlcache * delete
certutil -dump C:\CAConfig\LAB-ROOTCA-01.crl
certutil -store CA
certutil -store Root
certutil -installcert C:\CAConfig\LAB-ISSUINGCA-01.cer
Start-Service certsvc
Get-Service certsvc
Get-ChildItem Cert:\LocalMachine\CA
certutil -crl
Get-ChildItem C:\Windows\System32\CertSrv\CertEnroll
```

## HTTP publication point for CDP and AIA

### Goal

Build a stable lab publication point at:

- `http://pki.lab.local/CertEnroll/`

This is intentionally simpler and more future-proof than relying on the issuing CA host name directly.

Suggested design:

- DNS name `pki.lab.local`
- hosted on `ws25-ica01`
- IIS `Default Web Site`
- physical folder `C:\inetpub\wwwroot\CertEnroll`

What was actually performed:

- DNS A record `pki.lab.local -> 192.168.122.196` was created on the DC
- IIS was installed on `ws25-ica01`
- `C:\inetpub\wwwroot\CertEnroll` was created
- issuing CA cert/CRLs and root CA cert/CRL were copied there

### Why this step matters

Without a clean HTTP publication point:

- revocation checking becomes inconsistent
- future `pkiview.msc` checks become noisy
- Linux and RadSec clients have a harder time fetching chain and CRL data

### Suggested polling vs what was actually used

Suggested compact IIS install poll:

```powershell
while ($true) { Get-Date; Get-WindowsFeature Web-WebServer | Format-Table Name,InstallState -AutoSize; Start-Sleep 15; Clear-Host }
```

Lighter fallback poll:

```powershell
while ($true) { Get-Date; Get-Command Get-Website -ErrorAction SilentlyContinue; Start-Sleep 15; Clear-Host }
```

What was actually used for the final “done” signal:

- `Get-Command Get-Website`
- `Import-Module WebAdministration; Get-Website`

Observed success state:

- `Get-Website` existed
- `Default Web Site` was `Started`

### Default CDP/AIA values found before change

The issuing CA initially showed placeholder HTTP entries using `%1`:

- CRL HTTP: `http://%1/CertEnroll/%3%8%9.crl`
- CA cert HTTP: `http://%1/CertEnroll/%1_%3%4.crt`

Why this was not good enough:

- `%1` expands to the CA server host name
- the intended stable publication name is `pki.lab.local`
- keeping the placeholder would make the web publication path depend on the server identity instead of the dedicated PKI alias

### First failed attempt and what was wrong

Suggested approach:

- rewrite `CRLPublicationURLs` and `CACertPublicationURLs`
- restart `certsvc`
- run `certutil -crl`

What was actually tried first:

- a one-line SSH PowerShell command using a temporary `$cfg` variable

Why it failed:

- SSH quoting collapsed the `$cfg` assignment
- the registry writes did not apply
- `certutil -crl` then failed with `RPC_S_SERVER_UNAVAILABLE`

Lesson:

- for registry-heavy PowerShell over SSH, a copied `.ps1` file is safer than a single long quoted command

### What was actually performed successfully

An explicit script was copied to `ws25-ica01` and run locally there.

The issuing CA publication URLs were changed to:

- CRL local publish:
  - `65:C:\WINDOWS\system32\CertSrv\CertEnroll\%3%8%9.crl`
- CRL LDAP publish:
  - `79:ldap:///CN=%7%8,CN=%2,CN=CDP,CN=Public Key Services,CN=Services,%6%10`
- CRL HTTP for clients:
  - `6:http://pki.lab.local/CertEnroll/%3%8%9.crl`

- CA cert local publish:
  - `1:C:\WINDOWS\system32\CertSrv\CertEnroll\%1_%3%4.crt`
- CA cert LDAP publish:
  - `3:ldap:///CN=%7,CN=AIA,CN=Public Key Services,CN=Services,%6%11`
- CA cert HTTP for clients:
  - `2:http://pki.lab.local/CertEnroll/%1_%3%4.crt`

After the registry update:

- `certsvc` was restarted
- the first immediate `certutil -crl` hit `RPC_S_SERVER_UNAVAILABLE`
- this was a timing issue because the service had not finished coming back yet

What fixed it:

- rerun `certutil -crl` after `certsvc` was visibly `Running`

Successful result:

- `LAB-ISSUINGCA-01.crl` republished
- `LAB-ISSUINGCA-01+.crl` republished

### Root CA artifacts in the publication folder

The issuing CA web folder also needs root artifacts for chain building and manual verification.

What was copied:

- `LAB-ROOTCA-01.crl`
- `LAB-ROOTCA-01.cer`

Problem discovered:

- `LAB-ROOTCA-01.crl` returned HTTP `200`
- `LAB-ROOTCA-01.cer` returned HTTP `404`

Why this matters:

- a future operator may think the root cert is published because the file exists on disk
- IIS still may not serve the `.cer` path the way expected

What was done instead:

- copied the same root certificate content as:
  - `LAB-ROOTCA-01.crt`

Why this was better:

- `.crt` matched the CA cert publication pattern already used by IIS for the issuing CA cert
- `http://pki.lab.local/CertEnroll/LAB-ROOTCA-01.crt` returned HTTP `200`

### Final verified HTTP baseline

Verified from the DC:

- `Resolve-DnsName pki.lab.local` returned `192.168.122.196`
- `http://pki.lab.local/CertEnroll/LAB-ROOTCA-01.crl` returned `200`
- `http://pki.lab.local/CertEnroll/LAB-ROOTCA-01.crt` returned `200`
- `http://pki.lab.local/CertEnroll/ws25-ica01.lab.local_LAB-ISSUINGCA-01.crt` returned `200`

This is the baseline publication state to preserve before moving on to:

- `pkiview.msc`
- certificate templates
- autoenrollment
- EAP-TLS / RadSec issuance

## Final state at end of this phase

As of the end of this update:

- `ws25-ica01` is a running enterprise subordinate CA
- `certsvc` is running
- issuing CRLs are publishing successfully
- IIS is installed and serving `CertEnroll`
- `pki.lab.local` is the dedicated HTTP publication alias
- root and issuing artifacts are reachable over HTTP in the lab

## Discovery after HTTP publication: the subordinate CA certificate itself was still wrong

### What was checked

Suggested verification step:

- download the issuing CA cert from `pki.lab.local`
- run Windows chain verification from another domain host

What was actually performed:

```powershell
Invoke-WebRequest -UseBasicParsing http://pki.lab.local/CertEnroll/ws25-ica01.lab.local_LAB-ISSUINGCA-01.crt -OutFile C:\Windows\Temp\LAB-ISSUINGCA-01.crt
certutil -urlfetch -verify C:\Windows\Temp\LAB-ISSUINGCA-01.crt
```

### What was wrong

The issuing CA certificate that had already been installed from `RequestID 3` still contained:

- AIA: `file://ws2025-rootca01/CertEnroll/ws2025-rootca01_LAB-ROOTCA-01.crt`
- CDP: `file://ws2025-rootca01/CertEnroll/LAB-ROOTCA-01.crl`

Why this was bad:

- the root CA is intended to become offline later
- a subordinate CA certificate pointing to `file://ws2025-rootca01/...` is the wrong long-term publication design
- this is the kind of thing that later makes `pkiview.msc` look broken even though the CA “seems to work”

### Why this happened

The root CA signed `RequestID 3` before its own publication URLs were corrected.

So the issuing CA certificate was technically valid, but it was minted with the root CA’s old file-based AIA/CDP pointers.

## Corrective action: fix the root CA publication settings before reissuing the subordinate CA cert

### What was found on the root CA

Before correction, the root CA still had:

- `http://%1/CertEnroll/...` placeholder entries
- `file://%1/CertEnroll/...` entries included in AIA/CDP usage

That is exactly why the subordinate CA cert came out wrong.

### What was actually performed on `ws2025-rootca01`

The root CA publication settings were rewritten to explicit HTTP values:

- CRL local publish:
  - `65:C:\WINDOWS\system32\CertSrv\CertEnroll\%3%8%9.crl`
- CRL HTTP:
  - `2:http://pki.lab.local/CertEnroll/%3%8%9.crl`

- CA cert local publish:
  - `1:C:\WINDOWS\system32\CertSrv\CertEnroll\%1_%3%4.crt`
- CA cert HTTP:
  - `2:http://pki.lab.local/CertEnroll/%1_%3%4.crt`

Then:

- `certsvc` was restarted
- a fresh root CRL was published
- updated root artifacts were exported again

Verified result:

- root CA AIA/CDP no longer depended on `file://ws2025-rootca01/...`

### Publication point refresh after root correction

The updated root artifacts were recopied to:

- `C:\inetpub\wwwroot\CertEnroll`

Verified from Windows clients:

- `http://pki.lab.local/CertEnroll/LAB-ROOTCA-01.crl` returned `200`
- `http://pki.lab.local/CertEnroll/LAB-ROOTCA-01.crt` returned `200`

## Why the issuing CA had to be rebuilt

Important lesson:

- once `LAB-ISSUINGCA-01` was already active, simply trying to drop in the reissued subordinate certificate returned:
  - `0x8007139f (ERROR_INVALID_STATE)`

This is why a casual “just install the new cert” approach was not enough.

What was checked before choosing rebuild:

- CA database contents on `ws25-ica01`

Observed result:

- only the CA cert row existed
- only the CA chain row existed
- no end-entity client or server certificates had been issued yet

That made rebuild the clean fix.

## Controlled issuing CA rebuild

### What was actually performed

1. Confirmed the CA database was effectively empty.
2. Stopped `certsvc`.
3. Ran:

```powershell
Uninstall-AdcsCertificationAuthority -Force
```

4. Attempted to reuse the original helper script.

### First rebuild failure

Suggested assumption:

- the helper script could rediscover the AD distinguished name suffix automatically

What actually happened:

- `CADistinguishedNameSuffix` came back null over the rebuild path

Fix:

- reran the subordinate configuration with explicit:
  - `DC=lab,DC=local`

### Second rebuild failure

Suggested assumption:

- a new subordinate CA request could be created immediately after teardown

What actually happened:

- the old CA private key container still existed
- `Install-AdcsCertificationAuthority` failed with:
  - `The private key "LAB-ISSUINGCA-01" already exists.`

Fix:

- reran with:
  - `-OverwriteExistingKey`

### Rebuild result

The issuing CA returned to the correct incomplete subordinate state:

- a fresh `C:\CAConfig\LAB-ISSUINGCA-01.req` was generated
- the CA was not yet active
- this was the correct point to ask the corrected root CA to sign a new subordinate cert

## Corrected subordinate CA reissue

### What was actually performed

1. Copied the fresh rebuilt request back to the root CA.
2. Submitted it with explicit CA config:

```powershell
certreq -submit -config 'ws2025-rootca01\LAB-ROOTCA-01' -attrib 'CertificateTemplate:SubCA' C:\CAInbox\LAB-ISSUINGCA-01.req C:\CAOutbox\LAB-ISSUINGCA-01-fixed.cer
```

3. Root CA created pending `RequestID 6`.
4. Explicitly issued it:

```powershell
certutil -resubmit 6
```

5. Retrieved it to a fresh filename to avoid the automatic `.rsp` overwrite prompt:

```powershell
certreq -retrieve -config 'ws2025-rootca01\LAB-ROOTCA-01' 6 C:\CAOutbox\LAB-ISSUINGCA-01-fixed-v2.cer
```

### Why the fresh filename mattered

If `certreq -retrieve` writes to the same base name repeatedly:

- Windows may ask to overwrite the auto-generated `.rsp`
- over SSH that prompt is hidden and looks like a hang

Using a unique output filename avoids that blind prompt.

### Verified improvement in the corrected subordinate CA certificate

The reissued subordinate certificate from `RequestID 6` now contains:

- CDP:
  - `http://pki.lab.local/CertEnroll/LAB-ROOTCA-01.crl`
- AIA:
  - `http://pki.lab.local/CertEnroll/ws2025-rootca01_LAB-ROOTCA-01.crt`

This is the corrected publication design.

## Current remaining blocker

The final bind of the corrected rebuilt subordinate certificate still falls into an interactive `certutil -installcert` path when executed over SSH.

Observed facts:

- `ws25-ica01` can resolve `pki.lab.local`
- `ws25-ica01` can fetch the corrected root `.crt` and `.crl` over HTTP with `200`
- the issuing CA is back in the correct incomplete subordinate state
- `certutil.exe` processes still hang when the final bind is attempted remotely

Meaning:

- the PKI publication problem is fixed
- the remaining blocker is the final interactive certificate-install path, not chain reachability

## Final idiot-proof finish step from RDP

Open an elevated PowerShell or Command Prompt on `ws25-ica01` and run:

```powershell
certutil -installcert C:\CAConfig\LAB-ISSUINGCA-01-fixed-v2.cer
Start-Service certsvc
Get-Service certsvc
```

Expected result:

- the cert install completes in the visible desktop session
- `certsvc` starts successfully
- the rebuilt issuing CA is now active with the corrected root HTTP AIA/CDP

## Critical correction after the first visible bind attempt

### What happened

When the first visible RDP install was attempted with:

```powershell
certutil -installcert C:\CAConfig\LAB-ISSUINGCA-01-fixed-v2.cer
```

AD CS returned:

- `0x80090003`
- `Bad Key`
- `The new certificate public key does not match the current outstanding request`

### What that means

This is not a generic revocation problem.

It means:

- the certificate file being installed was signed from the wrong CSR
- the currently pending subordinate request on `ws25-ica01` had a different public key

### Why this happened

During the rebuild sequence, older request/certificate files with similar names still existed.

That made it too easy to sign a stale request copy and believe it was the current one.

### What was actually done to prove the mismatch

The live pending request on `ws25-ica01` was dumped directly:

- `C:\CAConfig\LAB-ISSUINGCA-01.req`

The first returned replacement certificate was also dumped:

- `C:\CAConfig\LAB-ISSUINGCA-01-fixed-v2.cer`

Observed result:

- request public key began with:
  - `00 9c 64 93 c1 3a f6 d1 ...`
- cert public key began with:
  - `00 9f 60 fb bd 0a ca 27 ...`

So the mismatch was real.

### Correct fix

The current live request was copied under a unique name:

- `LAB-ISSUINGCA-01-current.req`

That exact uniquely named file was copied to the root CA and signed:

- root created `RequestID 7`
- `RequestID 7` was explicitly issued
- final retrieved certificate:
  - `LAB-ISSUINGCA-01-current-signed-v2.cer`

### Verified result

The final `RequestID 7` certificate now matches the live request key.

Observed matching public key start in both request and certificate:

- `00 9c 64 93 c1 3a f6 d1 ...`

### Updated final idiot-proof finish step

Do **not** use `LAB-ISSUINGCA-01-fixed-v2.cer` anymore.

Use this file instead:

```powershell
certutil -installcert C:\CAConfig\LAB-ISSUINGCA-01-current-signed-v2.cer
Start-Service certsvc
Get-Service certsvc
```

This is the correct certificate for the current outstanding subordinate request.

## Final activation verification baseline

### What was confirmed on `ws25-ica01`

After the correct `RequestID 7` certificate was installed:

- `certsvc` was `Running`
- `certutil -store CA` showed the active issuing CA certificate as:
  - serial: `7400000007d4f10ded50581cb0000000000007`
  - thumbprint: `1f55eeacd8045bfbe1e4ceadc8765a057a44f415`
- fresh issuing CA artifacts were published in:
  - `C:\Windows\System32\CertSrv\CertEnroll`

Observed publication files:

- `LAB-ISSUINGCA-01+.crl`
- `LAB-ISSUINGCA-01.crl`
- `ws25-ica01.lab.local_LAB-ISSUINGCA-01.crt`

### Final web publication refresh

The fresh issuing CA publication files were recopied into:

- `C:\inetpub\wwwroot\CertEnroll`

### One final publication mismatch discovered

Initial post-activation verification still found:

- AIA URL in the issuing CA cert:
  - `http://pki.lab.local/CertEnroll/ws2025-rootca01_LAB-ROOTCA-01.crt`
- but the web folder only had:
  - `LAB-ROOTCA-01.crt`

Effect:

- HTTP `404` for the root AIA URL

Fix:

- copied `ws2025-rootca01_LAB-ROOTCA-01.crt` from the root CA exports into the issuing CA web folder as-is

Verified result:

- `http://pki.lab.local/CertEnroll/ws2025-rootca01_LAB-ROOTCA-01.crt` returned `200`

### Final client-side trust verification from the DC

Suggested verification:

- verify the issuing CA certificate from another Windows machine
- confirm AIA and CDP fetch succeed over HTTP
- confirm revocation check succeeds after importing the lab root locally

What was actually performed on the DC:

1. Download the active issuing CA certificate:

```powershell
Invoke-WebRequest -UseBasicParsing 'http://pki.lab.local/CertEnroll/ws25-ica01.lab.local_LAB-ISSUINGCA-01.crt' -OutFile 'C:\Windows\Temp\LAB-ISSUINGCA-01-active.crt'
```

2. Import the lab root CA cert and root CRL into local stores:

```powershell
certutil -addstore -f Root C:\Windows\Temp\LAB-ROOTCA-01.cer
certutil -addstore -f CA C:\Windows\Temp\LAB-ROOTCA-01.cer
certutil -addstore -f CA C:\Windows\Temp\LAB-ROOTCA-01.crl
```

3. Reverify:

```powershell
certutil -urlfetch -verify C:\Windows\Temp\LAB-ISSUINGCA-01-active.crt
```

### Final verified result

The final verification showed:

- issuing CA AIA:
  - `http://pki.lab.local/CertEnroll/ws2025-rootca01_LAB-ROOTCA-01.crt`
  - verified successfully
- issuing CA CDP:
  - `http://pki.lab.local/CertEnroll/LAB-ROOTCA-01.crl`
  - verified successfully
- final status:
  - `Leaf certificate revocation check passed`

Meaning:

- the two-tier PKI chain is now internally coherent
- HTTP publication for root and issuing artifacts is working
- the earlier AIA/CDP and key-mismatch problems are resolved

### Important final interpretation

If a future machine shows:

- `CERT_E_UNTRUSTEDROOT`

that does not automatically mean the PKI publication point is broken.

It may only mean:

- the lab root certificate has not yet been imported or auto-distributed to that machine

That is a separate trust-distribution problem, not a CA-publication problem.
