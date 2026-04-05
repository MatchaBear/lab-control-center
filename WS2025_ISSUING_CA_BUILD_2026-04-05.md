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
