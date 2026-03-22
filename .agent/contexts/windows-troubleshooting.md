# Windows Golden Image Troubleshooting Guide

## Windows PE & Autounattend.xml
- **Delivery Method**: Windows Setup is incredibly stubborn. Always use `floppy_files` (A:\ drive) to deliver the `autounattend.xml`. Using `cd_files` will often break the sequence because Windows PE stops scanning disks when it finds other CD-ROMs (like VirtIO drivers). Do NOT try to extract 21MB VirtIO drivers into the floppy disk using `floppy_dirs` as floppy disks have a hard limit of **1.44 MB** and will throw a `FAT FULL` error causing Packer to crash immediately.
- **Product Keys**: If using an Evaluation ISO, you *must* provide a `UserData` block with a generic KMS Setup Key (e.g., `VDYBN-27WPP-V4HQT-9VMD4-VMK7H` for 2022 Std) and set `<WillShowUI>OnError</WillShowUI>`. If this is missing, Windows will stop at the Language/Keyboard selection screen.
- **Language Selection**: To completely bypass the first setup screen, the `Microsoft-Windows-International-Core-WinPE` block MUST have `<WillShowUI>OnError</WillShowUI>` specifically within the `<SetupUILanguage>` node.

## VirtIO Drivers (Libvirt / QEMU)
- If you use `disk_interface = "virtio"`, Windows will not see the hard drive to install onto.
- You must mount the VirtIO ISO (`--tools-iso`) and inject it on the fly during Windows PE before the disk formatting phase.
- **Injection Script**: Add a `<RunSynchronousCommand>` in the `windowsPE` pass that loops through all drive letters (C through Z) and uses `drvload` to load `viostor.inf`, `netkvm.inf`, and `vioscsi.inf`.
- **DO NOT** use the `DriverPaths` directive pointing to `A:\` if you have not successfully injected the drivers onto the floppy, because missing drivers will cause Windows to halt and ask "Where do you want to install Windows?" 

## QEMU Boot Conflicts
- When adding an extra CD-ROM (like VirtIO drivers) via `qemuargs`, NEVER use `-cdrom`. It will replace the primary boot ISO.
- Do NOT use `-drive file=...,media=cdrom` without an index. It will override `index=0` (the primary boot ISO).
- Always use: `["-drive", "file=${var.tools_iso},media=cdrom,index=2"]`. This maps the tools to `D:\` or `E:\` without disturbing the primary boot sequence.

## Press Any Key to Boot
- Windows ISOs pause execution and wait for a keystroke. Always include `boot_wait = "3s"` and `boot_command = ["<enter><wait><enter>"]` in your Packer configurations to bypass this.
