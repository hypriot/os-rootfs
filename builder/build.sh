#!/bin/bash
set -ex
source builder/gpgcheck.sh

# this script should be run inside of a Docker container only
if [ ! -f /.dockerenv ]; then
  echo "ERROR: script works in Docker only!"
  exit 1
fi

# Hypriot common settings
HYPRIOT_HOSTNAME="${HYPRIOT_HOSTNAME:-black-pearl}"

# build Debian rootfs for ARCH={armhf,arm64,mips,i386,amd64}
# - Debian armhf = ARMv6/ARMv7
# - Debian arm64 = ARMv8/Aarch64
# - Debian mips  = MIPS
# - Debian i386  = Intel/AMD 32-bit
# - Debian amd64 = Intel/AMD 64-bit
BUILD_ARCH="${BUILD_ARCH:-arm64}"
QEMU_ARCH="${QEMU_ARCH}"
VARIANT="${VARIANT:-debian}"
HYPRIOT_OS_VERSION="${HYPRIOT_OS_VERSION:-dirty}"
ROOTFS_DIR="/debian-${BUILD_ARCH}"
DEBOOTSTRAP_URL="http://ftp.debian.org/debian"
DEBOOTSTRAP_KEYRING_OPTION=""
DEFAULT_PACKAGES_INCLUDE="apt-transport-https,avahi-daemon,bash-completion,binutils,ca-certificates,curl,git-core,htop,locales,net-tools,openssh-server,parted,sudo,usbutils,wget,libpam-systemd"
DEFAULT_PACKAGES_EXCLUDE="debfoster"

if [[ "${VARIANT}" = "raspbian" ]]; then
  DEBOOTSTRAP_URL="http://mirrordirector.raspbian.org/raspbian/"
  DEBOOTSTRAP_KEYRING_OPTION="--keyring=/etc/apt/trusted.gpg"

  # for Raspbian we need an extra gpg key to be able to access the repository
  mkdir -p /builder/files/tmp
  wget -v -O "/builder/files/tmp/raspbian.public.key" http://mirrordirector.raspbian.org/raspbian.public.key
  get_gpg A0DA38D0D76E8B5D638872819165938D90FDDD2E "/builder/files/tmp/raspbian.public.key"

fi

# show TRAVIS_TAG in travis builds
echo TRAVIS_TAG="${TRAVIS_TAG}"

# cleanup
mkdir -p /workspace
rm -fr "${ROOTFS_DIR}"

# define ARCH dependent settings
if [ -z "${QEMU_ARCH}" ]; then
  DEBOOTSTRAP_CMD="debootstrap"
else
  DEBOOTSTRAP_CMD="qemu-debootstrap"

  # tell Linux how to start binaries that need emulation to use Qemu
  update-binfmts --enable "qemu-${QEMU_ARCH}"
fi

# debootstrap a minimal Debian Jessie rootfs
${DEBOOTSTRAP_CMD} \
  ${DEBOOTSTRAP_KEYRING_OPTION} \
  --arch="${BUILD_ARCH}" \
  --include="${DEFAULT_PACKAGES_INCLUDE}" \
  --exclude="${DEFAULT_PACKAGES_EXCLUDE}" \
  jessie \
  "${ROOTFS_DIR}" \
  "${DEBOOTSTRAP_URL}"

# modify/add image files directly
cp -R /builder/files/* "$ROOTFS_DIR/"

# only keep apt/sources.list files that we need for the current build
if [[ "$VARIANT" == "debian" ]]; then
  rm -f "$ROOTFS_DIR/etc/apt/sources.list.raspbian.jessie"
elif [[ "$VARIANT" == "raspbian" ]]; then
  mv -f "$ROOTFS_DIR/etc/apt/sources.list.raspbian.jessie" "$ROOTFS_DIR/etc/apt/sources.list"
fi

# set up mount points for the pseudo filesystems
mkdir -p "$ROOTFS_DIR/proc" "$ROOTFS_DIR/sys" "$ROOTFS_DIR/dev/pts"

mount -o bind /dev "$ROOTFS_DIR/dev"
mount -o bind /dev/pts "$ROOTFS_DIR/dev/pts"
mount -t proc none "$ROOTFS_DIR/proc"
mount -t sysfs none "$ROOTFS_DIR/sys"

# make our build directory the current root
# and install the Rasberry Pi firmware, kernel packages,
# docker tools and some customizations
chroot "$ROOTFS_DIR" \
       /usr/bin/env \
       HYPRIOT_HOSTNAME="$HYPRIOT_HOSTNAME" \
       HYPRIOT_OS_VERSION="$HYPRIOT_OS_VERSION" \
       BUILD_ARCH="$BUILD_ARCH" \
       VARIANT="$VARIANT" \
       /bin/bash < /builder/chroot-script.sh

# unmount pseudo filesystems
umount -l "$ROOTFS_DIR/dev/pts"
umount -l "$ROOTFS_DIR/dev"
umount -l "$ROOTFS_DIR/proc"
umount -l "$ROOTFS_DIR/sys"

# ensure that there are no leftover artifacts in the pseudo filesystems
rm -rf "$ROOTFS_DIR/{dev,sys,proc}/*"

# package rootfs tarball
umask 0000

cd /workspace
ARCHIVE_NAME="rootfs-${BUILD_ARCH}-${VARIANT}-${HYPRIOT_OS_VERSION}.tar.gz"
tar -czf "${ARCHIVE_NAME}" -C "${ROOTFS_DIR}/" .
sha256sum "${ARCHIVE_NAME}" > "${ARCHIVE_NAME}.sha256"
cd -

# test if rootfs is OK
HYPRIOT_HOSTNAME="${HYPRIOT_HOSTNAME}" VARIANT="${VARIANT}" /builder/test.sh
