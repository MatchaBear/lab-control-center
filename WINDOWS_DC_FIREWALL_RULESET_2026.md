# Windows DC Firewall Ruleset (2026)

Contributors: bermekbukair, Codex

Last updated: 2026-04-03

## Scope

This document records the manual inbound Windows Firewall rules used on `dns-adcs01` after tightening default inbound behavior and then reopening only the required lab ports for AD, DNS, Kerberos, LDAP, LDAPS, SMB, RPC, Global Catalog, and ping.

This is a manual port-based ruleset, not a service-group-based ruleset.

## Manual inbound rules

Use an elevated PowerShell session:

```powershell
New-NetFirewallRule -DisplayName "DNS TCP 53" -Direction Inbound -Protocol TCP -LocalPort 53 -Action Allow
New-NetFirewallRule -DisplayName "DNS UDP 53" -Direction Inbound -Protocol UDP -LocalPort 53 -Action Allow
New-NetFirewallRule -DisplayName "RPC Endpoint Mapper TCP 135" -Direction Inbound -Protocol TCP -LocalPort 135 -Action Allow
New-NetFirewallRule -DisplayName "RPC Endpoint Mapper UDP 135" -Direction Inbound -Protocol UDP -LocalPort 135 -Action Allow
New-NetFirewallRule -DisplayName "NetBIOS UDP 137" -Direction Inbound -Protocol UDP -LocalPort 137 -Action Allow
New-NetFirewallRule -DisplayName "NetBIOS TCP 139" -Direction Inbound -Protocol TCP -LocalPort 139 -Action Allow
New-NetFirewallRule -DisplayName "SMB TCP 445" -Direction Inbound -Protocol TCP -LocalPort 445 -Action Allow
New-NetFirewallRule -DisplayName "Kerberos TCP 88,464" -Direction Inbound -Protocol TCP -LocalPort 88,464 -Action Allow
New-NetFirewallRule -DisplayName "Kerberos UDP 88,464" -Direction Inbound -Protocol UDP -LocalPort 88,464 -Action Allow
New-NetFirewallRule -DisplayName "LDAP TCP 389" -Direction Inbound -Protocol TCP -LocalPort 389 -Action Allow
New-NetFirewallRule -DisplayName "LDAP UDP 389" -Direction Inbound -Protocol UDP -LocalPort 389 -Action Allow
New-NetFirewallRule -DisplayName "LDAPS TCP 636" -Direction Inbound -Protocol TCP -LocalPort 636 -Action Allow
New-NetFirewallRule -DisplayName "LDAPS UDP 636" -Direction Inbound -Protocol UDP -LocalPort 636 -Action Allow
New-NetFirewallRule -DisplayName "Global Catalog TCP 3268,3269" -Direction Inbound -Protocol TCP -LocalPort 3268,3269 -Action Allow
New-NetFirewallRule -DisplayName "RPC Dynamic TCP 49152-65535" -Direction Inbound -Protocol TCP -LocalPort 49152-65535 -Action Allow
New-NetFirewallRule -DisplayName "ICMPv4 Echo Request" -Direction Inbound -Protocol ICMPv4 -IcmpType 8 -Action Allow
New-NetFirewallRule -DisplayName "ICMPv6 Echo Request" -Direction Inbound -Protocol ICMPv6 -IcmpType 128 -Action Allow
```

## Verification

Check LDAPS specifically:

```powershell
Get-NetFirewallRule -DisplayName "LDAPS *" | Get-NetFirewallPortFilter | Format-Table Protocol,LocalPort
```

Observed output:

```text
Protocol LocalPort
-------- ---------
TCP      636
UDP      636
```

Check the full manual ruleset:

```powershell
Get-NetFirewallRule -Enabled True -Direction Inbound -Action Allow |
Where-Object DisplayName -match 'DNS|RPC Endpoint Mapper|NetBIOS|SMB|Kerberos|LDAP|LDAPS|Global Catalog|RPC Dynamic|ICMP' |
Select-Object DisplayName
```

## Notes

- `TCP 135` is the more important RPC endpoint mapper rule. `UDP 135` was also opened here because the lab decision was to allow both.
- `LDAPS` is normally associated with `TCP 636`. `UDP 636` was also opened here to match the manual rules currently in use.
- If this VM is acting as a full domain controller long term, the built-in Windows firewall service groups are usually safer and easier to maintain than a hand-built port list.
