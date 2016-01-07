FROM debian:jessie

RUN apt-get update && apt-get install -y \
    qemu \
    qemu-user-static \
    binfmt-support \
    debootstrap \
    debootstrap \
    elfutils \
    ruby \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

RUN gem update --no-document --system && \
    gem install --no-document serverspec

COPY build.sh /build.sh
COPY test.sh /test.sh
COPY test /test

# create rootfs
CMD /build.sh
