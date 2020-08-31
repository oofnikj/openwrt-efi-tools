#!/usr/bin/env bash
set -e

usage() {
	cat <<-EOF
	$0 SRC_IMG [SIZE]
	Use this script to grow an OpenWrt rootfs partition to the desired size.
	If SIZE is not specified, defaults to 2 GB.
	EOF
}

main() {
	cp ${SRC_IMG} ${DEST_IMG}
	qemu-img resize -f raw ${DEST_IMG} ${SIZE}

	echo "Resize root partition to ${SIZE}"
	sfdisk -d ${DEST_IMG} > ${DEST_IMG%.img}.sfdisk
	sed -i -E "/${DEST_IMG}2/ s/size=[ 0-9,]+//" ${DEST_IMG%.img}.sfdisk
	sed -i "/^last-lba/d" ${DEST_IMG%.img}.sfdisk
	sfdisk ${DEST_IMG} < ${DEST_IMG%.img}.sfdisk
	rm -rf ${DEST_IMG%.img}.sfdisk

	echo "Grow filesystem"
	offset=$(sfdisk -d ${DEST_IMG} | grep "${DEST_IMG}2" | sed -E 's/.*start=\s+([0-9]+).*/\1/g')
	size=$(sfdisk -d ${DEST_IMG} | grep "${DEST_IMG}2" | sed -E 's/.*size=\s+([0-9]+).*/\1/g')
	loopdev=$(sudo losetup --offset $((512 * $offset)) --sizelimit $((512 * $size)) --find --show ${DEST_IMG})
	sudo e2fsck -yf $loopdev >/dev/null 2>&1 || true
	sudo resize2fs $loopdev
	sudo losetup -d $loopdev

	echo "--- new image file ${DEST_IMG} created"
}

SRC_IMG=${1:-''}
test -f "${SRC_IMG}" || { usage; exit 1; }
SIZE=${2:-2G}
DEST_IMG=${SRC_IMG%.img}-resized.img
main
