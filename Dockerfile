FROM hypriot/image-builder:latest

RUN apt-get update && apt-get install -y \
    binfmt-support \
    qemu \
    qemu-user-static \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
gpg


COPY builder /builder/

# create rootfs
CMD /builder/build.sh
