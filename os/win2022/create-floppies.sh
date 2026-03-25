#!/bin/bash
mkdir -p ./floppy

EDITIONS=(
  "standard-core"
  "standard-desktop"
  "datacenter-core"
  "datacenter-desktop"
)

for EDITION in "${EDITIONS[@]}"; do
  echo "Building floppy for $EDITION..."
  IMG_FILE="./floppy/win2022-${EDITION}-setup-qemu.img"
  
  # Initialize the FAT12 raw image file natively
  dd if=/dev/zero of="$IMG_FILE" bs=1k count=1440
  mformat -i "$IMG_FILE" -f 1440 ::
  
  # Stage the explicitly named answer file into the required root Autounattend.xml
  cp -p "./setup/win2022-autounattend-${EDITION}.xml" "./setup/autounattend.xml"
  
  # Load all dependencies natively
  mcopy -i "$IMG_FILE" "./setup/autounattend.xml" ::/
  mcopy -i "$IMG_FILE" "./setup/setup.ps1" ::/
  mcopy -i "$IMG_FILE" "./driver/vioscsi.inf" ::/
  mcopy -i "$IMG_FILE" "./driver/vioscsi.sys" ::/
  mcopy -i "$IMG_FILE" "./driver/vioscsi.cat" ::/
done

# Cleanup temporary OOBE answer file
rm -f ./setup/autounattend.xml
echo "Successfully compiled all ISO floppy image payloads."
