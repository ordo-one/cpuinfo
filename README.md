[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fordo-one%2Fcpuinfo%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/ordo-one/cpuinfo)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fordo-one%2Fcpuinfo%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/ordo-one/cpuinfo)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE.txt)
[![Documentation](https://img.shields.io/badge/Documentation-DocC-blue.svg)](https://swiftpackageindex.com/ordo-one/cpuinfo/documentation)
[![codecov](https://codecov.io/gh/ordo-one/cpuinfo/branch/main/graph/badge.svg)](https://codecov.io/gh/ordo-one/cpuinfo)

# cpuinfo

A Swift Package Manager wrapper around [cpuinfo](https://github.com/pytorch/cpuinfo) — a library for detecting CPU topology, cache hierarchy, and instruction set features at runtime.

Zero additional install steps for consumers. All C sources are vendored.

## Features

- **Processor topology** — packages (sockets), clusters, physical cores, and logical processors (hardware threads), with per-core microarchitecture identification (P/E cores on Apple Silicon, big.LITTLE on ARM, hybrid on Intel)
- **Cache hierarchy** — L1 through L4 cache sizes, line sizes, associativity, sharing topology, and flags (unified, inclusive, complex indexing)
- **ISA feature detection** — runtime detection of instruction set extensions: SSE/AVX/AVX-512/AMX on x86, NEON/SVE/SME on ARM, plus cryptographic and bit-manipulation extensions
- **Architecture detection** — binary slice architecture via `Architecture.current` (x86_64, ARM64, etc.); reports `x86_64` under Rosetta 2
- **Serialization** — every type in a `ProcessorInfo` snapshot conforms to `Codable` for JSON export (benchmarking reports, diagnostics, offline analysis), and a snapshot taken on one architecture decodes on the other
- **TSC and frequency (x86)** — a first-party addition read directly with CPUID: the TSC-to-crystal-clock ratio and exact TSC frequency from leaf 0x15 (`ProcessorInfo.tsc`, with a per-model crystal table where the CPU leaves the clock out), base/max/bus frequencies from leaf 0x16 (`ProcessorInfo.frequency`), and invariant-TSC detection from leaf 0x80000007 (`isa.x86.invariantTSC`)
- **Typed errors** — a single `CpuInfoError` thrown via Swift 6 typed throws for initialization and affinity failures
- **Thread affinity (Linux)** — a first-party addition (upstream cpuinfo is detection-only): `CPUSet` (`SetAlgebra`), `ProcessorInfo.setCurrentThreadAffinity(_:)` for pinning, and `ProcessorInfo.currentThreadAffinity` for reading the calling thread's mask. Throws `.threadAffinityUnsupported` on non-Linux.

## Why cpuinfo?

Swift does not ship a cross-platform, cross-architecture view of the CPU. The built-in alternatives are all partial:

| Where | Built-in option | What it misses |
|---|---|---|
| macOS / iOS / visionOS | Scattered `sysctlbyname` keys (`hw.ncpu`, `hw.perflevel0.physicalcpu`, `machdep.cpu.features`, …) | No unified topology, no cache sharing, no microarch names |
| Linux | Parsing `/proc/cpuinfo` and `/sys/devices/system/cpu/` as text | Works only on Linux; format churns across kernel versions |
| x86 only | Raw `CPUID` inline assembly | Hundreds of feature bits to decode by hand; doesn't help on ARM |
| Any platform | `ProcessInfo.processInfo.activeProcessorCount` | Just a scalar |

`CpuInfo` replaces all four with a single API. It wraps the battle-tested pytorch/cpuinfo C library — used by PyTorch, XNNPACK, and others — and adds Swift-native ergonomics on top: value-typed `Sendable` / `Codable` snapshots, typed throws, and runtime version introspection. It also layers on Linux thread pinning (a `SetAlgebra`-conforming `CPUSet` plus `setCurrentThreadAffinity(_:)` / `currentThreadAffinity`) and x86 TSC/frequency reporting — neither of which upstream provides.

## Usage

Add the dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/ordo-one/cpuinfo.git", from: "2.3.0"),
]
```

Then add `"CpuInfo"` to your target's dependencies.

### Quick Start

```swift
import CpuInfo

let info = ProcessorInfo.current            // traps on catastrophic init failure
// or, for explicit error handling:
// let info = try ProcessorInfo()            // throws CpuInfoError

// Topology
if let package = info.packages.first {
    print("Package: \(package.name)")
}
print("Cores: \(info.cores.count)")
print("Clusters: \(info.clusters.count)")

// Heterogeneous topology (P/E cores on Apple Silicon, big.LITTLE on ARM)
for cluster in info.clusters {
    print("  \(cluster.microarchitecture): \(cluster.coreCount) cores")
}

// Cache hierarchy
if let l1d = info.caches.l1Data.first {
    print("L1d: \(l1d.size / 1024) KiB")
}
if let l2 = info.caches.l2.first {
    print("L2: \(l2.size / 1024) KiB")
}

// Architecture
print("Architecture: \(Architecture.current)")

// ISA features
#if arch(arm64)
print("NEON: \(info.isa.arm.neon.neon)")
print("SVE:  \(info.isa.arm.sve.sve)")
#elseif arch(x86_64)
print("AVX2:    \(info.isa.x86.avx.avx2)")
print("AVX-512F: \(info.isa.x86.avx.avx512f)")
#endif

// Runtime version for bug reports / logs
print("cpuinfo \(CpuInfoVersion.packageVersion) (upstream \(CpuInfoVersion.vendoredCpuinfoCommit.prefix(12)))")
```

## Examples

Two executable examples are available under `Examples/` — see the [Examples guide](https://swiftpackageindex.com/ordo-one/cpuinfo/documentation/cpuinfo/examples) in the rendered documentation, or run them directly:

```bash
cd Examples
swift run lscpu        # cross-platform; prints detailed CPU info
swift run linuxPin     # Linux only; pins thread to L2-sharing processors
```

<details>
<summary>Sample <code>lscpu</code> output (Apple M4 Max)</summary>

```
$ swift run lscpu
============================================================
 System Processor Information
============================================================

--- Package -------------------------------------------------

  Version                               2.3.0
  Vendored cpuinfo                      e9320ce33988

--- Architecture --------------------------------------------

  Binary architecture (CPUINFO_ARCH)    ARM64
  x86 family                            no
  ARM family                            yes

--- Topology Summary ----------------------------------------

  Packages (sockets)                    1
  Clusters                              2
  Physical cores                        16
  Logical processors (threads)          16
  Threads per core (SMT)                1

--- Packages ------------------------------------------------

  Package 0                             Apple M4 Max
    Cores                               16
    Clusters                            2
    Logical processors                  16

--- Clusters (heterogeneous topology) -----------------------

  Cluster 0                             Apple Donan Everest (M4 P-core)
    Cores                               12
    Logical processors                  12
  Cluster 1                             Apple Donan Sawtooth (M4 E-core)
    Cores                               4
    Logical processors                  4

--- Cores ---------------------------------------------------

  Apple Donan Everest (M4 P-core)       12 cores
  Apple Donan Sawtooth (M4 E-core)      4 cores

    Core 0                              uarch=Apple Donan Everest (M4 P-core), threads=1
    Core 1                              uarch=Apple Donan Everest (M4 P-core), threads=1
    Core 2                              uarch=Apple Donan Everest (M4 P-core), threads=1
    Core 3                              uarch=Apple Donan Everest (M4 P-core), threads=1
    Core 4                              uarch=Apple Donan Everest (M4 P-core), threads=1
    Core 5                              uarch=Apple Donan Everest (M4 P-core), threads=1
    Core 6                              uarch=Apple Donan Everest (M4 P-core), threads=1
    Core 7                              uarch=Apple Donan Everest (M4 P-core), threads=1
    Core 8                              uarch=Apple Donan Everest (M4 P-core), threads=1
    Core 9                              uarch=Apple Donan Everest (M4 P-core), threads=1
    Core 10                             uarch=Apple Donan Everest (M4 P-core), threads=1
    Core 11                             uarch=Apple Donan Everest (M4 P-core), threads=1
    Core 12                             uarch=Apple Donan Sawtooth (M4 E-core), threads=1
    Core 13                             uarch=Apple Donan Sawtooth (M4 E-core), threads=1
    Core 14                             uarch=Apple Donan Sawtooth (M4 E-core), threads=1
    Core 15                             uarch=Apple Donan Sawtooth (M4 E-core), threads=1

--- Logical Processors --------------------------------------

    Processor 0                         SMT thread 0
    Processor 1                         SMT thread 0
    Processor 2                         SMT thread 0
    Processor 3                         SMT thread 0
    Processor 4                         SMT thread 0
    Processor 5                         SMT thread 0
    Processor 6                         SMT thread 0
    Processor 7                         SMT thread 0
    Processor 8                         SMT thread 0
    Processor 9                         SMT thread 0
    Processor 10                        SMT thread 0
    Processor 11                        SMT thread 0
    Processor 12                        SMT thread 0
    Processor 13                        SMT thread 0
    Processor 14                        SMT thread 0
    Processor 15                        SMT thread 0

--- Cache Hierarchy -----------------------------------------

  L1d (Data)                            16x 64 KiB
    Line size                           128 bytes
    Associativity                       4-way set associative
    Sets                                128
    Partitions                          1
    Shared by                           1 logical processor

  L1i (Instruction)                     16x 128 KiB
    Line size                           128 bytes
    Associativity                       4-way set associative
    Sets                                256
    Partitions                          1
    Shared by                           1 logical processor

  L2 (Unified)                          1x 4 MiB
    Line size                           128 bytes
    Associativity                       8-way set associative
    Sets                                4096
    Partitions                          1
    Shared by                           16 logical processors

--- Instruction Set Extensions ------------------------------

  NEON (Advanced SIMD)                  
    NEON                                yes
    NEON-FP16 (half-precision)          yes
    NEON-FMA (fused multiply-add)       yes
    NEON v8                             yes
    NEON-RDM (rounding double multiply) yes
    NEON-FP16 Arith                     yes
    NEON-DOT (dot product)              yes
    NEON-BF16 (bfloat16)                yes
    NEON-FP8DOT4 (fp8 dot product)      no
    NEON-F8MM (fp8 matrix multiply)     no

  SVE (Scalable Vector Extension)       
    SVE                                 no
    SVE2                                no
    SVE2p1                              no
    SVE-BF16                            no

  SME (Scalable Matrix Extension)       
    SME                                 yes
    SME2                                yes
    SME2p1                              no
    SME-MOP4                            no
    SME-I16I32                          yes
    SME-BI32I32                         yes
    SME-B16B16                          no
    SME-F16F16                          no

  Cryptography & Atomics                
    AES (hardware AES)                  yes
    SHA-1                               yes
    SHA-2 (SHA-256)                     yes
    PMULL (polynomial multiply long)    yes
    CRC32                               yes
    LSE Atomics (ARMv8.1)               yes

  Floating Point & Matrix               
    Scalar FP16 Arith (ARMv8.2)         yes
    BF16 (bfloat16)                     yes
    FP8 (8-bit float convert)           no
    FHM (half-precision multiply)       yes
    I8MM (int8 matrix multiply)         yes
    JSCVT (JS FP convert)               yes
    FCMA (complex number arith)         yes

```

</details>

### Error handling

`ProcessorInfo.current` traps on catastrophic failure (OOM, unsupported kernel, restrictive sandbox). For graceful degradation, use the throwing initializer:

```swift
do {
    let info = try ProcessorInfo()
    // …
} catch {
    // error is a CpuInfoError via typed throws
    print("cpuinfo unavailable: \(error)")
}
```

### Serialization

Every type in a `ProcessorInfo` snapshot conforms to `Codable`, so you can serialize a full processor-info snapshot for benchmarking reports, diagnostics, or offline analysis. A snapshot taken on one architecture decodes on the other, with every ISA flag of the architecture it was not taken on reading `false`:

```swift
let data = try JSONEncoder().encode(ProcessorInfo.current)
```

### Thread-Context Queries

```swift
if let core = ProcessorInfo.currentCore {
    print("Running on core \(core.id)")
}
if let allowed = ProcessorInfo.currentThreadAffinity {
    print("Allowed CPUs: \(allowed.sortedCPUs)")
}
```

These are host-level operations and sit on the `ProcessorInfo` type rather than on a snapshot value. `.currentCore` / `.currentLogicalProcessor` return `nil` on macOS/iOS/visionOS (backed by `sched_getcpu()`, Linux-only). `.currentThreadAffinity` returns `nil` on non-Linux (no equivalent of `sched_getaffinity(2)`).

### Pin current thread to cores sharing L2 cache (Linux)

```swift
let info = ProcessorInfo.current
guard let procID = ProcessorInfo.currentLogicalProcessor?.id,
      let l2 = info.caches.l2.first(where: {
          ($0.logicalProcessorOffset ..< $0.logicalProcessorOffset + $0.logicalProcessorCount)
              .contains(procID)
      })
else { return }

let siblingIDs = (l2.logicalProcessorOffset ..< l2.logicalProcessorOffset + l2.logicalProcessorCount)
    .compactMap { info.logicalProcessors[$0].linuxID }

try ProcessorInfo.setCurrentThreadAffinity(CPUSet(siblingIDs))
```

`CPUSet` is a Swift-native value type that conforms to `SetAlgebra` (and supports array literals, `union`, `intersection`, etc.). On non-Linux platforms `ProcessorInfo.setCurrentThreadAffinity(_:)` throws `CpuInfoError.Code.threadAffinityUnsupported`.

## Design Notes

- Every public type is a value type (a struct or enum), and every type you can hold an instance of is `Sendable` — data is snapshot at init, no retained C pointers.
- Every type in a `ProcessorInfo` snapshot conforms to `Equatable`, `Hashable`, and `Codable`, and all of them except `ProcessorInfo`, `ISAFeatures` with its feature structs, and `CacheFlags` are `CustomStringConvertible`. `CPUSet`, `CpuInfoError`, and `CpuInfoVersion` are not `Codable`.
- `ARMFeatures` and `X86Features` exist on every architecture, so code that reads `isa.x86` or `isa.arm` needs no `#if arch(...)`; the architecture a snapshot was not taken on reads all `false`, and `isa.architecture` says which one it was taken on.
- `Microarchitecture` and `Architecture` gain cases in minor releases, as vendor bumps bring in hardware that upstream has learned to recognize. Switch over them with a `default` case so new cases don't break your build.
- `ProcessorInfo.current` and `try ProcessorInfo()` share the same process-lifetime cache.
- `cpuinfo_deinitialize()` is intentionally not called — cpuinfo is designed for process-lifetime use.
- The vendored C library keeps upstream's unprefixed `cpuinfo_*` symbol names, so a binary that also statically links another copy of pytorch/cpuinfo (as PyTorch or XNNPACK do) links the same symbols twice. Link only one copy.
- cpuinfo is built to log errors to stderr (`CPUINFO_LOG_LEVEL=2`, `CPUINFO_LOG_TO_STDIO=1`), and there is no switch to silence it. It writes them when part of detection fails, which can happen even when initialization succeeds.
- C pointers are read only in initializers and `Internal/BridgeHelpers.swift`; no C pointer outlives initialization.
- The initialization and affinity APIs use typed throws (Swift 6 / SE-0413) — the thrown type is `CpuInfoError`.
- `Architecture.current` reports the **binary slice's** architecture (not the host hardware): under Rosetta 2 on Apple Silicon, an x86-64 binary reports `.x86_64`. For actual hardware topology, use `ProcessorInfo.current.cores` / `.clusters`.
- The package wraps upstream's detection logic unchanged. Two parts are first-party additions: the Linux thread-affinity API (`CPUSet`, `setCurrentThreadAffinity`, `currentThreadAffinity`), built directly on the GNU `pthread_setaffinity_np` / `pthread_getaffinity_np` extensions, and the x86 TSC/frequency reporting (`ProcessorInfo.tsc`, `ProcessorInfo.frequency`, `invariantTSC`), read directly with CPUID. Detection-layer bugs belong upstream; wrapper, affinity, or TSC/frequency bugs stay here — see [SUPPORT.md](SUPPORT.md) for the triage split.

## Running Tests

### macOS

```bash
swift test
```

### iOS Simulator

```bash
xcodebuild test -scheme cpuinfo -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

### macOS (Rosetta 2)

On Apple Silicon, build for x86-64 and run under Rosetta 2 to exercise the x86 ISA detection paths:

```bash
# Tests (xcodebuild handles the Rosetta runner correctly)
xcodebuild test -scheme cpuinfo -destination 'platform=macOS,arch=x86_64'

# Examples
swift build --arch x86_64 --package-path Examples
arch -x86_64 Examples/.build/x86_64-apple-macosx/debug/lscpu
```

### Linux (Apple Container)

Requires [Apple container](https://github.com/apple/container) on Apple Silicon.

```bash
container run --rm -v "$PWD:/workspace" -w /workspace swift:6.2 swift test
```

## Updating Vendored Sources

```bash
./Scripts/update-cpuinfo.sh          # update to latest upstream
./Scripts/update-cpuinfo.sh <SHA>    # pin to a specific commit (full 40-character SHA)
```

The script copies fresh sources, diffs the build files to surface source-list changes, updates `CPUINFO_VERSION`, `NOTICES`, and `CpuInfoVersion.vendoredCpuinfoCommit`, and runs a local build. If upstream adds or removes source files, update the shim files in `Sources/_cpuinfo/shims/` to match.

## Contributing, Support & Security

- [CONTRIBUTING.md](CONTRIBUTING.md) — build, test, and vendor-update workflow
- [SUPPORT.md](SUPPORT.md) — where to route detection bugs (upstream) vs wrapper bugs (here), what to include in reports
- [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) — expectations for participants
- [SECURITY.md](SECURITY.md) — vulnerability disclosure and response SLA

## Acknowledgements

This package vendors and wraps [cpuinfo](https://github.com/pytorch/cpuinfo) by Marat Dukhan and contributors. 

## License

This package is licensed under [Apache 2.0](LICENSE.txt).

cpuinfo and its bundled clog logger are licensed under [BSD 2-Clause](NOTICES) by Google LLC, Facebook Inc., Georgia Institute of Technology, and Marat Dukhan.
