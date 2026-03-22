# Windows Server Unattended Setup Rules

When an agent interacts with Windows Server Packer configurations, the following strict boundaries MUST be observed to prevent broken zero-touch builds.

## 1. Answer File Delivery (Autounattend.xml)
- **NEVER** use `cd_files` to deliver the `autounattend.xml`. Windows PE is inconsistent at reading CD-ROMs if multiple are present.
- **ALWAYS** use `floppy_files = ["../../unattended/autounattend.xml"]` to map the answer file to the `A:\` drive, which Windows PE parses natively without fail.

## 2. Driver Injection & Limitations
- **NEVER** use `floppy_dirs` to inject large VirtIO driver payloads (like the Red Hat 21MB ISO). Virtual floppy disks have a hard limit of `1.44MB`. Doing so will crash Packer with a `FAT FULL` error.
- **ALWAYS** inject drivers by mounting the `--tools-iso` as a CD-ROM, and executing a `RunSynchronousCommand` in the `windowsPE` pass to scan drives `C:` through `Z:` for the `.inf` files and execute `drvload`.

## 3. QEMU CD-ROM Boot Sequencing
- **NEVER** map secondary tool ISOs using QEMU's `-cdrom` argument or a bare `-drive` argument. This intercepts QEMU's `index=0` and causes it to boot into the tools ISO instead of the OS installer.
- **ALWAYS** explicitly define the secondary IDE channel index: `["-drive", "file=${var.tools_iso},media=cdrom,index=2"]`.

## 4. Boot Prompts
- **ALWAYS** inject `boot_wait = "2s"` and `boot_command = ["<enter><wait><enter><wait><enter><wait><enter><wait><enter>"]` into Windows Packer builders to automatically bypass the "Press any key to boot from CD or DVD" interception prompt.

## 5. Product Key Bypass
- **ALWAYS** ensure `autounattend.xml` contains a `UserData > ProductKey` node using a generic KMS setup key (e.g., `VDYBN-27WPP-V4HQT-9VMD4-VMK7H`) accompanied by `<WillShowUI>OnError</WillShowUI>`. If this is omitted, the installation will permanently pause on the Language Selection screen.
- **ALWAYS** ensure `OSImage > InstallTo` contains `<WillShowUI>OnError</WillShowUI>`.
