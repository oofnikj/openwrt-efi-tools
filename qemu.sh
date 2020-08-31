#!/bin/sh

PREFIX=${PREFIX:-/usr}
qemu-system-x86_64 -enable-kvm -smp cpus=2 -m 256 \
  -M q35 -nographic \
  -netdev user,id=net0 -device e1000,netdev=net0,id=net0 \
  -netdev user,id=net1 -device e1000,netdev=net1,id=net1 \
  -drive if=pflash,format=raw,readonly,file="${PREFIX}/share/edk2-ovmf/x64/OVMF_CODE.fd" \
  -drive format=raw,file=image.img