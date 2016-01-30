#!/bin/bash
set -ex
# This script should be run inside of a Docker container only
if [ ! -f /.dockerinit ]; then
  echo "ERROR: script works in Docker only!"
  exit 1
fi

# Hypriot common settings
HYPRIOT_HOSTNAME="black-pearl"
HYPRIOT_GROUPNAME="docker"
HYPRIOT_USERNAME="pirate"
HYPRIOT_PASSWORD="hypriot"

# Build Debian rootfs for ARCH={armhf,arm64,mips,i386,amd64}
# - Debian armhf = ARMv6/ARMv7
# - Debian arm64 = ARMv8/Aarch64
# - Debian mips  = MIPS
# - Debian i386  = Intel/AMD 32-bit
# - Debian amd64 = Intel/AMD 64-bit
BUILD_ARCH="${BUILD_ARCH:-arm64}"
QEMU_ARCH="${QEMU_ARCH}"
HYPRIOT_TAG="${HYPRIOT_TAG:-dirty}"
ROOTFS_DIR="/debian-${BUILD_ARCH}"

# Show TRAVSI_TAG in travis builds
echo TRAVIS_TAG="${TRAVIS_TAG}"

# Cleanup
mkdir -p /workspace
rm -fr "${ROOTFS_DIR}"

# Define ARCH dependent settings
if [ -z "${QEMU_ARCH}" ]; then
  DEBOOTSTRAP_CMD="debootstrap"
else
  DEBOOTSTRAP_CMD="qemu-debootstrap"

  # Tell Linux how to start binaries that need emulation to use Qemu
  update-binfmts --enable qemu-${QEMU_ARCH}
fi

# Debootstrap a minimal Debian Jessie rootfs
${DEBOOTSTRAP_CMD} \
  --arch="${BUILD_ARCH}" \
  --include="apt-transport-https,avahi-daemon,bash-completion,binutils,ca-certificates,curl,git-core,htop,locales,net-tools,openssh-server,parted,sudo,usbutils" \
  --exclude="debfoster" \
  jessie \
  "${ROOTFS_DIR}" \
  http://ftp.debian.org/debian

# modify/add image files directly
cp -R /builder/files/* $ROOTFS_DIR/

# set up mount points for the pseudo filesystems
mkdir -p $ROOTFS_DIR/{proc,sys,dev/pts}

mount -o bind /dev $ROOTFS_DIR/dev
mount -o bind /dev/pts $ROOTFS_DIR/dev/pts
mount -t proc none $ROOTFS_DIR/proc
mount -t sysfs none $ROOTFS_DIR/sys

# make our build directory the current root
# and install the Rasberry Pi firmware, kernel packages,
# docker tools and some customizations
chroot $ROOTFS_DIR \
       /usr/bin/env \
       HYPRIOT_HOSTNAME=$HYPRIOT_HOSTNAME \
       HYPRIOT_GROUPNAME=$HYPRIOT_GROUPNAME \
       HYPRIOT_USERNAME=$HYPRIOT_USERNAME \
       HYPRIOT_PASSWORD=$HYPRIOT_PASSWORD \
       HYPRIOT_TAG=$HYPRIOT_TAG \
       BUILD_ARCH=$BUILD_ARCH \
       /bin/bash < /builder/chroot-script.sh

# unmount pseudo filesystems
umount -l $ROOTFS_DIR/dev/pts
umount -l $ROOTFS_DIR/dev
umount -l $ROOTFS_DIR/proc
umount -l $ROOTFS_DIR/sys

# ensure that there are no leftover artifacts in the pseudo filesystems
rm -rf $ROOTFS_DIR/{dev,sys,proc}/*

# Package rootfs tarball
umask 0000
tar -czf "/workspace/rootfs-${BUILD_ARCH}.tar.gz" -C "${ROOTFS_DIR}/" .

# Test if rootfs is OK
/builder/test.sh
