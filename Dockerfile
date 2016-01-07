FROM debian:jessie

RUN apt-get update && apt-get install -y \
    qemu \
    qemu-user-static \
    binfmt-support \
    debootstrap \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

COPY build.sh /build.sh
COPY files /files

# create rootfs
CMD /build.sh
