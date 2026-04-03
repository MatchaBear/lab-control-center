# START HERE: Lab Documentation Index (Idiot-Proof)

Contributors: bermekbukair, Codex

Last updated: 2026-04-03

This is the master navigation page for all documents in:

`$REPO_DIR`

Use this file first.

---

## Quick Navigation by Goal

If your goal is "I want to...":

1. Understand what was already done on this machine
- Open: [LAB_SECURITY_AND_VIRT_SUMMARY.md](./LAB_SECURITY_AND_VIRT_SUMMARY.md)

2. Understand what to build first vs later (realistic phased plan)
- Open: [LAB_BUILD_PLAN_PHASED.md](./LAB_BUILD_PLAN_PHASED.md)

3. Make lab startup automatic after reboot
- Script: [bootstrap-lab.sh](./bootstrap-lab.sh)
- Installer: [install-systemd-bootstrap.sh](./install-systemd-bootstrap.sh)
- Startup config: [lab.env](./lab.env)

4. Move/carry lab between hosts using removable SSD
- Open: [LAB_PORTABILITY_PLAYBOOK.md](./LAB_PORTABILITY_PLAYBOOK.md)

5. Prepare a brand new target host before import
- Open: [TARGET_HOST_PREREQ_IDIOTPROOF.md](./TARGET_HOST_PREREQ_IDIOTPROOF.md)

6. Import lab bundle into target host and run it
- Open: [TARGET_HOST_IMPORT_IDIOTPROOF.md](./TARGET_HOST_IMPORT_IDIOTPROOF.md)

7. Start implementing Phase 1 right now
- Open: [PHASE1_TOPOLOGY.md](./PHASE1_TOPOLOGY.md)
- Build steps: [PHASE1_BUILD_CHECKLIST.md](./PHASE1_BUILD_CHECKLIST.md)
- Use helper: [labctl.sh](./labctl.sh)

8. Compare architecture alternatives before committing
- Open: [SERVICE_ALTERNATIVES_DECISION.md](./SERVICE_ALTERNATIVES_DECISION.md)

9. Build ADCS two-tier (offline root + online issuing) with low resource use
- Open: [ADCS_2TIER_BLUEPRINT_2026.md](./ADCS_2TIER_BLUEPRINT_2026.md)

10. Run priority objectives (AAA TLS1.3 + DS-AS L2 incident tests)
- Open: [PHASE1_PRIORITY_AAA_L2.md](./PHASE1_PRIORITY_AAA_L2.md)
- ADCS execution steps: [ADCS_CEREMONY_RUNBOOK.md](./ADCS_CEREMONY_RUNBOOK.md)
- L2 test log template: [L2_INCIDENT_TEST_RESULTS.md](./L2_INCIDENT_TEST_RESULTS.md)

11. Get the NAC-first static IP plan and CML endpoint design
- Open: [NAC_STATIC_IP_PLAN_2026.md](./NAC_STATIC_IP_PLAN_2026.md)

12. Build the new dual-NIC ClearPass libvirt networks
- Open: [CPPM611_DUAL_NIC_NETWORKS_2026.md](./CPPM611_DUAL_NIC_NETWORKS_2026.md)

13. Execute detailed test cases
- Open: [AAA_TEST_CASES_TLS13.md](./AAA_TEST_CASES_TLS13.md)

14. Build a reusable Windows AD template VM
- Open: [WINDOWS_AD_TEMPLATE_VM_GUIDE_2026.md](./WINDOWS_AD_TEMPLATE_VM_GUIDE_2026.md)

15. Acquire ISO/images (free-first, legal-only)
- Open: [ISO_IMAGE_ACQUISITION_GUIDE_2026.md](./ISO_IMAGE_ACQUISITION_GUIDE_2026.md)

16. Access eve-ng SSH from another LAN host (port 2222 forward fix)
- Open: [SSH_FORWARD_EVE_FIX.md](./SSH_FORWARD_EVE_FIX.md)

17. Review publish hardening and the current ClearPass host port map
- Open: [PUBLISHING_SECURITY_AUDIT_2026-04-03.md](./PUBLISHING_SECURITY_AUDIT_2026-04-03.md)
- Open: [CPPM_HOST_PORT_MAP_2026-04-03.md](./CPPM_HOST_PORT_MAP_2026-04-03.md)

---

## Recommended Order (First Time User)

Follow this order:

1. [LAB_SECURITY_AND_VIRT_SUMMARY.md](./LAB_SECURITY_AND_VIRT_SUMMARY.md)
2. [LAB_BUILD_PLAN_PHASED.md](./LAB_BUILD_PLAN_PHASED.md)
3. [LAB_PORTABILITY_PLAYBOOK.md](./LAB_PORTABILITY_PLAYBOOK.md)
4. [TARGET_HOST_PREREQ_IDIOTPROOF.md](./TARGET_HOST_PREREQ_IDIOTPROOF.md)
5. [TARGET_HOST_IMPORT_IDIOTPROOF.md](./TARGET_HOST_IMPORT_IDIOTPROOF.md)

---

## Operational Files (What actually runs)

- Bootstrap runtime script:
  - [bootstrap-lab.sh](./bootstrap-lab.sh)
- Bootstrap installer (creates/enables systemd service):
  - [install-systemd-bootstrap.sh](./install-systemd-bootstrap.sh)
- Startup variables (VM order, delay, network):
  - [lab.env](./lab.env)

Systemd unit created on host:
- `/etc/systemd/system/lab-bootstrap.service`

---

## Minimal Daily Commands

Check VM status:
```bash
virsh -c qemu:///system list --all
```

Use helper command wrapper:
```bash
$REPO_DIR/labctl.sh status
```

Check bootstrap service:
```bash
systemctl status --no-pager lab-bootstrap.service
```

Apply changed startup order:
```bash
sudo systemctl restart lab-bootstrap.service
```

---

## Where your source planning notes are

Prompt helper kept in repo:
- `$REPO_DIR/vm_prompt_01.md`

Private local-only agent session notes are intentionally gitignored and are not part of the publishable repo.

---

## Where libvirtd and eve-ng live (current host)

libvirt service/runtime:
- Systemd unit: `/usr/lib/systemd/system/libvirtd.service` (managed service name: `libvirtd`)
- Host config root: `/etc/libvirt/`
- VM definitions: `/etc/libvirt/qemu/`

Current eve-ng locations:
- VM definition XML: `/etc/libvirt/qemu/eve-ng.xml`
- VM disk image: `/var/lib/libvirt/images/eve-ng.qcow2`
- Boot automation unit using it: `/etc/systemd/system/lab-bootstrap.service`

---

## If you are confused, do this

1. Open this file first: [README_START_HERE.md](./README_START_HERE.md)
2. Then open: [LAB_SECURITY_AND_VIRT_SUMMARY.md](./LAB_SECURITY_AND_VIRT_SUMMARY.md)
3. Then follow the "Recommended Order" section above.
