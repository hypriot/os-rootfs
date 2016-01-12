FROM debian:jessie

RUN apt-get update && apt-get install -y \
    qemu \
    qemu-user-static \
    binfmt-support \
    debootstrap \
    elfutils \
    ruby \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

RUN gem update --no-document --system && \
    gem install --no-document serverspec

COPY builder /builder/

# create rootfs
CMD /builder/build.sh
