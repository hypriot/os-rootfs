#!/bin/bash -e
set +x
# This script should be run inside of a Docker container only
if [ ! -f /.dockerinit ]; then
  echo "ERROR: script works in Docker only!"
  exit 1
fi

# Build Debian rootfs for ARCH={armhf,arm64,mips,i386,amd64}
BUILD_ARCH="${BUILD_ARCH:-arm64}"
ROOTFS_DIR="/debian-${BUILD_ARCH}"
ROOTFS_TAR="/data/rootfs-${BUILD_ARCH}.tar.gz"

# Cleanup
echo "Testing: BUILD_ARCH=${BUILD_ARCH}"
mkdir -p /data
if [ ! -d "${ROOTFS_DIR}" ]; then
  mkdir -p "${ROOTFS_DIR}"
  if [ ! -f "${ROOTFS_TAR}" ]; then
    echo "ERROR: rootfs tarfile ${ROOTFS_TAR} missing!"
    exit 1
  fi
  tar -xzf "${ROOTFS_TAR}" -C "${ROOTFS_DIR}/"
fi

# Test if rootfs is OK
cd "${ROOTFS_DIR}" && rspec /test
