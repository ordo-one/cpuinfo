# ``CpuInfo``

Detect CPU topology, cache hierarchy, and instruction-set features at runtime.

## Overview

`CpuInfo` is a Swift-native wrapper around the battle-tested [pytorch/cpuinfo](https://github.com/pytorch/cpuinfo) C library. It provides a single, unified view of the host processor across **x86 / x86-64 / ARM / ARM64** and **macOS / iOS / visionOS / Linux** — with no external dependencies. All C sources are vendored; consumers only need `swift package add-dependency` to use it.

One entry point:

```swift
import CpuInfo

let info = ProcessorInfo.current
print("Cores: \(info.cores.count)")
if let l1d = info.caches.l1Data.first {
    print("L1d: \(l1d.size / 1024) KiB")
}
```

Every type in a ``ProcessorInfo`` snapshot is a `Sendable` value type that is `Equatable`, `Hashable`, and `Codable`, and a snapshot taken on one architecture decodes on the other. Data is captured once at initialization; there are no retained C pointers. Both `ProcessorInfo.current` and `try ProcessorInfo()` share a single process-lifetime cache.

## When to reach for CpuInfo

- You need processor topology (packages, clusters, P/E cores, SMT) — not just `activeProcessorCount`.
- You want cache **geometry** and **sharing topology** — who shares which L2 / L3.
- You need to enable an optimized path (AVX-512, SVE2, NEON-BF16, AMX) at runtime based on the actual CPU.
- You want one API that works identically on macOS, iOS, visionOS, and Linux, across both x86 and ARM.
- You want to pin threads to specific logical processors on Linux without hand-writing `cpu_set_t` gymnastics.
- You want `Codable` snapshots for diagnostics, bug reports, or benchmarking artefacts.

The built-in alternatives (scattered `sysctlbyname` keys on Apple platforms, `/proc/cpuinfo` parsing on Linux, raw `CPUID` on x86) each cover only a slice of this; `CpuInfo` unifies them.

## Start here

- <doc:GettingStarted> — install, initialize, first query.
- <doc:Examples> — two runnable programs (`lscpu`, `linuxPin`) exercising the full API.

## Topics

### Essentials

- <doc:GettingStarted>
- ``ProcessorInfo``
- ``Architecture``
- ``CpuInfoError``
- ``CpuInfoVersion``

### Processor Topology

- <doc:ProcessorTopology>
- ``ProcessorPackage``
- ``Cluster``
- ``Core``
- ``LogicalProcessor``
- ``Microarchitecture``

### Cache Hierarchy

- <doc:CacheHierarchyGuide>
- ``CacheHierarchy``
- ``CacheLevel``
- ``CacheLevel/ID``
- ``CacheFlags``
- ``CacheKind``

### Instruction Set Features

- <doc:ISAFeatureDetection>
- ``ISAFeatures``

### Thread Affinity (Linux)

- ``CPUSet``
- ``ProcessorInfo/currentCore``
- ``ProcessorInfo/currentLogicalProcessor``
- ``ProcessorInfo/currentThreadAffinity``
- ``ProcessorInfo/setCurrentThreadAffinity(_:)``

### CPU Frequency & Time Stamp Counter (x86)

- ``TSCInfo``
- ``ProcessorFrequencyInfo``

### Examples

- <doc:Examples>
