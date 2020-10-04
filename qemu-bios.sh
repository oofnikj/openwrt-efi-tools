#!/bin/sh

PREFIX=${PREFIX:-/usr}
DISK=$1
qemu-system-x86_64 -enable-kvm -smp cpus=2 -m 256 \
  -M q35 -nographic \
  -netdev user,id=net0 -device e1000,netdev=net0,id=net0 \
  -netdev user,id=net1 -device e1000,netdev=net1,id=net1 \
  -drive format=raw,file=$DISK
