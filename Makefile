default: build

build:
	docker build -t rootfs-builder .

all: build amd64 i386 arm64 armhf mips

amd64: build
	docker run --rm -e BUILD_ARCH=amd64 -e TRAVIS_TAG -e HYPRIOT_OS_VERSION -v $(shell pwd):/workspace --privileged rootfs-builder

i386: build
	docker run --rm -e BUILD_ARCH=i386 -e TRAVIS_TAG -e HYPRIOT_OS_VERSION -v $(shell pwd):/workspace --privileged rootfs-builder

arm64: build
	docker run --rm -e BUILD_ARCH=arm64 -e QEMU_ARCH=aarch64 -e TRAVIS_TAG -e HYPRIOT_OS_VERSION -v $(shell pwd):/workspace --privileged rootfs-builder

armhf: build
	docker run --rm -e BUILD_ARCH=armhf -e QEMU_ARCH=arm -e TRAVIS_TAG -e HYPRIOT_OS_VERSION -v $(shell pwd):/workspace --privileged rootfs-builder

mips: build
	docker run --rm -e BUILD_ARCH=mips -e QEMU_ARCH=mips -e TRAVIS_TAG -e HYPRIOT_OS_VERSION -v $(shell pwd):/workspace --privileged rootfs-builder

shell: build
	docker run --rm -ti -e TRAVIS_TAG -e HYPRIOT_OS_VERSION -v $(shell pwd):/workspace --privileged rootfs-builder bash

test: build
	docker run --rm -ti -e BUILD_ARCH=$(BUILD_ARCH) -e TRAVIS_TAG -e HYPRIOT_OS_VERSION -v $(shell pwd):/workspace --privileged rootfs-builder /builder/test.sh

testshell: build
	docker run --rm -ti -e TRAVIS_TAG -e HYPRIOT_OS_VERSION -v $(shell pwd):/workspace -v $(shell pwd)/test:/test --privileged rootfs-builder bash

shellcheck: build
	docker run --rm -ti -v $(shell pwd):/workspace rootfs-builder bash -c 'shellcheck builder/*.sh builder/files/usr/local/bin/* builder/files/etc/firstboot.d/*'

tag:
	git tag ${TAG}
	git push origin ${TAG}
