# Windows Server Unattended Setup Rules

When an agent interacts with Windows Server Packer configurations, the following strict boundaries MUST be observed to prevent broken zero-touch builds.

## 1. Answer File Delivery (Autounattend.xml)
- **NEVER** use `cd_files` to deliver the `autounattend.xml`. Windows PE is inconsistent at reading CD-ROMs if multiple are present.
- **ALWAYS** use `floppy_files = ["../../unattended/autounattend.xml"]` to map the answer file to the `A:\` drive, which Windows PE parses natively without fail.

## 2. Driver Injection & Limitations
- **NEVER** use `floppy_dirs` to inject large VirtIO driver payloads (like the complete Red Hat 21MB+ ISO including `.pdb` debug symbols). Virtual floppy disks have a hard limit of `1.44MB`. Doing so will crash Packer with a `FAT FULL` error.
- **ALWAYS** extract only the essential `.inf`, `.cat`, and `.sys` files (usually ~400KB total) into a local `drivers/` folder and mount them via `floppy_dirs`. Windows PE will automatically scan the root and all subdirectories of the floppy drive (A:\) and install the drivers natively, making them available for both Windows PE and the target OS image. Avoid using `drvload` as it only injects into the temporary PE environment and breaks the target OS boot.

## 3. QEMU CD-ROM Boot Sequencing
- **NEVER** map secondary tool ISOs using QEMU's `-cdrom` argument or a bare `-drive` argument. This intercepts QEMU's `index=0` and causes it to boot into the tools ISO instead of the OS installer.
- **NEVER** use `["-drive", "file=..."]` in `qemuargs`. The Packer QEMU plugin does a raw substring match for `"-drive"` and if found, it silently drops the `iso_url` entirely, breaking the build!
- **ALWAYS** explicitly define the secondary IDE channel index and bypass the substring match by using `--drive` instead of `-drive`: `["--drive", "file=${var.tools_iso},media=cdrom,index=2"]`. QEMU accepts `--drive` perfectly fine and this prevents Packer from dropping the main ISO.

## 4. Boot Prompts
- **ALWAYS** inject `boot_wait = "2s"` and `boot_command = ["<enter><wait><enter><wait><enter><wait><enter><wait><enter>"]` into Windows Packer builders to automatically bypass the "Press any key to boot from CD or DVD" interception prompt.

## 5. Product Key Bypass
- **ALWAYS** ensure `autounattend.xml` contains a `UserData > ProductKey` node using a generic KMS setup key (e.g., `VDYBN-27WPP-V4HQT-9VMD4-VMK7H`) accompanied by `<WillShowUI>OnError</WillShowUI>`. If this is omitted, the installation will permanently pause on the Language Selection screen.
- **ALWAYS** ensure `OSImage > InstallTo` contains `<WillShowUI>OnError</WillShowUI>`.

## 6. Windows Update (.msu) Finalization
- **ALWAYS** pass the `/norestart` flag to `wusa.exe` during sequential patching script loops to prevent abrupt termination of Packer remote execution.
- **ALWAYS** invoke a built-in `windows-restart` provisioner immediately after patch stages to natively and cleanly finalize all kernel/OS patches before system packing.

## 7. FirstLogonCommands Hang Prevention
- **NEVER** leave `<RequiresUserInput>true</RequiresUserInput>` explicitly or implicitly enabled during a `FirstLogonCommands` block executing powershell via `cmd.exe`. 
- **ALWAYS** strictly define `<RequiresUserInput>false</RequiresUserInput>` in the XML target nodes to ensure Headless/Zero-Touch OOBE stages operate without permanently freezing.

## 8. QEMU Image Compaction & Compression
- **ALWAYS** set `disk_discard = "unmap"` and `disk_compression = true` within the QEMU `.hcl` builder block to allow `.qcow2` automatic sparse shrinking and export compression.
- **ALWAYS** trigger `Optimize-Volume -DriveLetter C -ReTrim -Defrag` prior to shutdown internally within Windows. This punches holes natively and sends unmap instructions to the virtualized device boundary to ensure minimal golden-image size.
