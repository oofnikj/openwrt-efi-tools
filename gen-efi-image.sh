#!/usr/bin/env bash

set -e

usage() {
	printf "%s SOURCE_IMG EFI_IMG DEST_IMG\n" "$0"
	exit 1
}

parse_args() {
	SOURCE_IMG=${1}
	EFI_IMG=${2}
	DEST_IMG=${3}
	if [ ! $# -eq 3 ] ; then
		printf "Incorrect parameters\n"
		usage
	fi
	for f in $SOURCE_IMG $EFI_IMG; do
		test -f "$f" || { printf "No file '%s'\n" $SOURCE_IMG; exit 1; }
	done
}

decompress() {
	for f in ${EFI_IMG} ${SOURCE_IMG}; do
		if [[ "${f}" != "${f%.gz}" ]]; then
			printf "Inflate compressed image file %s\n" "$f"
			gzip --quiet --keep --decompress "${f}" || true
		fi
	done
	EFI_IMG=${EFI_IMG%.gz}
	SOURCE_IMG=${SOURCE_IMG%.gz}

}

tmpdir() {
	tmpdir=$(mktemp -u -p .)
	mkdir -p "${tmpdir}"
}

cleanup() {
	rm -rf "${tmpdir}"
}

main() {
	decompress
	tmpdir
	printf "Initialize empty image file\n"
	fallocate -l 300M ${DEST_IMG}

	printf "Copy EFI partition from snapshot\n"
	dd if=${EFI_IMG} bs=512 skip=511 seek=511 count=32768 of=${DEST_IMG} conv=notrunc

	printf "Copy rootfs\n"
	dd if=${SOURCE_IMG} bs=512 skip=33791 seek=33791 count=524288 of=${DEST_IMG} conv=notrunc

	printf "Build partition table\n"
	uuid=$(sfdisk -d "${EFI_IMG}" | grep 'type=EBD0A0A2-B9E5-4433-87C0-68B6B72699C7' | sed -E 's/.*uuid=(.*)/\1/g')
	size=$(sfdisk -d "${SOURCE_IMG}" | grep 'type=83' | grep -v 'bootable' | sed -E 's/.*size=\s+([0-9]+).*/\1/g')
	sfdisk image.img <<-EOF
		label: gpt
		label-id: D9265732-F7D1-ADBA-513C-502CE422E600
		unit: sectors
		first-lba: 34

		1 : start=512, size=32768, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B, uuid=D9265732-F7D1-ADBA-513C-502CE422E601, name="EFI System Partition"
		2 : start=33792, size=${size}, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, uuid=${uuid}
	EOF

	printf "Copy kernel from source image\n"
	sudo mount -o loop,offset=$((512 * 512)) -t ext4 "${SOURCE_IMG}" "${tmpdir}"
	sudo cp "${tmpdir}/boot/vmlinuz" vmlinuz
	sudo umount "${tmpdir}"
	sudo mount -o loop,offset=$((512 * 512)) -t vfat "${DEST_IMG}" "${tmpdir}"
	sudo mv vmlinuz "${tmpdir}/boot/vmlinuz"
	sudo umount "${tmpdir}"
}

trap cleanup exit
parse_args "$@"
main
printf "Image file %s created\n" "${DEST_IMG}"