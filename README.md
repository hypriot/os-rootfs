# os-rootfs [![Build Status](https://travis-ci.org/hypriot/os-rootfs.svg)](https://travis-ci.org/hypriot/os-rootfs)

Create builder Docker image
```
make build
```

Create all rootfs's for all supported ARCH's
```
make all
```

Create single rootfs's for all supported ARCH's
```
make i386
make amd64

make armhf
make arm64
make mips
```

Run container in interactive mode (for testing purposes)
```
make shell
```


# How to run tests

### Option 1: Run tests with a single command
With the following command, all tests for a specific architecture will be executed:

  ```
  BUILD_ARCH=arm64 make test
  ```

### Option 2: Run tests interactively
If you prefer to have a shorter feedback loop of less than a second, enter the container with

  ```
  make testshell
  ```

Now, to run the test, execute

  ```
  BUILD_ARCH=arm64 /test.sh
  ```
