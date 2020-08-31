# Openwrt EFI Tools

Some scripts to manage OpenWrt EFI images on x86_64.

* `gen-efi-image.sh`
```
./gen-efi-image.sh SOURCE_IMG EFI_IMG DEST_IMG
```
Generates an EFI-compatible x86-64 disk image for OpenWrt
by combining the rootfs and kernel from the latest stable release
with the EFI image available in snapshot since @a6b7c3e.

Requires `qemu-utils` package.

Download the latest stable release from
https://downloads.openwrt.org/releases/19.07.3/targets/x86/64/openwrt-19.07.3-x86-64-combined-ext4.img.gz

Download the EFI image from 
https://downloads.openwrt.org/snapshots/targets/x86/64/openwrt-x86-64-generic-ext4-combined-efi.img.gz

Tested with versions 19.07.2 and 19.07.3.

* `resize-image.sh`
```
./resize-image.sh IMAGE [SIZE]
```

Generate a resized image with a larger root partition. Online resize from
within OpenWrt is not possible with such a small disk and results in errors.

* `qemu.sh`
```
./qemu.sh IMAGE
```
Runs the image in QEMU in EFI mode.
On Debian / Ubuntu, the packages `qemu-kvm` and `ovmf` must be installed. The path to the OVMF
firmware on Debian / Ubuntu should be changed to `/usr/share/OVMF/OVMF_CODE.fd`.