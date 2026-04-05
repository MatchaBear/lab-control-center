# CML Windows Endpoint Idiot-Proof Runbook (2026-04-05)

Contributors: bermekbukair, Codex

Last updated: 2026-04-05

## What this file is

This is the blind-follow manual for putting a Windows guest image into CML and using it as a Windows endpoint.

This file is written for someone who does not want to think too much and just wants:

- the exact order
- what each step means
- what to expect after each step

If you want the background and design explanation, read:

- [CML_WINDOWS_ENDPOINT_AND_WS2025_CA_BUILD_2026-04-05.md](./CML_WINDOWS_ENDPOINT_AND_WS2025_CA_BUILD_2026-04-05.md)

---

## Goal

End result:

- a Windows image file exists inside the CML controller
- CML knows about that image
- you can add a Windows endpoint node in a CML lab

In this lab, that Windows endpoint is meant to later do:

- domain join
- `gpupdate`
- machine certificate enrollment
- EAP-TLS style testing

Important safety rule:

- this runbook is meant to add a new Windows-backed image definition
- this runbook is not meant to replace or edit the built-in Tiny Linux `Desktop`
- if done correctly, the original CML `Desktop` remains available
- your Windows endpoint appears as a separate option

---

## Before you start

You need:

- Ubuntu host running libvirt
- CML controller reachable
- a Windows qcow2 image ready on the Ubuntu host
- CML controller credentials

Known values for this lab:

- CML UI: `https://192.168.122.210`
- CML Linux shell SSH: port `1122`
- CML image landing folder: `/var/local/virl2/dropfolder`
- preferred CML node definition for this Windows endpoint: `desktop`

Known current working image filename for this lab:

- `ws2025-endpoint-fast.qcow2`

Important reality check:

- CML custom images are based on a prepared `.qcow2` disk image
- a raw Windows installer `.iso` is not itself the final CML node image
- if you want Windows 11 in CML, you still need to install it into a qcow2 first

Important Windows 11 warning:

- Windows 11 normally expects UEFI, Secure Boot capability, and TPM 2.0
- in this lab, the built-in `desktop` node type already failed on EFI handling
- because of that, Windows 11 is a worse first choice than Windows Server for quick endpoint testing in this exact CML setup

---

## Simple picture of what you are doing

You are doing four big things:

1. prepare a Windows qcow2 image
- Meaning: make the Windows disk image small and usable

2. upload the image to the CML controller
- Meaning: copy the file onto the CML server

3. move the image into CML’s import folder
- Meaning: put the file where CML expects uploaded images to live

4. create the image definition in CML
- Meaning: tell CML what kind of node this file belongs to

Only after step 4 can you add the Windows endpoint in a CML lab.

Very important:

- do not keep making duplicate qcow2 files unless there is a very clear reason
- large duplicate files will eat host storage fast
- keep one known-good qcow2 whenever possible

---

## Step-by-step instructions

### Step 1. Confirm the Windows source VM exists

Example:

```bash
virsh list --all
```

What this means:

- This checks whether the Windows source VM is present on the Ubuntu host.

What you want to see:

- the source VM name exists, for example `ws2025-eval01`

---

### Step 2. Export or copy the Windows qcow2 to your home directory

Example output file:

- `/home/hadescloak/ws2025-endpoint.qcow2`

What this means:

- This creates a host-side working copy of the Windows image so you do not touch the original libvirt image directly.

Important note:

- A plain `virsh vol-download` may bloat the file badly.
- If that happens, do not panic.
- You can still convert it into a better qcow2 afterward.

---

### Step 3. Convert the exported image into a better qcow2

Recommended command:

```bash
qemu-img convert -p -O qcow2 /home/hadescloak/ws2025-endpoint.qcow2 /home/hadescloak/ws2025-endpoint-fast.qcow2
```

What this means:

- This rewrites the Windows disk into a cleaner qcow2 file that is easier to upload and use.

What you want to see:

- the command reaches `100.00/100%`

Check the result:

```bash
qemu-img info /home/hadescloak/ws2025-endpoint-fast.qcow2
```

What this means:

- This confirms the new image is valid.

What you want to see:

- `file format: qcow2`
- no corruption

---

### Step 4. Check free space on the CML controller

Command:

```bash
ssh -p 1122 sysadmin@192.168.122.210 'df -h / /var /home'
```

What this means:

- This checks where the CML controller actually has room for the upload.

Important note:

- On this lab, `/home` is too small and may fill up.
- `/var` has the useful free space.

So:

- do not upload the big file into `/home/sysadmin`
- upload it into `/var/tmp` instead

---

### Step 5. Upload the finished qcow2 into `/var/tmp` on the CML controller

Example:

```bash
scp -P 1122 /home/hadescloak/ws2025-endpoint-fast.qcow2 sysadmin@192.168.122.210:/var/tmp/ws2025-endpoint-fast.qcow2
```

What this means:

- This copies the final Windows qcow2 onto the CML controller in a filesystem that has enough space.

What you want to see:

- the file appears on the controller

Check it:

```bash
ssh -p 1122 sysadmin@192.168.122.210 'ls -lh /var/tmp/ws2025-endpoint-fast.qcow2'
```

What this means:

- This confirms the uploaded file is really there.

---

### Step 6. Move the uploaded image into the CML drop folder

Example:

```bash
ssh -p 1122 sysadmin@192.168.122.210
sudo mv /var/tmp/ws2025-endpoint-fast.qcow2 /var/local/virl2/dropfolder/
sudo ls -lh /var/local/virl2/dropfolder/ws2025-endpoint-fast.qcow2
```

What this means:

- This places the image into CML’s official upload/import folder.

Why `sudo` is needed:

- the drop folder is under CML system ownership

Important note:

- after CML processes the upload, the qcow2 may move out of the drop folder into CML’s managed image store
- that is normal
- if you later want to reclaim space, deleting only from the drop folder is not enough if CML already imported it

---

### Step 7. Open the CML web UI

Open:

- `https://192.168.122.210`

Log in with the CML admin account.

What this means:

- You are now using the normal CML management interface instead of only the Linux shell.

---

### Step 8. Go to image upload management

Look for the page that manages image uploads and image definitions.

In this CML build, the relevant UI areas are:

- uploaded image files
- image definitions

What this means:

- This is where CML shows files already placed into its drop folder and lets you turn them into usable node images.

---

### Step 9. Confirm the uploaded qcow2 appears in CML

You want to see:

- `ws2025-endpoint-fast.qcow2`

What this means:

- CML can see the file and is ready for image-definition work.

If you do not see it:

- refresh the page
- confirm the file is really in `/var/local/virl2/dropfolder`

---

### Step 10. Create the image definition

Use these values as the starting point:

- Node Definition: `desktop`
- Disk Image: `ws2025-endpoint-fast.qcow2`
- Label: something obvious like `Windows Endpoint`
- ID: something obvious like `windows-endpoint-2025`

What this means:

- This tells CML that your qcow2 belongs to a KVM endpoint-style node.

Why `desktop`:

- It is the cleanest built-in endpoint-style node choice found during this build.

Very important:

- you are creating a new image definition that uses the built-in `desktop` node type
- you are not editing the built-in `desktop` node definition itself

Think of it this way:

- built-in `desktop` node definition = the machine shape and boot style
- your new image definition = the actual Windows disk file that shape boots

So after this:

- old Tiny Linux `Desktop` still exists
- new Windows endpoint also exists

They are separate.

---

### Step 10A. Exact GUI path

Open the CML UI and go to:

- `Tools`
- `Node and Image Definitions`

What this means:

- this is the page where CML manages uploaded qcow2 files and the definitions that turn them into selectable lab nodes

What you want to see:

- an uploaded images section
- an image definitions section
- a button or action to create a new image definition

---

### Step 10B. Confirm the uploaded file is visible

Look for this uploaded filename:

- `ws2025-endpoint-fast.qcow2`

What this means:

- CML can see the qcow2 file in its drop folder

If it is not visible:

- refresh the page
- verify the file still exists in `/var/local/virl2/dropfolder`

Do not continue until this file appears.

---

### Step 10C. Fill in the new image definition

When you create the new image definition, use values like these:

- `ID`
  - Example: `windows-endpoint-2025`
  - Meaning: the internal unique name for this image definition

- `Label`
  - Example: `Windows Endpoint 2025`
  - Meaning: the human-friendly name you will see in CML when selecting nodes

- `Description`
  - Example: `Windows Server 2025 based endpoint for domain join, gpupdate, and certificate autoenrollment tests`
  - Meaning: a note so future-you remembers what this image is for

- `Node Definition`
  - Value: `desktop`
  - Meaning: tell CML to treat this as an endpoint-style KVM node

- `Disk Image`
  - Value: `ws2025-endpoint-fast.qcow2`
  - Meaning: tell CML which uploaded qcow2 file to boot

- `RAM`
  - Suggested start: `4096` or `6144`
  - Meaning: memory assigned to the Windows endpoint

- `CPUs`
  - Suggested start: `2`
  - Meaning: number of virtual CPU cores

- `CPU Limit`
  - Leave default unless you have a reason
  - Meaning: restricts how much CPU the node can consume

- `Boot Disk Size`
  - Leave default unless CML requires otherwise
  - Meaning: virtual boot disk capacity presented to the node definition

Use the smallest settings that still boot Windows reliably.

---

### Step 10D. What not to do

Do not do these things:

- do not rename or edit the built-in `desktop` node definition
- do not delete the built-in `Desktop` image definition
- do not reuse the Alpine disk image entry
- do not choose the wrong qcow2 filename

If you do any of those, you risk breaking the default Linux endpoint behavior.

---

### Step 10E. What success looks like

After saving the new image definition:

- the new Windows image definition appears in the definitions list
- the original Tiny Linux `Desktop` still appears too
- both are visible as separate choices

That is the expected good outcome.

---

### Step 11. Save the image definition

What this means:

- This is the step that makes the uploaded image actually usable as a node type in a lab.

What you want to see:

- no error from CML
- the new image definition is visible in the image-definition list

---

### Step 12. Add the Windows node to a CML lab

Now go into a lab and add the node using the new image definition.

What this means:

- This is the first point where the Windows image becomes a usable endpoint inside the CML topology.

What you should expect:

- you should see a separate Windows endpoint label, not just the original Alpine `Desktop`
- if you only see the original `Desktop`, the new image definition was not created correctly yet

---

## If something goes wrong

### Problem: upload to `/home/sysadmin` fails

Meaning:

- the controller root filesystem is full

Fix:

- upload to `/var/tmp` instead

### Problem: file is in CML drop folder but not visible in UI

Meaning:

- CML has not refreshed the drop folder list yet

Fix:

- refresh the image-management page
- verify the filename in `/var/local/virl2/dropfolder`

### Problem: image definition saves but node does not boot

Meaning:

- the node definition type may not match the image behavior well enough

Fix:

- try the same qcow2 again against `desktop` first
- if needed later, test `server` as a fallback

### Problem: Windows 11 ISO sounds attractive, but may still be the wrong next step

Meaning:

- Windows 11 is not just “newer Windows”
- it usually needs stricter boot features than Windows Server

Fix:

- do not assume the ISO can be dropped straight into CML
- expect to build one qcow2 from the ISO first
- prefer the Windows Server qcow2 route first if your goal is domain join, `gpupdate`, and certificate tests

---

## What each important path means

- `/home/hadescloak/ws2025-endpoint.qcow2`
  - the first exported Windows image copy on the Ubuntu host

- `/home/hadescloak/ws2025-endpoint-fast.qcow2`
  - the improved qcow2 made for CML upload

- `/var/tmp/ws2025-endpoint-fast.qcow2`
  - the temporary upload landing point on the CML controller

- `/var/local/virl2/dropfolder`
  - the folder CML watches for uploaded image files

- `/var/lib/libvirt/images/virl-base-images/windows-endpoint-2025/ws2025-endpoint-fast.qcow2`
  - the actual large managed image file once CML has imported the Windows qcow2

---

## Short answer to “When can I add the Windows node in CML?”

You can add the Windows node only after all of these are true:

1. the qcow2 is uploaded to the controller
2. the qcow2 is moved into `/var/local/virl2/dropfolder`
3. the CML image definition is created successfully

If step 3 is not done yet, you are not ready yet.

---

## Current checkpoint for this exact lab

At the current point in this build:

- the built-in `desktop` node definition has not been modified
- the Windows Server image definition attempt failed on EFI handling
- the large CML-managed Windows Server qcow2 was later removed again to reclaim space
- a tiny metadata stub may still remain, but the large disk file is the part that mattered for storage
- a Windows 11 ISO is present locally, but it is not a ready-to-use CML endpoint by itself

So right now:

- the drag-and-drop Windows node is not ready
- the big CML-side Server qcow2 is no longer consuming space
- the next decision is whether to keep troubleshooting a single Server qcow2 or build exactly one Windows 11 qcow2

It becomes ready only after the image definition is created successfully.

---

## Current best next action

If you are continuing from the current build:

1. do not upload anything else yet
2. keep storage under control by deleting obvious duplicate qcow2 files first
3. decide whether you want to continue with one Windows Server qcow2 or build one Windows 11 qcow2
4. only after that should you create a fresh CML image path again

---

## Cleanup section

Use this section if you want to free space after a failed Windows endpoint attempt.

### Cleanup 1. Remove the CML-managed Windows qcow2

Example:

```bash
ssh -p 1122 sysadmin@192.168.122.210
echo 'PASSWORD' | sudo -S rm -f /var/lib/libvirt/images/virl-base-images/windows-endpoint-2025/ws2025-endpoint-fast.qcow2
```

What this means:

- This deletes the big Windows disk from the CML controller so it stops consuming CML storage.

### Cleanup 2. Delete the obvious bad local export copy first

Bad copy seen in this lab:

- `/home/hadescloak/ws2025-endpoint.qcow2`

What this means:

- This was the bloated first export copy and consumed about `66G`.

### Cleanup 3. Be careful with the very small compact copy

Observed compact file:

- `/home/hadescloak/ws2025-endpoint-compact.qcow2`

What this means:

- It is unusually small for a Windows disk and should not be trusted blindly without a real boot test.

Safe rule:

- if you want a safer reusable copy, keep the `15G` `ws2025-endpoint-fast.qcow2`
- if you need to free space immediately, delete the `66G` file first

---

## Full troubleshooting log: steps 1 to 38

This section is the literal practical path that was followed in this lab.

It is written so someone can repeat the same investigation in the same order without guessing.

### Step 1. Confirm the first qcow2 exists

Command:

```bash
qemu-img info /home/hadescloak/ws2025-endpoint-fast.qcow2
```

What this means:

- confirm the qcow2 exists and is readable

Observed result:

- qcow2 was valid on disk
- virtual size was `80 GiB`
- disk size was about `14.9 GiB`
- no corruption was shown

### Step 2. Create a temporary boot-test VM from the `fast` qcow2

Command:

```bash
virt-install \
  --name ws2025-endpoint-test \
  --memory 4096 \
  --vcpus 2 \
  --cpu host \
  --import \
  --disk path=/home/hadescloak/ws2025-endpoint-fast.qcow2,format=qcow2,bus=virtio \
  --os-variant win11 \
  --network network=default,model=virtio \
  --graphics spice \
  --video virtio \
  --noautoconsole
```

What this means:

- create a temporary VM from the copied qcow2 without making another disk copy

Observed result:

- VM definition was created successfully

### Step 3. Open the test VM console

Command:

```bash
virt-viewer --connect qemu:///system ws2025-endpoint-test
```

What this means:

- see whether Windows boots or not

Observed result:

- TianoCore UEFI screen
- no bootable device found

Lesson:

- the qcow2 did not boot in that VM definition

### Step 4. Remove the first failed test VM

Commands:

```bash
virsh destroy ws2025-endpoint-test
virsh undefine ws2025-endpoint-test
```

Observed result:

- `undefine` failed first because the VM had UEFI NVRAM

### Step 5. Remove the same test VM correctly

Command:

```bash
virsh undefine ws2025-endpoint-test --nvram
```

What this means:

- remove the temporary UEFI VM definition completely

### Step 6. Check the real source disk attached to the original source VM

Command:

```bash
virsh domblklist ws2025-eval01
```

Observed result:

- real source disk was `/var/lib/libvirt/images/ws2025-eval01.qcow2`
- installer ISO was attached separately

### Step 7. Inspect the real source disk

Command:

```bash
sudo qemu-img info /var/lib/libvirt/images/ws2025-eval01.qcow2
```

Observed result:

- source disk was valid
- virtual size `80 GiB`
- disk size about `15.7 GiB`

### Step 8. Check the source VM power state

Command:

```bash
virsh dominfo ws2025-eval01
```

Observed result:

- source VM was shut off

### Step 9. Start the source VM

Command:

```bash
virsh start ws2025-eval01
```

What this means:

- test whether the original source VM itself is actually bootable

### Step 10. Open the source VM console

Command:

```bash
virt-viewer --connect qemu:///system ws2025-eval01
```

Observed result:

- Windows lock screen appeared

Lesson:

- the original source disk and source VM were good

### Step 11. Shut down the source VM cleanly

Command:

```bash
virsh shutdown ws2025-eval01
```

### Step 12. Wait for the source VM to fully stop

Command:

```bash
virsh dominfo ws2025-eval01
```

Observed result:

- state became `shut off`

### Step 13. Make one fresh clean copy directly from the real source disk

Command:

```bash
sudo qemu-img convert -p -O qcow2 /var/lib/libvirt/images/ws2025-eval01.qcow2 /home/hadescloak/ws2025-endpoint-clean.qcow2
```

What this means:

- create a fresh qcow2 directly from the known-good source disk

### Step 14. Inspect the new clean copy

Command:

```bash
qemu-img info /home/hadescloak/ws2025-endpoint-clean.qcow2
```

Observed result:

- new clean qcow2 was valid
- disk size about `15.7 GiB`

### Step 15. Boot-test the clean copy using the same temporary UEFI-style path

Command:

```bash
virt-install \
  --name ws2025-endpoint-clean-test \
  --memory 4096 \
  --vcpus 2 \
  --cpu host \
  --import \
  --disk path=/home/hadescloak/ws2025-endpoint-clean.qcow2,format=qcow2,bus=virtio \
  --os-variant win11 \
  --network network=default,model=virtio \
  --graphics spice \
  --video virtio \
  --noautoconsole
```

Observed result:

- VM definition was created successfully

### Step 16. Open the clean-copy test VM console

Command:

```bash
virt-viewer --connect qemu:///system ws2025-endpoint-clean-test
```

Observed result:

- same TianoCore UEFI no-boot error appeared

Lesson:

- the problem was not specific to the earlier `fast` copy

### Step 17. Check the original source VM firmware type

Command:

```bash
virsh dumpxml ws2025-eval01 | sed -n '/<os>/,/<\/os>/p'
```

Observed result:

- source VM had no EFI section
- source VM used legacy BIOS-style boot

Lesson:

- earlier test VMs were wrongly using UEFI against a BIOS-installed Windows disk

### Step 18. Remove the failed clean-copy UEFI test VM

Commands:

```bash
virsh destroy ws2025-endpoint-clean-test
virsh undefine ws2025-endpoint-clean-test --nvram
```

### Step 19. Try a BIOS-style test with `virt-install`

Command first attempted:

```bash
virt-install \
  --name ws2025-endpoint-bios-test \
  --memory 4096 \
  --vcpus 2 \
  --cpu host \
  --import \
  --boot hd,bootmenu=on \
  --disk path=/home/hadescloak/ws2025-endpoint-clean.qcow2,format=qcow2,bus=sata \
  --os-variant win11 \
  --network network=default,model=e1000 \
  --graphics spice \
  --video qxl \
  --noautoconsole
```

Observed result:

- syntax error because this `virt-install` expected `menu=on` instead of `bootmenu=on`

Second attempt:

```bash
virt-install \
  --name ws2025-endpoint-bios-test \
  --memory 4096 \
  --vcpus 2 \
  --cpu host \
  --import \
  --boot hd,menu=on \
  --disk path=/home/hadescloak/ws2025-endpoint-clean.qcow2,format=qcow2,bus=sata \
  --os-variant win11 \
  --network network=default,model=e1000 \
  --graphics spice \
  --video qxl \
  --noautoconsole
```

Observed result:

- VM definition was created successfully

### Step 20. Open the BIOS-style `virt-install` test VM

Command:

```bash
virt-viewer --connect qemu:///system ws2025-endpoint-bios-test
```

Observed result:

- it still booted to TianoCore UEFI and failed

Lesson:

- `virt-install` silently forced EFI because `--os-variant win11` was used

### Step 21. Prove the test VM was still EFI

Command:

```bash
virsh dumpxml ws2025-endpoint-bios-test
```

Observed result:

- XML showed `<os firmware='efi'>`
- secure boot and EFI loader entries existed

### Step 22. Remove the wrongly-created EFI test VM

Commands:

```bash
virsh destroy ws2025-endpoint-bios-test
virsh undefine ws2025-endpoint-bios-test --nvram
```

### Step 23. Export the original working VM definition

Command:

```bash
virsh dumpxml ws2025-eval01 > /home/hadescloak/ws2025-eval01.xml
```

What this means:

- use the original working BIOS-style VM definition as the template

### Step 24. Open the XML template in `nano`

Command:

```bash
nano /home/hadescloak/ws2025-eval01.xml
```

### Step 25. Change the VM name

Changed from:

```xml
<name>ws2025-eval01</name>
```

Changed to:

```xml
<name>ws2025-endpoint-manual-test</name>
```

### Step 26. Change the disk source path

Changed from:

```xml
<source file='/var/lib/libvirt/images/ws2025-eval01.qcow2' .../>
```

Changed to:

```xml
<source file='/home/hadescloak/ws2025-endpoint-clean.qcow2' .../>
```

### Step 27. Remove the attached ISO CD-ROM disk block

What this means:

- delete the entire `<disk ...>` block that referenced the installer ISO

### Step 28. Save and exit `nano`

Keys:

- `Ctrl+O`, `Enter`
- `Ctrl+X`

### Step 29. Define the new VM from XML

Command:

```bash
virsh define /home/hadescloak/ws2025-eval01.xml
```

Observed result:

- failed because the old UUID was still present

### Step 30. Reopen the XML

Command:

```bash
nano /home/hadescloak/ws2025-eval01.xml
```

### Step 31. Delete the old UUID line

Deleted:

```xml
<uuid>...</uuid>
```

What this means:

- let libvirt generate a fresh VM identity

### Step 32. Save and exit again

Keys:

- `Ctrl+O`, `Enter`
- `Ctrl+X`

### Step 33. Define the VM again

Command:

```bash
virsh define /home/hadescloak/ws2025-eval01.xml
```

Observed result:

- new VM `ws2025-endpoint-manual-test` defined successfully

### Step 34. Start the manual test VM

Command:

```bash
virsh start ws2025-endpoint-manual-test
```

### Step 35. Open the manual test VM console

Command:

```bash
virt-viewer --connect qemu:///system ws2025-endpoint-manual-test
```

Observed result:

- Windows lock screen appeared

Main lesson:

- the clean copied qcow2 is valid and bootable
- the deciding factor was matching the original BIOS-style VM definition

### Step 36. Shut down the successful manual test VM

Command:

```bash
virsh shutdown ws2025-endpoint-manual-test
```

### Step 37. Wait for it to fully stop

Command:

```bash
virsh dominfo ws2025-endpoint-manual-test
```

Observed result:

- state became `shut off`

### Step 38. Remove the temporary manual test VM definition

Command:

```bash
virsh undefine ws2025-endpoint-manual-test
```

What this means:

- remove only the temporary VM definition
- keep the good qcow2 file

---

## Final conclusion from steps 1 to 38

The correct conclusion is:

- the image did not fail because it became small
- the image failed when booted under the wrong firmware style
- this Windows Server disk was installed as BIOS or legacy boot, not UEFI
- `EFI Boot ON` is therefore the wrong direction for this qcow2
- the current best endpoint image is:

`/home/hadescloak/ws2025-endpoint-clean.qcow2`

The unsafe images are:

- `/home/hadescloak/ws2025-endpoint-fast.qcow2`
  - not trusted for serious use anymore

- `/home/hadescloak/ws2025-endpoint-compact.qcow2`
  - too unusual to trust without its own separate boot proof

---

## Follow-up: first CML retry after the BIOS discovery

This section records what happened after the good BIOS-style qcow2 was imported back into CML.

### What was imported

The only trusted image used for the retry was:

- `/home/hadescloak/ws2025-endpoint-clean.qcow2`

It was uploaded to the controller and moved into:

- `/var/local/virl2/dropfolder/ws2025-endpoint-clean.qcow2`

After CML created the managed image, it was stored under:

- `/var/lib/libvirt/images/virl-base-images/windows-endpoint-2025-clean/ws2025-endpoint-clean.qcow2`

### First retry image definition

The first clean retry used:

- image definition ID: `windows-endpoint-2025-clean`
- node definition: `desktop`
- `EFI Boot`: `OFF`

This was the correct direction compared with the earlier bad EFI attempt.

### Result of the first clean retry in CML

Observed result:

- the node started in SeaBIOS, not UEFI
- Windows reached boot and then crashed with `INACCESSIBLE_BOOT_DEVICE (0x7B)`
- Windows recovery screens then appeared

Meaning:

- firmware mode was now basically correct
- the remaining problem was not UEFI anymore
- the remaining problem was virtual hardware mismatch

### What mismatch was identified

The working original libvirt VM used:

- disk bus: `sata`
- NIC model: `e1000`

The built-in CML `desktop` node definition used:

- `disk_driver: virtio`
- `nic_driver: virtio`

That difference explains the `INACCESSIBLE_BOOT_DEVICE` crash:

- Windows could boot in BIOS mode
- but the CML `desktop` node presented a storage controller that this Windows install did not have as its boot driver

### Corrective action taken

A new custom node definition was added on the CML controller:

- `/var/local/virl2/node-definitions/windows-bios-desktop.yaml`

Important properties of this custom node definition:

- based on the `desktop` shape
- `disk_driver: sata`
- `nic_driver: e1000`
- intended specifically for legacy-BIOS Windows endpoint images

### Existing image definition was repointed

Instead of uploading another qcow2 or creating another duplicate image, the existing clean image definition was updated to use the new custom node definition.

Changed file:

- `/var/lib/libvirt/images/virl-base-images/windows-endpoint-2025-clean/windows-endpoint-2025-clean.yaml`

Changed key:

- from `node_definition_id: desktop`
- to `node_definition_id: windows-bios-desktop`

### What to do after this change

Important:

- do not keep using the already-crashed node instance in the lab
- that existing lab node may still hold the old hardware profile

Correct next action:

1. stop the existing crashed node
2. delete that node from the lab canvas
3. refresh the CML UI if needed
4. add a brand new node using image definition `Windows Endpoint 2025 Clean`
5. start that new node

Reason:

- a fresh lab node is the safest way to ensure CML applies the new node definition hardware

### Important correction after that first attempt

The first controller-side DB edit accidentally changed the original existing `desktop-0` node in the lab.

That was wrong because:

- `desktop-0` was the user's original Tiny Linux desktop
- it should not have been repurposed into the Windows endpoint

What was done to fix that mistake:

1. `desktop-0` was restored back to:
   - node definition `desktop`
   - image definition `alpine-desktop-3-21-3`

2. a brand new lab node named:
   - `win-endpoint-0`
   was added by the user

3. the Windows BIOS mapping was moved onto `win-endpoint-0` instead:
   - node definition `windows-bios-desktop`
   - image definition `windows-endpoint-2025-clean`

4. a matching `node_deployment` record was created for `win-endpoint-0`

Meaning:

- the original Tiny Linux desktop remains original
- the Windows endpoint is now isolated on its own separate lab node

### Important final discovery about custom node definitions in CML 2.9.1

Just placing a YAML file in:

- `/var/local/virl2/node-definitions/`

was not enough.

Why:

- the controller backend still rejected the custom ID with:
  - `Node Definition not found: windows-bios-desktop`

What was finally required:

- register the custom node definition through CML's supported API
- not just by dropping YAML on disk

Supported method that was used:

- the controller's bundled `virl2_client` library
- authenticated as the CML admin user
- uploaded the YAML definition with `upload_node_definition(...)`

Observed result:

- `CREATE_RESULT: Success`
- the controller then recognized `windows-bios-desktop` as a real node definition

Meaning:

- file on disk alone is not sufficient
- proper API registration is required for the backend to accept the custom node type

### Current working milestone

After fixing:

- the BIOS versus UEFI mismatch
- the wrong `virtio` hardware profile
- the custom node-definition registration
- the broken `node_deployment` and `network_device` database rows

the Windows endpoint in CML finally moved past the earlier failures.

Observed improvement:

- it no longer immediately crashes with `INACCESSIBLE_BOOT_DEVICE`
- it now reaches the Windows setup or boot phase showing:
  - `Getting devices ready`

Meaning:

- CML is now close enough to the original working libvirt hardware profile for Windows to continue booting
- this is the strongest sign so far that the Windows endpoint path is viable

Important:

- do not interrupt the node while it is on `Getting devices ready`
- do not wipe it
- allow Windows time to finish hardware detection and any automatic reboot it decides to do

---

## New lighter client path: Windows 11 IoT Enterprise LTSC

After the Windows Server endpoint was proven workable but painful, a lighter non-Server client path was added.

Why this path was chosen:

- the public Windows 10 LTSC evaluation path was redirecting away and was not usable
- the user wanted a lighter endpoint and explicitly wanted to avoid Server edition
- Windows 11 IoT Enterprise LTSC was available as an official public evaluation ISO

ISO used:

- `/home/hadescloak/Downloads/26100.1742.240906-0331.ge_release_svc_refresh_CLIENT_IOT_LTSC_EVAL_x64FRE_en-us.iso`

Installed target disk:

- `/home/hadescloak/win-endpoint-client.qcow2`

Meaning:

- this is the lighter Windows endpoint image that will later be imported into CML
- the install was intentionally done on local libvirt first, not inside CML
- that is safer because Windows setup is easier to complete outside CML

### Exact local build shape that worked

VM name used during install:

- `win-endpoint-client-install`

Key hardware choices that were used:

- UEFI firmware
- TPM 2.0 enabled
- `q35` machine type
- SATA boot disk
- `e1000` NIC
- QXL video

Meaning:

- this matches what modern Windows 11 expects much better than the earlier BIOS-style Server endpoint

### What “done” looks like for this lighter client image

The install is considered complete only when:

- OOBE finished
- a usable Windows desktop appeared
- the VM could then be shut down cleanly

Observed result:

- the Windows desktop was reached successfully
- the qcow2 settled at roughly `11.9G` on disk

### Clean-up step after install

After Windows finished installing:

1. shut down `win-endpoint-client-install`
2. detach the ISO from the VM definition
3. boot the VM from disk only
4. only after that, treat the qcow2 as the final import candidate

Meaning:

- if the VM only boots when the ISO is still attached, the image is not ready
- a real CML image must boot from its own disk

### Current lighter-client file state

Current final candidate image:

- `/home/hadescloak/win-endpoint-client.qcow2`

Current observed size:

- about `11.9G` real disk usage
- `64G` virtual size

Meaning:

- the file is already compact enough to import
- no extra duplicate qcow2 should be created unless there is a real failure

### Upload path used for the lighter client image

Because direct write into the dropfolder failed as `sysadmin`, the practical upload path is:

1. upload to:
   - `/var/tmp/win-endpoint-client.qcow2`
2. move with `sudo` into:
   - `/var/local/virl2/dropfolder/win-endpoint-client.qcow2`

Meaning:

- `/var/tmp` is the landing area with enough free space
- `/var/local/virl2/dropfolder` is the folder CML scans for uploaded images

Current controller-side file:

- `/var/local/virl2/dropfolder/win-endpoint-client.qcow2`

### What to do next for the lighter client image

Blind next actions:

1. refresh `Tools` -> `Node and Image Definitions`
2. confirm `win-endpoint-client.qcow2` appears in uploaded images
3. create a new image definition for it
4. test which CML node-definition and hardware profile boot it cleanly

Important:

- this lighter client is UEFI-based, not the older BIOS-style Server endpoint
- do not assume the same CML node-definition trick used for the Server image will be correct for this one

### What actually happened in this lab for the Windows IoT image

The first direct attempts failed for predictable reasons:

1. `Server` image definition with `EFI Boot ON`
- CML error:
  - `Unexpected error EFI Code for node definition is missing`
- Meaning:
  - the built-in `server` node definition in this CML build does not include EFI metadata

2. `Desktop` image definition with `EFI Boot ON`
- CML error:
  - `Unexpected error EFI Code for node definition is missing`
- Meaning:
  - the built-in `desktop` node definition also lacks the EFI metadata required by this controller build

3. Trying to reuse the same consumed uploaded qcow from the GUI
- Problem:
  - the file stopped appearing in `Uploaded Images`
- Meaning:
  - CML had already consumed it into an image definition
- Workaround used:
  - create a second filename that points to the same file, without duplicating the 12G image

### No-extra-space workaround that was used

Managed CML file after import:

- `/var/lib/libvirt/images/virl-base-images/windows-iot-client/win-endpoint-client.qcow2`

Fresh GUI-visible filename that was created without a real copy:

- `/var/local/virl2/dropfolder/win-endpoint-client-desktop.qcow2`

Important:

- this was a hard link, not a second full qcow2
- it did not consume another 12G
- it was only used so CML would offer the image again in the GUI for a second image definition

### Windows IoT image definitions that now exist

Original first image definition:

- `windows-iot-client`

Second image definition used for the desktop-style path:

- `windows-iot-client-desktop`

Important:

- the second image definition is the one tied to the newer UEFI desktop work

### New custom UEFI node definition that was created

Custom node definition ID:

- `windows-uefi-desktop`

Why it was needed:

- both built-in `desktop` and built-in `server` were missing EFI metadata
- the Windows IoT image is UEFI-based and expects modern Windows boot conditions

Important fields discovered from the CML UI bundle:

- `efi_boot`
- `efi_code`
- `efi_vars`
- `machine_type`
- `enable_tpm`
- `enable_rng`

Final custom UEFI node-definition choices:

- `disk_driver: sata`
- `nic_driver: e1000`
- `efi_boot: true`
- `efi_code: OVMF_CODE_4M.ms.fd`
- `efi_vars: OVMF_VARS_4M.ms.fd`
- `machine_type: q35`
- `enable_tpm: true`
- `enable_rng: true`

Meaning:

- SATA was chosen to avoid storage-driver surprises
- `e1000` was chosen because Windows handles it well
- `q35` was required because secure boot support in libvirt demanded it
- TPM was enabled because Windows 11 expects it

### Important errors and what they meant

Observed backend error:

- `Secure boot is supported with q35 machine types only`

Meaning:

- EFI was no longer the missing piece
- the machine type was wrong
- adding `machine_type: q35` to the custom node definition was required

Observed backend error after that:

- `Failed to open file '/var/lib/libvirt/images/virl-base-images/windows-iot-client-desktop/OVMF_VARS_4M.ms.fd': No such file or directory`

Meaning:

- this CML build expected the EFI firmware files to exist next to the managed image definition directory
- it was not enough to only reference the firmware names in the node definition

### Final firmware-file fix that was applied

Two symlinks were created inside the managed image directory:

- `/var/lib/libvirt/images/virl-base-images/windows-iot-client-desktop/OVMF_CODE_4M.ms.fd`
- `/var/lib/libvirt/images/virl-base-images/windows-iot-client-desktop/OVMF_VARS_4M.ms.fd`

These point to:

- `/usr/share/OVMF/OVMF_CODE_4M.ms.fd`
- `/usr/share/OVMF/OVMF_VARS_4M.ms.fd`

Meaning:

- no large file copy was needed
- CML can now find the EFI firmware files where it expects them for this image

### How the lab node was finally bound

The GUI could not expose the new custom node-definition relationship cleanly.

So the fresh lab node:

- `desktop-1`

was rebound controller-side to:

- `node_definition = windows-uefi-desktop`
- `image_definition = windows-iot-client-desktop`

Meaning:

- the visible node label stayed `desktop-1`
- but under the hood it is no longer a stock Alpine desktop
- it is now the Windows IoT UEFI test node

### Current status at the end of this document update

Current strongest signal:

- the user reported that it appears to be working and just taking time

Meaning:

- the boot path is likely finally close enough for Windows to proceed
- do not interrupt the node too early
- first boot under a fresh CML hardware profile can take time
