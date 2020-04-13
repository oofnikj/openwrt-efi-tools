#!/usr/bin/env bash

# gen-efi-image.sh [DEST_IMG] [EFI_IMG] [SOURCE_IMG]
# 
# Generates an EFI-compatible x86-64 disk image for OpenWrt
# by combining the rootfs and kernel from the latest stable release
# with the EFI image available in snapshot since @a6b7c3e.
# 
# Download the EFI image from 
# https://downloads.openwrt.org/snapshots/targets/x86/64/openwrt-x86-64-generic-ext4-combined-efi.img.gz
#
# Download the latest stable release of 19.07.2 from
# https://downloads.openwrt.org/releases/19.07.2/targets/x86/64/openwrt-19.07.2-x86-64-combined-ext4.img.gz
#
# Tested only with version 19.07.2.

set -e

DEST_IMG=${1:-image.img}
EFI_IMG=${2:-openwrt-x86-64-generic-ext4-combined-efi.img}
SOURCE_IMG=${3:-openwrt-19.07.2-x86-64-combined-ext4.img}

test -f ${EFI_IMG}.gz || test -f ${SOURCE_IMG}.gz && {
	echo 'Inflate compressed image files'
	for f in ${EFI_IMG}.gz ${SOURCE_IMG}.gz; do
		gzip -d "${f}"
	done
}

echo 'Create empty image file'
fallocate -l 300M ${DEST_IMG}

echo 'Copy EFI partition from snapshot'
dd if=${EFI_IMG} bs=512 skip=511 seek=511 count=32768 of=${DEST_IMG} conv=notrunc

echo 'Copy rootfs'
dd if=${SOURCE_IMG} bs=512 skip=33791 seek=33791 count=524288 of=${DEST_IMG} conv=notrunc

echo 'Build partition table'
uuid=$(sfdisk -d openwrt-x86-64-generic-ext4-combined-efi.img | grep 'type=EBD0A0A2-B9E5-4433-87C0-68B6B72699C7' | sed -E 's/.*uuid=(.*)/\1/g')
size=$(sfdisk -d openwrt-19.07.2-x86-64-combined-ext4.img | grep 'type=83' | grep -v 'bootable' | sed -E 's/.*size=\s+([0-9]+).*/\1/g')
sfdisk image.img <<-EOF
	label: gpt
	label-id: D9265732-F7D1-ADBA-513C-502CE422E600
	unit: sectors
	first-lba: 34

	1 : start=512, size=32768, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B, uuid=D9265732-F7D1-ADBA-513C-502CE422E601, name="EFI System Partition"
	2 : start=33792, size=${size}, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, uuid=${uuid}
EOF

echo 'Copy kernel'
tmpdir=$(mktemp -u -p .)
mkdir -p "${tmpdir}"
sudo mount -o loop,offset=$((512 * 512)) -t ext4 "${SOURCE_IMG}" "${tmpdir}"
cp "${tmpdir}"/boot/vmlinuz vmlinuz
sudo umount "${tmpdir}"
sudo mount -o loop,offset=$((512 * 512)) -t vfat "${EFI_IMG}" "${tmpdir}"
sudo cp vmlinuz "${tmpdir}/boot/"
sudo umount "${tmpdir}"
rm -rf "${tmpdir}"

echo "Image file ${DEST_IMG} created"