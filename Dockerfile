FROM debian:jessie

RUN apt-get update && apt-get install -y \
    qemu \
    qemu-user-static \
    binfmt-support \
    debootstrap \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# debian bootstrap rootfs for arch
# - Debian armhf = ARMv6/ARMv7
# - Debian arm64 = ARMv8/Aarch64
ENV BOOTSTRAP_ARCH=arm64
ENV ROOTFS_DIR=/debian-${BOOTSTRAP_ARCH}

# configure qemu emulation: aarch64 or arm
ENV QEMU_ARCH=aarch64

# create rootfs
CMD update-binfmts --enable qemu-${QEMU_ARCH} && \
  cat /proc/sys/fs/binfmt_misc/qemu-arm && \
  qemu-debootstrap \
  --arch="${BOOTSTRAP_ARCH}" \
  --include="apt-transport-https,avahi-daemon,ca-certificates,curl,htop,locales,net-tools,openssh-server,usbutils" \
  --exclude="debfoster" \
  jessie \
  "${ROOTFS_DIR}" \
  http://ftp.debian.org/debian \
  && tar -czf /data/rootfs.tar.gz -C ${ROOTFS_DIR}/ .
