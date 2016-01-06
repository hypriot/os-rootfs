FROM debian:jessie

RUN apt-get update && apt-get install -y \
    qemu \
    qemu-user-static \
    binfmt-support \
    debootstrap \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

ENV ARCH=arm64
ENV ROOTFS_DIR=/debian-${ARCH}

# create rootfs
CMD echo rootfs && qemu-debootstrap --arch=$ARCH --keyring \
/usr/share/keyrings/debian-archive-keyring.gpg \
--exclude=debfoster \
jessie debian-arm64 http://ftp.debian.org/debian
# && tar -czf /data/build_rootfs.tar.gz -C debian-arm64/ .

CMD qemu-debootstrap \
  --arch="${ARCH}" \
  --include="apt-transport-https,avahi-daemon,ca-certificates,curl,htop,locales,net-tools,openssh-server,usbutils" \
  --exclude="debfoster" \
  jessie \
  "${ROOTFS_DIR}" \
  http://ftp.debian.org/debian

tar -czf /data/rootfs.tar.gz -C ${ROOTFS_DIR}/ .
