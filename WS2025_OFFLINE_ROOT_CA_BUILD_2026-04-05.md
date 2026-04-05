# Windows Server 2025 Offline Root CA Build Notes (2026-04-05)

Contributors: bermekbukair, Codex

## Goal

Build `ws2025-rootca01` as a private lab root CA that:

- stays off the domain
- acts as a `Standalone Root CA`
- will later be powered off or isolated
- will only be brought online when needed to:
  - sign subordinate CA requests
  - publish a fresh root CRL
  - renew the root or subordinate CA chain

## Current confirmed machine state

Confirmed over SSH:

- hostname: `ws2025-rootca01`
- IP: `192.168.122.98/24`
- OS: `Windows Server 2025 Standard Evaluation`
- build: `26100`
- role: `StandaloneServer`
- domain state: `WORKGROUP`

Meaning:

- this is the correct starting point for an offline root CA
- it is not domain-joined
- it is not already a member server in `lab.local`

## Design choice for this root CA

Chosen CA type:

- `Standalone Root CA`

Chosen role name:

- `LAB-ROOTCA-01`

Chosen cryptography baseline:

- RSA
- 4096-bit key
- SHA256
- root validity target: `20 years`

Why:

- simple and conservative
- appropriate for a private lab PKI
- easy to support from Windows Server 2025 and subordinate Windows issuing CAs

## Naming clarification

There are two different names in this PKI build:

- the Windows server hostname
- the CA common name

They are not the same thing.

For the root CA:

- hostname: `ws2025-rootca01`
- CA common name: `LAB-ROOTCA-01`

For the issuing CA plan:

- chosen hostname: `ws25-ica01`
- planned CA common name: `LAB-ISSUINGCA-01`

Important rule:

- the CA common name should not be identical to the computer hostname
- the CA common name should not be the FQDN

Important Windows hostname rule:

- the Windows hostname / NetBIOS name should stay within `15` characters

Meaning:

- `ws2025-issuingca01` was too long for a Windows hostname
- `ws25-ica01` is the corrected issuing CA hostname choice

## CAPolicy.inf planned contents

Before installing AD CS, create:

- `C:\Windows\CAPolicy.inf`

Planned content:

```ini
[Version]
Signature="$Windows NT$"

[PolicyStatementExtension]
Policies=InternalPolicy

[InternalPolicy]
OID=1.2.3.4.1455.67.89.5
Notice="Private Lab PKI"
URL="http://pki.lab.local/pki/cps.txt"

[Certsrv_Server]
RenewalKeyLength=4096
RenewalValidityPeriod=Years
RenewalValidityPeriodUnits=20
CRLPeriod=Years
CRLPeriodUnits=1
CRLDeltaPeriod=Days
CRLDeltaPeriodUnits=0
LoadDefaultTemplates=0
AlternateSignatureAlgorithm=0

[CRLDistributionPoint]
Empty=true

[AuthorityInformationAccess]
Empty=true
```

Meaning:

- the root CA issues no AD templates
- the root certificate itself carries no AIA or CDP extension entries
- this is normal for an offline root

## Planned immediate build sequence

1. Create `CAPolicy.inf`
2. Install Windows feature:
   - `ADCS-Cert-Authority`
3. Configure AD CS as:
   - `StandaloneRootCA`
   - new private key
   - `LAB-ROOTCA-01`
   - RSA 4096
   - SHA256
   - `20` years
4. Tune CRL and validity settings with `certutil`
5. Publish first root CRL
6. Export:
   - root CA certificate
   - root CRL

## Planned later operational model

After subordinate CA issuance is complete:

- keep this VM powered off when not needed
- or disconnect its NIC and treat it as offline

Only bring it back online for:

- signing subordinate CA renewal requests
- publishing a fresh root CRL
- root CA maintenance

## Work completed in this session

### Remote access confirmed

Confirmed working from the Ubuntu host:

- RDP to `192.168.122.98`
- SSH to `Administrator@192.168.122.98`

Meaning:

- the root CA VM can now be administered remotely without opening the console each time

### CAPolicy.inf created

A local source file was created on the Ubuntu host:

- `/home/hadescloak/CAPolicy-rootca.inf`

It was copied to the root CA VM at:

- `C:\Windows\CAPolicy.inf`

The file was then verified remotely.

### AD CS role install completed

The machine was checked first:

- `ADCS-Cert-Authority` state was `Available`

Then the role installation was started from the Ubuntu host over SSH.

Important observed behavior:

- the original inline PowerShell install command behaved badly over SSH
- a safer script-file path was then used instead

Helper script created on the Ubuntu host:

- `/home/hadescloak/install-rootca-role.ps1`

Its contents:

```powershell
$ProgressPreference = 'SilentlyContinue'
Install-WindowsFeature ADCS-Cert-Authority -IncludeManagementTools |
    Format-List Success, RestartNeeded, ExitCode, FeatureResult
```

The machine was later rechecked and the feature state flipped to:

- `ADCS-Cert-Authority = Installed`

Meaning:

- the Windows role installation finished successfully
- the root CA could then be configured safely

### Standalone root CA configuration completed

The AD CS deployment step was run as:

- `StandaloneRootCA`
- CA common name: `LAB-ROOTCA-01`
- crypto provider: `RSA#Microsoft Software Key Storage Provider`
- hash: `SHA256`
- key length: `4096`
- validity: `20 years`

The CA service state after configuration:

- service: `certsvc`
- status: `Running`
- startup type: `Automatic`

### Root CA registry settings confirmed

The following configuration values were verified under the CA configuration key:

- `CommonName = LAB-ROOTCA-01`
- `ValidityPeriod = Years`
- `ValidityPeriodUnits = 20`
- `CRLPeriod = Years`
- `CRLPeriodUnits = 1`
- `CRLOverlapPeriod = Weeks`
- `CRLOverlapUnits = 1`

Meaning:

- issued subordinate CA certificates from this root will inherit a `20 year` CA validity default unless a subordinate request workflow overrides that
- the root CRL is set to `1 year`
- there is a `1 week` CRL overlap window

### Root CA certificate created successfully

The local machine CA store now contains:

- `CN=LAB-ROOTCA-01`

Observed expiry:

- `2046-04-05`

Meaning:

- the root CA private key and signing certificate were created successfully

### Initial CRL generated successfully

The first root CRL was later generated successfully after the service settled:

- `certutil -crl`

Result:

- `CertUtil: -CRL command completed successfully.`

### Exported root CA files

Exports were created in:

- `C:\CA-Exports`

Observed files:

- `LAB-ROOTCA-01.cer`
- `LAB-ROOTCA-01.crl`
- `ws2025-rootca01_LAB-ROOTCA-01.crt`

Observed CertEnroll output directory:

- `C:\Windows\System32\CertSrv\CertEnroll`

Observed files there:

- `LAB-ROOTCA-01.crl`
- `ws2025-rootca01_LAB-ROOTCA-01.crt`

Meaning:

- the root certificate and CRL are now available for copying to the future issuing CA and HTTP publication point
- the CA is usable as the signing authority for a subordinate CA request

### Current root CA build status

Current state of `ws2025-rootca01`:

- standalone root CA is configured
- root signing certificate exists
- CertSvc is running
- first CRL exists
- export files exist

This means the root CA build is complete enough for the next phase:

- build the issuing CA request on the subordinate server
- bring that request to this root CA
- issue the subordinate CA certificate here
- copy the issued certificate and root chain back to the issuing CA

### Recommended next hardening step later

After the subordinate CA certificate is issued and the root artifacts are copied where needed:

- power off `ws2025-rootca01`
- or disconnect its NIC
- bring it online only for CRL publication or subordinate/root renewal events

## Exact commands used from the Ubuntu host

### Verify host identity and state

```bash
sshpass -p 'P@ssw0rd' ssh -o StrictHostKeyChecking=no Administrator@192.168.122.98 hostname
sshpass -p 'P@ssw0rd' ssh -o StrictHostKeyChecking=no Administrator@192.168.122.98 "powershell -NoProfile -Command \"Get-ComputerInfo | Select-Object WindowsProductName,WindowsVersion,OsBuildNumber,CsDomainRole,CsDomain | Format-List\""
sshpass -p 'P@ssw0rd' ssh -o StrictHostKeyChecking=no Administrator@192.168.122.98 "powershell -NoProfile -Command \"Get-NetIPAddress -AddressFamily IPv4 | Select-Object InterfaceAlias,IPAddress,PrefixLength | Format-Table -AutoSize\""
```

### Copy CAPolicy.inf

```bash
sshpass -p 'P@ssw0rd' scp -O -o StrictHostKeyChecking=no /home/hadescloak/CAPolicy-rootca.inf Administrator@192.168.122.98:/C:/Windows/CAPolicy.inf
```

### Verify CAPolicy.inf

```bash
sshpass -p 'P@ssw0rd' ssh -o StrictHostKeyChecking=no Administrator@192.168.122.98 "powershell -NoProfile -Command \"Get-Content C:\\Windows\\CAPolicy.inf\""
```

### Start role install from script file

```bash
sshpass -p 'P@ssw0rd' scp -O -o StrictHostKeyChecking=no /home/hadescloak/install-rootca-role.ps1 Administrator@192.168.122.98:/C:/Windows/Temp/install-rootca-role.ps1
sshpass -p 'P@ssw0rd' ssh -o StrictHostKeyChecking=no Administrator@192.168.122.98 "powershell -NoProfile -ExecutionPolicy Bypass -File C:\\Windows\\Temp\\install-rootca-role.ps1"
```

### Check install activity

```bash
sshpass -p 'P@ssw0rd' ssh -o StrictHostKeyChecking=no Administrator@192.168.122.98 "powershell -NoProfile -Command \"Get-Process powershell,TrustedInstaller,dism -ErrorAction SilentlyContinue | Select-Object Name,Id,CPU,StartTime | Format-Table -AutoSize\""
sshpass -p 'P@ssw0rd' ssh -o StrictHostKeyChecking=no Administrator@192.168.122.98 "powershell -NoProfile -Command \"Get-Content C:\\Windows\\Logs\\DISM\\dism.log -Tail 40\""
```

### Verify role completion

```bash
sshpass -p 'P@ssw0rd' ssh -o StrictHostKeyChecking=no Administrator@192.168.122.98 "powershell -NoProfile -Command \"Get-WindowsFeature ADCS-Cert-Authority | Select-Object Name,InstallState | Out-String -Width 200\""
```

### Copy and run standalone root CA configuration

```bash
sshpass -p 'P@ssw0rd' scp -O -o StrictHostKeyChecking=no /home/hadescloak/configure-rootca.ps1 Administrator@192.168.122.98:/C:/Windows/Temp/configure-rootca.ps1
sshpass -p 'P@ssw0rd' ssh -o StrictHostKeyChecking=no Administrator@192.168.122.98 "powershell -NoProfile -ExecutionPolicy Bypass -File C:\Windows\Temp\configure-rootca.ps1"
```

### Verify CA service, registry, certificate, and exports

```bash
sshpass -p 'P@ssw0rd' ssh -o StrictHostKeyChecking=no Administrator@192.168.122.98 "powershell -NoProfile -Command \"Get-Service certsvc | Select-Object Name,Status,StartType | Out-String -Width 200\""
sshpass -p 'P@ssw0rd' ssh -o StrictHostKeyChecking=no Administrator@192.168.122.98 "powershell -NoProfile -Command \"Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\CertSvc\Configuration\LAB-ROOTCA-01' | Select-Object CommonName,ValidityPeriod,ValidityPeriodUnits,CRLPeriod,CRLPeriodUnits,CRLOverlapPeriod,CRLOverlapUnits | Format-List | Out-String -Width 200\""
sshpass -p 'P@ssw0rd' ssh -o StrictHostKeyChecking=no Administrator@192.168.122.98 "powershell -NoProfile -Command \"Get-ChildItem 'Cert:\LocalMachine\CA' | Select-Object Subject,Thumbprint,NotAfter | Format-List | Out-String -Width 200\""
sshpass -p 'P@ssw0rd' ssh -o StrictHostKeyChecking=no Administrator@192.168.122.98 "powershell -NoProfile -Command \"certutil -crl; Get-ChildItem 'C:\CA-Exports' | Select-Object Name,Length,LastWriteTime | Format-Table -AutoSize | Out-String -Width 200\""
sshpass -p 'P@ssw0rd' ssh -o StrictHostKeyChecking=no Administrator@192.168.122.98 "powershell -NoProfile -Command \"Get-ChildItem 'C:\Windows\System32\CertSrv\CertEnroll' | Select-Object Name,Length,LastWriteTime | Format-Table -AutoSize | Out-String -Width 200\""
```
