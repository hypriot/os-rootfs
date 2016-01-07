FROM debian:jessie

RUN apt-get update && apt-get install -y \
    qemu \
    qemu-user-static \
    binfmt-support \
    debootstrap \
    debootstrap \
    ruby \
    --no-install-recommends && \
    gem update --system && \
    gem install serverspec && \
    rm -rf /var/lib/apt/lists/*

COPY build.sh /build.sh
COPY test /test

# create rootfs
CMD /build.sh
