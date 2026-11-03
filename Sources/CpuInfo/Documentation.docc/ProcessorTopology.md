# Processor Topology

Understand the hierarchical structure of packages, clusters, cores, and logical processors.

## Overview

Modern processors have a hierarchical structure:

- **Package** — a physical processor chip (socket). Desktop systems typically have one; servers may have two or more.
- **Cluster** — a group of cores sharing the same microarchitecture. On heterogeneous systems like Apple M-series (performance/efficiency cores) or ARM big.LITTLE, different clusters have different microarchitectures.
- **Core** — a physical execution unit with its own register file and execution pipelines.
- **Logical Processor** — a hardware thread. On CPUs with SMT (Hyper-Threading), each core contains multiple logical processors.

All topology types conform to `Equatable`, `Hashable`, `Codable`, and `CustomStringConvertible`.

## Querying the Topology

```swift
let info = ProcessorInfo.current

// Packages (sockets)
for pkg in info.packages {
    print("\(pkg.name): \(pkg.coreCount) cores, \(pkg.clusterCount) clusters")
}

// Heterogeneous clusters (description includes microarchitecture name)
for cluster in info.clusters {
    print("  \(cluster.microarchitecture): \(cluster.coreCount) cores")
}

// Core → logical processor mapping
for core in info.cores {
    print("Core \(core.id): \(core.logicalProcessorCount) threads")
}
```

## Microarchitecture Names

The ``Microarchitecture`` enum conforms to `CustomStringConvertible` and provides human-readable names for all known processor designs:

```swift
for cluster in info.clusters {
    // Prints e.g. "Apple Firestorm (A14/M1 P-core)" or "AMD Zen 4 (Ryzen 7000 / EPYC Genoa)"
    print(cluster.microarchitecture.description)
}
```

## Cross-referencing with Offsets

Each level provides offset properties to cross-reference into the parent ``ProcessorInfo`` arrays. For example, ``ProcessorPackage/coreOffset`` is the index of the first core belonging to that package in ``ProcessorInfo/cores``:

```swift
if let pkg = info.packages.first {
    let pkgCores = info.cores[pkg.coreOffset ..< pkg.coreOffset + pkg.coreCount]
}
```

## Thread-Context Queries

The ``ProcessorInfo/currentCore`` and ``ProcessorInfo/currentLogicalProcessor`` type properties report where the calling thread is presently scheduled. They are host-level operations (not snapshot operations), so they sit on the type, not on an instance:

```swift
if let core = ProcessorInfo.currentCore {
    print("Running on core \(core.id) (\(core.microarchitecture))")
}
```

Both return `nil` on macOS, iOS, and visionOS (no `sched_getcpu()` equivalent). On Linux they are backed by `sched_getcpu(2)` — the result is a point-in-time snapshot and the thread may be migrated immediately afterwards; use ``ProcessorInfo/setCurrentThreadAffinity(_:)`` first to pin the thread.

To read the mask the kernel currently enforces for the calling thread - the last `setCurrentThreadAffinity(_:)` set, bounded by restrictions such as a cgroup `cpuset.cpus` - use ``ProcessorInfo/currentThreadAffinity``:

```swift
if let allowed = ProcessorInfo.currentThreadAffinity {
    print("Allowed CPUs: \(allowed.sortedCPUs)")
}
```

## Thread Affinity (Linux)

Pin the calling thread to a set of logical processors using ``CPUSet`` and ``ProcessorInfo/setCurrentThreadAffinity(_:)``:

```swift
let set: CPUSet = [0, 1, 2, 3]
try ProcessorInfo.setCurrentThreadAffinity(set) // throws on non-Linux
```

Elements of ``CPUSet`` are Linux CPU identifiers as exposed by ``LogicalProcessor/linuxID``. See <doc:Examples> for an end-to-end program that pins a thread to all logical processors sharing its L2 cache.
