# Windows AD Template VM Guide

Contributors: bermekbukair, Codex

Last updated: 2026-04-02

## Goal

Build a clean Windows Server template VM that you can clone and reuse for lab work without rebuilding from scratch every time.

This guide is for:

- a reusable Windows Server base image
- fast redeploy for lab-only AD work
- minimizing pain from evaluation-lifetime limits

This guide is **not** for:

- a production gold image
- sysprep-heavy enterprise image engineering
- long-lived domain controller cloning inside the same domain

## Core idea

You want **two stages**:

1. `Stage A`: clean Windows base template
- OS installed
- updates applied
- tools installed
- basic settings done
- **not joined to a domain**
- **not promoted to domain controller**

2. `Stage B`: lab-specific clone
- cloned from Stage A
- renamed
- given static IP
- promoted to AD DS / DNS / ADCS if needed

This separation is important:

- If you template a VM **after** domain promotion, you create identity and AD database problems.
- If you template **before** domain promotion, clones are safe and predictable.

## Recommended VM layout on this host

Use one of your existing Windows install VMs as the source.

Recommended base profile:

- vCPU: `2`
- RAM: `4-6 GiB`
- Disk: `80 GiB`
- Network: `default`

For the template itself, keep it on the `192.168.122.0/24` lab subnet.

## Recommended naming

Use this naming pattern:

- base template: `ws2022-template01`
- first AD build clone: `dns-adcs22-01`
- second test clone: `dns-adcs22-02`
- if using 2025 instead: `ws2025-template01`

## Recommended IP plan

Do **not** bake a permanent static IP into the template unless you are certain every clone will be edited immediately.

Safer pattern:

- template uses DHCP temporarily
- clone gets static IP on first boot for its assigned role

For your current lab:

- AD/DNS primary: `192.168.122.10`
- alternate Windows build: `192.168.122.11`
- gateway: `192.168.122.1`
- final DNS on the AD server itself: `192.168.122.10`

## Which Windows edition to use

For your lab:

- choose `Standard Evaluation (Desktop Experience)`

Why:

- easiest GUI path
- enough for AD DS, DNS, and ADCS lab use
- no need for Datacenter-only features here

## Build process

### Phase 1: Install the OS

1. Open the VM console

For the existing VMs:

```bash
virt-viewer --connect qemu:///system ws2022-eval01
virt-viewer --connect qemu:///system ws2025-eval01
```

2. Install Windows

Choose:

- `Windows Server Standard Evaluation (Desktop Experience)`

3. Disk layout

- use the default partitioning
- install to the full virtual disk

4. Set local Administrator password

- use a lab password you can remember
- store it in your password manager

### Phase 2: First boot cleanup

After first login:

1. Rename the machine

Example for template:

- `WS2022-TEMPLATE01`

Do this before you forget:

- `Settings` -> `System` -> `About` -> `Rename this PC`

2. Reboot after rename

3. Set timezone and verify clock

4. Confirm network works

- DHCP is fine at this stage

5. Install Windows Updates

- run updates until fully current
- reboot as needed

6. Install useful admin tools

Recommended:

- RSAT features if needed
- Edge/Firefox if you want alternate browser access
- 7-Zip
- Notepad++
- PowerShell 7 optional

7. Enable Remote Desktop if desired

- useful for future admin
- keep this as a lab convenience choice

8. Optional convenience settings

- disable Server Manager auto-start if you dislike it
- enable file extensions
- enable copy/paste friendly settings

## What not to do before templating

Do **not** do any of these on the base template:

- do not join a domain
- do not promote to domain controller
- do not install AD CS
- do not install DHCP role for a persistent design
- do not hardcode the final production lab hostname
- do not leave unique certs or role-specific configs if you want a reusable template

## Snapshot point

This is the most important part.

Take the template snapshot **after**:

- Windows install complete
- machine renamed to template name
- updates complete
- basic tools installed
- RDP enabled if wanted

Take the snapshot **before**:

- domain join
- AD DS promotion
- DNS role buildout
- ADCS installation
- static role-specific IP assignment if possible

Recommended snapshot name:

- `clean-base-postupdate`

Recommended second snapshot only if useful:

- `pre-domain-role`

## Best practice: clone, do not mutate the template

Keep the template VM powered off most of the time.

When you need a new lab server:

1. clone the VM disk and XML
2. define new VM
3. boot the clone
4. rename it for its actual role
5. set static IP
6. then promote or configure services

## If you want AD from the clone

Example for your first clone:

- VM name: `dns-adcs22-01`
- hostname: `DNS-ADCS22-01`
- IP: `192.168.122.10/24`
- gateway: `192.168.122.1`
- preferred DNS before promotion: `192.168.122.10` after DNS is installed on itself, or temporary public DNS before role install

Then:

1. set static IP
2. install `AD DS` and `DNS`
3. create new forest
4. reboot
5. verify DNS
6. only then consider `AD CS`

## Template lifecycle advice for evaluation media

For lab use:

- keep one clean template
- keep one powered-on working clone
- snapshot before major role changes
- if a clone becomes messy, discard it and reclone

This is better than trying to stretch one snowflake VM forever.

## Minimal post-install checklist

- OS installed
- local admin password set
- hostname changed to template name
- updates complete
- RDP enabled if wanted
- useful tools installed
- no domain join
- no DC promotion
- snapshot taken

If all of the above is true, your template is ready.

## Optional: sysprep or not?

For your lab, simplest answer:

- if you are cloning carefully and immediately renaming/re-IPing the clone, a clean pre-role template is already very useful
- if you want a more proper generalized Windows template, run `sysprep /generalize /oobe /shutdown` before converting it into your master image

Tradeoff:

- sysprep is cleaner
- but it adds one more moving part
- for a personal lab, a clean pre-domain template is often enough

## Recommended practical path on this host

1. finish installing `ws2022-eval01`
2. turn it into `WS2022-TEMPLATE01`
3. fully patch it
4. enable RDP
5. install only light admin tools
6. shut it down
7. snapshot or clone it as your clean base
8. create `dns-adcs22-01` from that base for real AD work

Do the same later for 2025 only if you specifically want side-by-side testing.

## One-line summary

- Template VM: clean Windows base, no domain role
- Clone VM: actual AD/DNS/ADCS server
- Snapshot timing: after updates, before any identity role
- Best lab habit: rebuild from template, do not endlessly repair a dirty server
