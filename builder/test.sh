#!/bin/bash
set +ex
# this script should be run inside of a Docker container only
if [ ! -f /.dockerenv ]; then
  echo "ERROR: script works in Docker only!"
  exit 1
fi

# build Debian rootfs for ARCH={armhf,arm64,mips,i386,amd64}
BUILD_ARCH="${BUILD_ARCH:-arm64}"
VARIANT="${VARIANT:-debian}"
ROOTFS_DIR="/${VARIANT}-${BUILD_ARCH}"
HYPRIOT_OS_VERSION="${HYPRIOT_OS_VERSION:-dirty}"
ROOTFS_TAR="/workspace/rootfs-${BUILD_ARCH}-${VARIANT}-${HYPRIOT_OS_VERSION}.tar.gz"

# cleanup
echo "Testing: BUILD_ARCH=${BUILD_ARCH}"
mkdir -p /workspace
if [ ! -d "${ROOTFS_DIR}" ]; then
  mkdir -p "${ROOTFS_DIR}"
  if [ ! -f "${ROOTFS_TAR}" ]; then
    echo "ERROR: rootfs tarfile ${ROOTFS_TAR} missing!"
    exit 1
  fi
  tar -xzf "${ROOTFS_TAR}" -C "${ROOTFS_DIR}/"
fi

# test if rootfs is OK
cd "${ROOTFS_DIR}" && rspec --format documentation --color /builder/test
