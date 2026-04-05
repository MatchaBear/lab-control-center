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
