# os-rootfs

Create builder Docker image
```
docker build -t rootfs-builder .
```

Create rootfs's for all supported ARCH's
```
docker run --rm -e BUILD_ARCH=i386 -v $(pwd):/data --privileged rootfs-builder
docker run --rm -e BUILD_ARCH=amd64 -v $(pwd):/data --privileged rootfs-builder

docker run --rm -e BUILD_ARCH=armhf -v $(pwd):/data --privileged rootfs-builder
docker run --rm -e BUILD_ARCH=arm64 -v $(pwd):/data --privileged rootfs-builder
docker run --rm -e BUILD_ARCH=mips -v $(pwd):/data --privileged rootfs-builder
```

Run container in interactive mode (for testing purposes)
```
docker run --rm -ti -v $(pwd):/data --privileged rootfs-builder bash
```
