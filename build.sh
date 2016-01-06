#!/bin/bash -e
set -x
# This script should be run inside of a Docker container only
if [ ! -f /.dockerinit ]; then
  echo "ERROR: script works in Docker only!"
  exit 1
fi

# Build Debian rootfs for ARCH={armhf,arm64,mips,i386,amd64}
# - Debian armhf = ARMv6/ARMv7
# - Debian arm64 = ARMv8/Aarch64
# - Debian mips  = MIPS
# - Debian i386  = Intel/AMD 32-bit
# - Debian amd64 = Intel/AMD 64-bit
BUILD_ARCH="${BUILD_ARCH:-arm64}"
ROOTFS_DIR="/debian-${BUILD_ARCH}"

# Cleanup
mkdir -p /data
rm -fr "${ROOTFS_DIR}"

# Define ARCH dependent settings
if [ "${BUILD_ARCH}" == "i386" ] || [ "${BUILD_ARCH}" == "amd64" ];then
  DEBOOTSTRAP_CMD="debootstrap"  
else
  DEBOOTSTRAP_CMD="qemu-debootstrap"

  # Qemu settings
  if [ "${BUILD_ARCH}" == "armhf" ];then
    QEMU_ARCH="arm"
  fi
  if [ "${BUILD_ARCH}" == "arm64" ];then
    QEMU_ARCH="aarch64"
  fi
  if [ "${BUILD_ARCH}" == "mips" ];then
    QEMU_ARCH="mips"
  fi

  # Define Qemu for binfmts (important to run inside of a Docker container)
  update-binfmts --enable qemu-${QEMU_ARCH}
  cat /proc/sys/fs/binfmt_misc/qemu-${QEMU_ARCH}
fi

# Debootstrap a minimal Debian Jessie rootfs 
#  --keyring /usr/share/keyrings/debian-ports-archive-keyring.gpg \
#  --no-check-gpg \
#  --variant=buildd \
${DEBOOTSTRAP_CMD} \
  --arch="${BUILD_ARCH}" \
  --include="apt-transport-https,avahi-daemon,ca-certificates,curl,htop,locales,net-tools,openssh-server,usbutils" \
  --exclude="debfoster" \
  jessie \
  "${ROOTFS_DIR}" \
  http://ftp.debian.org/debian


### Configure Debian ###

# Use standard Debian apt repositories
cat << EOM | chroot "${ROOTFS_DIR}" \
  tee /etc/apt/sources.list
deb http://httpredir.debian.org/debian jessie main
deb-src http://httpredir.debian.org/debian jessie main

deb http://httpredir.debian.org/debian jessie-updates main
deb-src http://httpredir.debian.org/debian jessie-updates main

deb http://security.debian.org/ jessie/updates main
deb-src http://security.debian.org/ jessie/updates main
EOM


### Configure network and systemd services ###

# Set ethernet interface eth0 to dhcp
cat << EOM | chroot "${ROOTFS_DIR}" \
  tee /etc/systemd/network/eth0.network
[Match]
Name=eth0

[Network]
DHCP=yes
EOM

# Enable networkd
chroot "${ROOTFS_DIR}" \
  systemctl enable systemd-networkd

# Configure and enable resolved
chroot "${ROOTFS_DIR}" \
  ln -sfv /run/systemd/resolve/resolv.conf /etc/resolv.conf
chroot "${ROOTFS_DIR}" \
  systemctl enable systemd-resolved

# Enable SSH root login
chroot "${ROOTFS_DIR}" \
  sed -i 's|PermitRootLogin without-password|PermitRootLogin yes|g' /etc/ssh/sshd_config

# Enable NTP with timesyncd
chroot "${ROOTFS_DIR}" \
  sed -i 's|#Servers=|Servers=|g' /etc/systemd/timesyncd.conf
chroot "${ROOTFS_DIR}" \
  systemctl enable systemd-timesyncd
  
# Set default locales to 'en_US.UTF-8'
echo 'en_US.UTF-8 UTF-8' | chroot "${ROOTFS_DIR}" \
  tee -a /etc/locale.gen
chroot "${ROOTFS_DIR}" \
  locale-gen
echo 'locales locales/default_environment_locale select en_US.UTF-8' | chroot "${ROOTFS_DIR}" \
  debconf-set-selections
chroot "${ROOTFS_DIR}" \
  dpkg-reconfigure -f noninteractive locales


### HypriotOS specific settings ###

# set hostname to 'black-pearl'
echo 'black-pearl' | chroot "${ROOTFS_DIR}" \
  tee /etc/hostname

# set root password to 'hypriot'
echo 'root:hypriot' | chroot "${ROOTFS_DIR}" \
  /usr/sbin/chpasswd

# set HypriotOS bash prompt for root user
cat /files/bash_prompt/bashrc | chroot "${ROOTFS_DIR}" \
  tee /root/.bashrc
cat /files/bash_prompt/bash_prompt | chroot "${ROOTFS_DIR}" \
  tee /root/.bash_prompt
cat /files/bash_prompt/profile | chroot "${ROOTFS_DIR}" \
  tee /root/.profile


# Package rootfs tarball
umask 0000
tar -czf "/data/rootfs-${BUILD_ARCH}.tar.gz" -C "${ROOTFS_DIR}/" .
