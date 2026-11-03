# Example Programs

Two executable examples ship with the package under `Examples/`.

## Overview

Both examples are real executable targets with tests, in one `Examples/Package.swift` that depends on this package by path. Run them with `swift run` from the `Examples/` directory.

## lscpu

A command-line tool that prints detailed CPU information — topology, cache hierarchy, and ISA feature flags — in a style similar to the Linux `lscpu(1)` utility. Works on every platform the library supports.

### macOS

```bash
cd Examples
swift run lscpu
```

### Linux (Apple Container)

Requires [Apple container](https://github.com/apple/container) on Apple Silicon.

```bash
container run --rm -v "$PWD/..:/cpuinfo" -w /cpuinfo/Examples swift:6.2 swift run lscpu
```

## linuxPin

Pins the calling thread to all logical processors that share the same L2 cache, using ``CPUSet`` and ``ProcessorInfo/setCurrentThreadAffinity(_:)``. Linux-only; on other platforms it prints that it could not determine the current logical processor, which needs Linux, and exits.

### Linux (Apple Container)

```bash
container run --rm -v "$PWD/..:/cpuinfo" -w /cpuinfo/Examples swift:6.2 swift run linuxPin
```

## Linux tests

Both examples' tests run in one go:

```bash
container run --rm -v "$PWD/..:/cpuinfo" -w /cpuinfo/Examples swift:6.2 swift test
```

## iOS Simulator

The main package's test target exercises the same code paths as `lscpu` and can be run under the iOS Simulator:

```bash
xcodebuild test -scheme cpuinfo -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```
