# CML Windows Endpoint And Windows Server 2025 CA Build (2026-04-05)

Contributors: bermekbukair, Codex

Last updated: 2026-04-05

## What this document is for

This note explains, in plain language, what was done for:

- a Windows endpoint inside Cisco Modeling Labs (CML)
- two separate Windows Server 2025 virtual machines
- the future Microsoft PKI build using one root CA and one issuing CA

It also explains what is already complete, what is still in progress, and what the safest next steps are.

This is written so a non-expert can still understand the main idea.

---

## The simple version

The lab now has:

- one running Windows Server 2022 VM that already exists
- two new Windows Server 2025 VMs created and started
- working access to the CML controller by SSH and web UI

The two new Windows Server 2025 VMs are intended to become:

- `ws2025-rootca01`: the future standalone root CA
- `ws2025-issuingca01`: the future issuing CA

The CML Windows endpoint is not fully finished yet.

What is finished is the groundwork:

- we proved CML controller access works
- we proved where CML stores uploaded image files
- we proved which built-in CML node types can host a custom KVM guest image

What is not finished yet:

- the Windows endpoint image has not been fully uploaded into CML
- the final CML image definition has not been created yet

Updated reality:

- a Windows Server qcow2 was successfully imported into CML storage later
- the image-definition attempt then failed because the chosen built-in `desktop` node path hit an EFI-related limitation
- the large CML-side Server qcow2 was removed again afterward to reclaim storage
- the Windows endpoint task is therefore back in a decision state, not a finished state

---

## Why there are three Windows roles here

There are three separate Windows jobs in this lab design:

1. A Windows endpoint
- This is the machine that will behave like a domain-joined client.
- It is used for realistic tests such as:
  - joining the domain
  - running `gpupdate`
  - auto-enrolling a machine certificate
  - using that certificate for EAP-TLS-style testing

2. A root CA
- This is the top certificate authority.
- It should be kept offline most of the time.
- Its job is mainly to sign the issuing CA certificate and publish revocation data when needed.

3. An issuing CA
- This is the online CA that actually issues certificates to machines and services.
- This is the CA that should issue:
  - machine certificates for EAP-TLS
  - server certificates for RADIUS or RadSec

Keeping these roles separate makes the PKI safer and easier to reason about.

---

## What was discovered on this host

### Local Windows media already exists

No external Microsoft download was needed for the Server 2025 CA builds because this host already had:

- `windows-server-2022-eval.iso`
- `windows-server-2025-eval.iso`

They exist under:

- `/home/hadescloak/Desktop/Projects/lab-control-center/private-media/microsoft/`

### Existing libvirt environment

The host already had these relevant VMs:

- `ws2022-eval01`
- `ws2025-eval01`
- `cml-core01`

The `ws2025-eval01` VM was used as the source template for the two new Server 2025 clones.

### CML controller access works

Confirmed access paths:

- CML UI: `https://192.168.122.210`
- CML console server SSH: port `22`
- CML Linux shell SSH: port `1122`

Confirmed credentials that worked during this build:

- CML Linux shell: `sysadmin`
- CML UI: `admin`

### CML controller storage paths that matter

Confirmed controller paths:

- image upload drop folder: `/var/local/virl2/dropfolder`
- node definitions: `/var/local/virl2/node-definitions`
- main controller database: `/var/local/virl2/config/controller.db`

The important practical finding is:

- `/var/local/virl2/dropfolder` is writable through the `virl2` group path, so it can be used as the image landing zone

---

## What was completed

### 1. Two new Windows Server 2025 VMs were created

The following new VMs were created from the existing `ws2025-eval01` base disk:

- `ws2025-rootca01`
- `ws2025-issuingca01`

They were created as separate libvirt guests and both were started successfully.

### 2. The intended future PKI role split is now clear

Planned role mapping:

- `ws2025-rootca01`
  - future offline standalone root CA
- `ws2025-issuingca01`
  - future online issuing CA

This keeps the future PKI design aligned with a normal two-tier Microsoft AD CS layout.

### 3. The best CML node type for the Windows endpoint was narrowed down

Built-in CML KVM-capable choices inspected:

- `desktop`
- `server`
- `ubuntu`

Best fit for a Windows endpoint image:

- `desktop`

Reason:

- it is already a KVM-backed endpoint-style node
- it has a GUI-oriented endpoint identity in CML
- it is the least confusing fit for a Windows client test box

---

## What is currently in progress

### Exporting a Windows qcow2 for CML

The current working plan is:

1. take a Windows Server 2025 qcow2 from libvirt
2. place a copy on the Ubuntu host
3. upload it into the CML controller drop folder
4. create a CML image definition for it
5. use it as a Windows endpoint inside a CML lab

The first export attempt used:

- `virsh vol-download`

This turned out to be a poor method for this image because it expanded the file heavily on disk.

Observed behavior:

- the exported file kept growing into a large regular file
- this is inefficient for CML import
- it is not the cleanest path for a sparse qcow2 image

At the time of this document, the exported staging file was:

- `/home/hadescloak/ws2025-endpoint.qcow2`

and it had grown substantially.

That first export was later confirmed to be about `66G`, which made it the obvious bad duplicate to delete first if storage became tight.

### Better converted copies later existed

Later host-side copies observed:

- `/home/hadescloak/ws2025-endpoint-fast.qcow2` about `15G`
- `/home/hadescloak/ws2025-endpoint-compact.qcow2` about `734M`

Interpretation:

- the `15G` file is the normal safer working copy
- the `734M` file is suspiciously small for a Windows endpoint and should not be trusted without a real boot test

### What CML did with the uploaded qcow2

Once imported, CML no longer left the file in `/var/local/virl2/dropfolder`.

The actual large managed image file was found at:

- `/var/lib/libvirt/images/virl-base-images/windows-endpoint-2025/ws2025-endpoint-fast.qcow2`

That is the file that was later deleted to reclaim CML storage.

Only a small metadata stub remained under the same managed-image directory afterward.

### What was learned about Windows 11

A Windows 11 ISO was later found locally:

- `/home/hadescloak/Downloads/Win11_25H2_English_x64_v2.iso`

Important conclusion:

- this ISO is not itself a ready CML endpoint image
- Cisco’s CML custom-image flow expects a prepared `.qcow2` image file, not a raw installer ISO, as the uploaded VM image
- Windows 11 is also a worse immediate fit than Server in this exact setup because Windows 11 normally expects UEFI, Secure Boot capability, and TPM 2.0, while the current CML `desktop` attempt already failed on EFI handling alone

### What the later boot investigation proved

After the earlier CML work, a full local boot investigation was performed against the Windows Server endpoint image.

That investigation proved these points:

- the original source VM `ws2025-eval01` is valid and bootable
- the copied image can also be valid and bootable
- the real issue was firmware mismatch, not “the image became small”
- the source Windows Server install is BIOS or legacy boot style
- trying to boot the copied image as a UEFI guest produces the TianoCore “no bootable device” failure
- `virt-install` also silently forced UEFI when `--os-variant win11` was used, even during an attempted BIOS-style test
- the only successful cloned-boot test happened when the copied qcow2 was attached to a manual VM definition based on the original working BIOS-style XML

Known-good endpoint qcow2 after that work:

- `/home/hadescloak/ws2025-endpoint-clean.qcow2`

Meaning:

- this is now the safest candidate for any later CML retry

Known-bad or untrusted copies:

- `/home/hadescloak/ws2025-endpoint-fast.qcow2`
  - not trusted anymore for serious reuse
- `/home/hadescloak/ws2025-endpoint-compact.qcow2`
  - suspiciously small and not boot-proven

---

## What still needs to be done

### Immediate next steps

The next safe sequence is:

1. clean up duplicates first
- delete the `66G` bad export copy before creating or uploading anything else

2. choose one path only
- either keep troubleshooting with one Windows Server qcow2
- or build exactly one Windows 11 qcow2 from the ISO

3. do not treat the Windows 11 ISO as a ready CML node
- it still needs to be installed into a qcow2 first

4. if retrying Server first, prefer the known `15G` qcow2
- do not keep multiple large host-side duplicates unless a rollback reason exists

5. if retrying in CML, expect that `desktop` plus EFI may still not be enough
- the real fix may require a different node definition path, not just another image definition

6. do not retry CML with `EFI Boot ON` for this Windows Server qcow2
- the later host-side proof showed the image is BIOS-installed
- any retry should respect that fact

### What happened in the next CML retry

The known-good qcow2:

- `/home/hadescloak/ws2025-endpoint-clean.qcow2`

was uploaded and imported into CML under:

- image definition `windows-endpoint-2025-clean`

The first retry deliberately used:

- `EFI Boot` disabled
- built-in node definition `desktop`

That was enough to move past the old UEFI failure.

Observed result:

- the node now booted under SeaBIOS
- Windows then crashed with `INACCESSIBLE_BOOT_DEVICE`
- automatic repair screens appeared afterward

Interpretation:

- the firmware problem was fixed
- the remaining problem was storage or NIC hardware mismatch

Comparing the working libvirt VM against the CML built-in `desktop` node made the difference clear:

- working libvirt VM: `sata` disk, `e1000` NIC
- CML `desktop`: `virtio` disk, `virtio` NIC

To address that, a custom CML node definition was created on the controller:

- `/var/local/virl2/node-definitions/windows-bios-desktop.yaml`

It intentionally uses:

- `disk_driver: sata`
- `nic_driver: e1000`

The existing clean image definition was then repointed to this new node definition instead of creating another duplicate qcow2 or duplicate image definition.

### Follow-up correction

During the first controller-side DB adjustment, the original lab node `desktop-0` was mistakenly repointed away from Alpine and toward the Windows endpoint.

That was corrected afterward:

- `desktop-0` was restored to the normal Alpine desktop image
- a separate new lab node `win-endpoint-0` was added
- the Windows BIOS node-definition and image-definition mapping was moved onto `win-endpoint-0`
- a dedicated deployment record was then created for `win-endpoint-0`

This restored the intended separation:

- original Tiny Linux desktop stays original
- Windows endpoint stays separate

### Final node-definition registration lesson

One more important detail was discovered after the custom `windows-bios-desktop` YAML had been created on disk.

Finding:

- CML 2.9.1 did not accept the custom node definition merely because the YAML file existed in `/var/local/virl2/node-definitions`
- the backend returned `Node Definition not found: windows-bios-desktop`

The successful fix was:

- register the custom node definition through CML's supported API
- this was done by using the controller's bundled `virl2_client` library and uploading the YAML definition programmatically as the admin user

After that:

- CML reported `CREATE_RESULT: Success`
- the custom node definition became valid to the backend

This means the real rule is:

- node-definition YAML on disk is not enough by itself
- proper controller registration is required

### Current boot milestone in CML

After all of the following were corrected:

- firmware mode mismatch
- CML disk and NIC hardware mismatch
- custom node-definition registration
- stale runtime domain reuse
- missing or inconsistent `node_deployment` and `network_device` rows

the Windows endpoint reached a materially better state.

Observed result:

- it no longer immediately falls into `INACCESSIBLE_BOOT_DEVICE`
- it proceeds into Windows hardware initialization
- the screen shows `Getting devices ready`

Interpretation:

- the endpoint is now far closer to the original working hardware profile
- the CML endpoint path appears viable
- the remaining task is to let Windows finish booting and confirm the final login-ready state
- use it later as the domain-join and certificate-autoenrollment test endpoint

### After the image exists in CML

Then the Windows endpoint work becomes:

1. boot the Windows endpoint in CML
2. give it reachability to the AD/DNS/issuing CA services
3. join it to the domain
4. run `gpupdate`
5. confirm machine certificate enrollment
6. use it for EAP-TLS testing

---

## Why a Windows Server image is being used as the endpoint image

There was no Windows desktop ISO already present in the local media store.

What was available:

- Windows Server 2022 evaluation ISO
- Windows Server 2025 evaluation ISO

That means the fastest practical endpoint image is:

- a Windows Server 2025 guest used as a client-style endpoint

This is acceptable for the lab goal because the important behaviors to test are:

- domain join
- Group Policy processing
- certificate autoenrollment
- EAP-TLS style machine-certificate behavior

For those tests, a Windows Server guest can still prove the workflow.

It is not a perfect replacement for a normal Windows desktop client, but it is good enough to validate the PKI and enrollment path.

---

## Layman explanation of the current blocker

The problem is not that CML cannot run Windows.

CML can run a Windows VM image as a custom image.

The problem is simply this:

- the Windows disk image needs to be moved into CML in the right format
- the first copy method was wasteful
- the final CML image registration step still needs to be completed

So this is mostly an image-handling problem, not a design problem.

---

## Practical commands and objects already confirmed

### New CA VMs

- `ws2025-rootca01`
- `ws2025-issuingca01`

### Existing source VM used for cloning

- `ws2025-eval01`

### CML controller

- host: `192.168.122.210`
- Linux shell SSH: `1122`
- upload landing folder: `/var/local/virl2/dropfolder`

### Best CML node-definition target for the custom Windows endpoint

- `desktop`

---

## Recommended next operator action

Continue with:

1. stop the current large `virsh vol-download`
2. build a smaller and cleaner qcow2 export
3. copy it into CML drop folder
4. register it against the `desktop` node definition

That is the cleanest path from the current state.

---

## Later design correction: use a lighter Windows client, not only Server

The earlier Windows Server endpoint work was still useful because it proved:

- CML custom Windows images are viable
- the real problems were firmware and virtual hardware matching
- CML node-definition behavior matters more than the Windows family name

But the user explicitly wanted a lighter endpoint and wanted to avoid Server edition if possible.

### Official client media actually used

The public Windows 10 LTSC evaluation path was no longer reliable and redirected away.

So the lighter official client image that was actually obtained was:

- `Windows 11 IoT Enterprise LTSC Evaluation`

Exact ISO:

- `/home/hadescloak/Downloads/26100.1742.240906-0331.ge_release_svc_refresh_CLIENT_IOT_LTSC_EVAL_x64FRE_en-us.iso`

### Why the install was done on local libvirt first

Installing Windows directly inside CML is possible in theory, but it is the worse operator experience.

The safer workflow is:

1. install the client OS on local libvirt
2. verify it reaches a real Windows desktop
3. shut it down cleanly
4. detach the ISO
5. boot-test from disk only
6. import the finished qcow2 into CML

Why:

- Windows setup itself is simpler outside CML
- this avoids mixing installer problems with CML node-definition problems
- it also avoids creating unnecessary duplicate qcow2 files

### Local Windows IoT LTSC build result

Final local disk:

- `/home/hadescloak/win-endpoint-client.qcow2`

Observed shape:

- `64G` virtual size
- about `11.9G` real disk usage after install

VM used during installation:

- `win-endpoint-client-install`

Working hardware profile during local install:

- UEFI
- TPM 2.0
- `q35`
- SATA system disk
- `e1000` NIC
- QXL video

Observed success milestone:

- Windows desktop was reached successfully

That means:

- the local client image is valid
- it is a better long-term endpoint candidate than the heavier Windows Server image

### Controller-side staging result

The finished client qcow2 was uploaded to the CML controller.

Practical upload flow used:

1. upload into:
   - `/var/tmp/win-endpoint-client.qcow2`
2. move with `sudo` into:
   - `/var/local/virl2/dropfolder/win-endpoint-client.qcow2`

Reason:

- direct write to the dropfolder as `sysadmin` was denied
- `/var` had enough free space

Current staged CML import file:

- `/var/local/virl2/dropfolder/win-endpoint-client.qcow2`

### Engineering implication

At this point there are now two distinct Windows endpoint tracks in the lab:

1. BIOS-style Windows Server endpoint work, useful for understanding CML custom hardware matching
2. UEFI-based Windows 11 IoT LTSC client image, which is the better non-Server endpoint candidate

The next meaningful question is no longer “can Windows run in CML?”

That has already been proven.

The next question is:

- which CML node-definition and image-definition combination cleanly boots the UEFI-based Windows 11 IoT LTSC client image
