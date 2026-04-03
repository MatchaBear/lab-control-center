# Service Alternatives Decision Guide (Latest Check)

Contributors: bermekbukair, Codex

Last updated: 2026-03-27

## Question 1: Do we need a full Ubuntu VM just for syslog + SNMP?

Short answer: **No**.

You can run syslog/SNMP collectors as containers on the host (or a lightweight VM) instead of a full dedicated Ubuntu VM.

Practical options:

1. Containerized syslog collector
- Use official rsyslog container images (`rsyslog/rsyslog-collector`).
- Good for fast deployment and portability.

2. SNMP polling/trap receiver
- SNMP trap receiver can be done with `snmptrapd` (Net-SNMP).
- For richer monitoring UI and polling, use LibreNMS Docker stack.

When a full VM still makes sense:
- You want strict isolation from host.
- You want long-running infra with less container complexity.
- You need systemd-native service behavior and easier classic ops.

## Question 2: Does DNS need to be Microsoft DNS?

Short answer: **Not strictly required**, but for AD labs Microsoft DNS on DCs is the easiest and most reliable.

Details:
- AD DS depends heavily on DNS (SRV records, dynamic updates, DC discovery).
- Microsoft recommends DNS on every domain controller and AD-integrated zones.
- AD can integrate with existing DNS infrastructures, but operational complexity goes up.

## Question 3: If I want AD / ADCS, do I need Windows DNS?

Short answer:
- **ADCS** itself is a Windows Server role.
- If you want real Microsoft AD + ADCS lab behavior with least pain, run AD DS + DNS on Windows DC.

Alternative patterns:

1. Keep AD/ADCS Microsoft-authentic:
- Windows DC with AD DS + DNS.
- ADCS (issuing CA) on same server initially, split later.

2. Reduce Windows footprint:
- Keep one Windows VM for AD DS/ADCS.
- Keep syslog/SNMP on containers or Linux.

3. Non-Microsoft directory/PKI path:
- Samba AD DC + Samba internal DNS or BIND9_DLZ.
- Replace ADCS with another CA (Smallstep `step-ca`, Vault PKI, EJBCA).
- Good for PKI/network experiments, not exact ADCS behavior parity.

## Recommended decision for your current host (8 threads / 31 GiB RAM)

Best balance:

1. Keep one Windows VM for `AD DS + DNS + ADCS` (authentic Microsoft behavior).
2. Move `syslog + SNMP` to containers (no extra heavy VM needed).
3. Keep `eve-ng` but resize if needed for headroom.

This gives lower RAM pressure and still keeps ADCS objectives intact.

## Container-first mini stack (suggested)

- `rsyslog/rsyslog-collector` for syslog ingest
- LibreNMS Docker (or Net-SNMP + custom scripts) for SNMP poll/trap workflows

## Why this is the pragmatic path

- Meets your ADCS/AD objective without overloading host.
- Avoids wasting RAM on "just infra plumbing" VMs.
- Easier to move lab between hosts (containers + VM bundle).

## Primary sources used

- Microsoft AD DS + DNS planning:
  - https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/plan/dns-and-ad-ds
  - https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/plan/integrating-ad-ds-into-an-existing-dns-infrastructure
  - https://learn.microsoft.com/en-us/troubleshoot/windows-server/networking/verify-srv-dns-records-have-been-created
  - https://learn.microsoft.com/en-us/windows-server/networking/dns/dynamic-update

- Microsoft AD CS docs:
  - https://learn.microsoft.com/en-us/windows-server/identity/ad-cs/

- rsyslog containers:
  - https://www.rsyslog.com/doc/containers/index.html
  - https://www.rsyslog.com/doc/containers/collector.html

- LibreNMS Docker docs:
  - https://docs.librenms.org/Installation/Docker/

- Samba AD DNS back ends:
  - https://wiki.samba.org/index.php/The_Samba_AD_DNS_Back_Ends
  - https://wiki.samba.org/index.php/Setting_up_a_BIND_DNS_Server

- Alternative PKI platforms:
  - https://smallstep.com/docs/step-ca
  - https://developer.hashicorp.com/vault/docs/secrets/pki

