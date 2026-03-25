#!/bin/bash

BASE_DIR=../os/win2022
DIR_NAME=$(basename $BASE_DIR)

mkdir -p ${BASE_DIR}/floppy

EDITIONS=(
  "standard-core"
  "standard-desktop"
  "datacenter-core"
  "datacenter-desktop"
)
if [[ -d ${BASE_DIR}/qemu/ ]]; then
  IMAGE_FILE_SUFFIX='-qemu'
fi

for EDITION in "${EDITIONS[@]}"; do
  echo "Building floppy for $EDITION..."
  IMG_FILE="${BASE_DIR}/floppy/${DIR_NAME}-${EDITION}-setup${IMAGE_FILE_SUFFIX}.img"
  
  # Initialize the FAT12 raw image file natively
  dd if=/dev/zero of="$IMG_FILE" bs=1k count=1440
  mformat -i "$IMG_FILE" -f 1440 ::
  
  # Stage the explicitly named answer file into the required root Autounattend.xml
  cp -p "${BASE_DIR}/setup/${DIR_NAME}-autounattend-${EDITION}.xml" "${BASE_DIR}/setup/autounattend.xml"
  
  # Load all dependencies natively
  mcopy -i "$IMG_FILE" "${BASE_DIR}/setup/autounattend.xml" ::/
  mcopy -i "$IMG_FILE" "${BASE_DIR}/setup/setup.ps1" ::/

  if [[ -d ${BASE_DIR}/qemu/ ]]; then
    mcopy -i "$IMG_FILE" "${BASE_DIR}/qemu/vioscsi.inf" ::/
    mcopy -i "$IMG_FILE" "${BASE_DIR}/qemu/vioscsi.sys" ::/
    mcopy -i "$IMG_FILE" "${BASE_DIR}/qemu/vioscsi.cat" ::/
  fi
done

# Cleanup temporary OOBE answer file
rm -f "${BASE_DIR}/setup/autounattend.xml"
echo "Successfully compiled all ISO floppy image payloads."
