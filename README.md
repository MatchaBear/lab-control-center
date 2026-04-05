# Lab Control Center

Contributors: bermekbukair, Codex
Last updated: 2026-04-05

## What this repo is

This repo is the control plane and documentation set for a personal multi-vendor security and network lab built on Ubuntu with libvirt/KVM.

It is designed to be:
- reboot-safe
- documentation-heavy
- practical to rebuild on another host
- safe to publish without exposing local-only troubleshooting residue

The repo contains:
- lab planning and phased build decisions
- libvirt network definitions and helper scripts
- bootstrap and helper tooling for VM startup
- ClearPass dual-NIC lab notes and host-port mapping
- PKI, DNS, AAA, and NAC build notes
- portability and import guides for moving the lab between hosts

## Current focus

The current working focus is a NAC-first lab with Aruba ClearPass and related infrastructure.

Documented and working items include:
- dual-NIC ClearPass network design on separate libvirt NAT networks
- persistent GUI forwards for two ClearPass nodes
- persistent SSH forwards for two ClearPass nodes
- boot-time firewall re-application for selective SSH exposure
- reboot-safe bootstrap helpers for selected lab VMs

## Current access model

Ubuntu host LAN IP:
- `192.168.68.127`

ClearPass GUI forwards:
- `https://192.168.68.127:8441`
- `https://192.168.68.127:8442`

ClearPass SSH forwards:
- `ssh -p 2223 <user>@192.168.68.127`
- `ssh -p 2224 <user>@192.168.68.127`

Detailed mapping is recorded in:
- [CPPM_HOST_PORT_MAP_2026-04-03.md](./CPPM_HOST_PORT_MAP_2026-04-03.md)

## Start here

If you are new to this repo, read in this order:

1. [README_START_HERE.md](./README_START_HERE.md)
2. [LAB_SECURITY_AND_VIRT_SUMMARY.md](./LAB_SECURITY_AND_VIRT_SUMMARY.md)
3. [LAB_BUILD_PLAN_PHASED.md](./LAB_BUILD_PLAN_PHASED.md)
4. [LAB_PORTABILITY_PLAYBOOK.md](./LAB_PORTABILITY_PLAYBOOK.md)
5. [TARGET_HOST_PREREQ_IDIOTPROOF.md](./TARGET_HOST_PREREQ_IDIOTPROOF.md)
6. [TARGET_HOST_IMPORT_IDIOTPROOF.md](./TARGET_HOST_IMPORT_IDIOTPROOF.md)

## Most useful docs

Architecture and build:
- [LAB_SECURITY_AND_VIRT_SUMMARY.md](./LAB_SECURITY_AND_VIRT_SUMMARY.md)
- [LAB_BUILD_PLAN_PHASED.md](./LAB_BUILD_PLAN_PHASED.md)
- [PHASE1_TOPOLOGY.md](./PHASE1_TOPOLOGY.md)
- [PHASE1_BUILD_CHECKLIST.md](./PHASE1_BUILD_CHECKLIST.md)

NAC and ClearPass:
- [NAC_STATIC_IP_PLAN_2026.md](./NAC_STATIC_IP_PLAN_2026.md)
- [CPPM611_DUAL_NIC_NETWORKS_2026.md](./CPPM611_DUAL_NIC_NETWORKS_2026.md)
- [CPPM_HOST_PORT_MAP_2026-04-03.md](./CPPM_HOST_PORT_MAP_2026-04-03.md)
- [CLEARPASS_AD_SITE_OFFLINE_LAB_2026.md](./CLEARPASS_AD_SITE_OFFLINE_LAB_2026.md)
- [CLEARPASS_TCP_FINGERPRINTING_VM_MIRRORING_RUNBOOK.md](./CLEARPASS_TCP_FINGERPRINTING_VM_MIRRORING_RUNBOOK.md)

PKI, AAA, and tests:
- [ADCS_2TIER_BLUEPRINT_2026.md](./ADCS_2TIER_BLUEPRINT_2026.md)
- [ADCS_CEREMONY_RUNBOOK.md](./ADCS_CEREMONY_RUNBOOK.md)
- [PHASE1_PRIORITY_AAA_L2.md](./PHASE1_PRIORITY_AAA_L2.md)
- [AAA_TEST_CASES_TLS13.md](./AAA_TEST_CASES_TLS13.md)

Operations and portability:
- [README_START_HERE.md](./README_START_HERE.md)
- [CML_CONTROLLER_ACCESS_AND_INTERFACES.md](./CML_CONTROLLER_ACCESS_AND_INTERFACES.md)
- [CML_BUILD_STATUS_AND_CODEX_NOTES_2026-04-04.md](./CML_BUILD_STATUS_AND_CODEX_NOTES_2026-04-04.md)
- [CML_WINDOWS_ENDPOINT_AND_WS2025_CA_BUILD_2026-04-05.md](./CML_WINDOWS_ENDPOINT_AND_WS2025_CA_BUILD_2026-04-05.md)
- [CML_WINDOWS_ENDPOINT_IDIOTPROOF_RUNBOOK_2026-04-05.md](./CML_WINDOWS_ENDPOINT_IDIOTPROOF_RUNBOOK_2026-04-05.md)
- [SSH_FORWARD_EVE_FIX.md](./SSH_FORWARD_EVE_FIX.md)
- [PUBLISHING_SECURITY_AUDIT_2026-04-03.md](./PUBLISHING_SECURITY_AUDIT_2026-04-03.md)

## Runtime helpers

Bootstrap and helper scripts:
- [bootstrap-lab.sh](./bootstrap-lab.sh)
- [install-systemd-bootstrap.sh](./install-systemd-bootstrap.sh)
- [labctl.sh](./labctl.sh)
- [install-lab-networks.sh](./install-lab-networks.sh)
- [lab-net-egress.sh](./lab-net-egress.sh)
- [lab-net-mirror.sh](./lab-net-mirror.sh)

## Public publishing posture

This repo intentionally excludes local-only residue such as:
- packet captures
- verbose SSH debug transcripts
- agent session scratch notes

The publish hardening review is recorded in:
- [PUBLISHING_SECURITY_AUDIT_2026-04-03.md](./PUBLISHING_SECURITY_AUDIT_2026-04-03.md)

## Notes

This repo is opinionated and practical rather than polished enterprise product documentation.
It is meant to help another engineer or agent understand how the lab is wired, why certain decisions were made, and how to bring it back after a reboot or host move.
