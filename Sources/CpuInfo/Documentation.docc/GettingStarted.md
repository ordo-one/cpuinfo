# Getting Started with CpuInfo

Install CpuInfo and query your first processor information.

## Overview

CpuInfo vendors all C sources, so there are no system dependencies to install. Add the package and start querying immediately.

## Add the Dependency

In your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/ordo-one/cpuinfo.git", from: "2.3.0"),
]
```

Then add `"CpuInfo"` to your target's dependencies:

```swift
.target(
    name: "MyApp",
    dependencies: ["CpuInfo"]
),
```

## Initialize and Query

Access ``ProcessorInfo/current`` to get a snapshot of the system's processor information:

```swift
import CpuInfo

let info = ProcessorInfo.current

if let package = info.packages.first {
    print("Package: \(package.name)")
}
print("Cores: \(info.cores.count)")
print("Clusters: \(info.clusters.count)")

for cluster in info.clusters {
    print("  \(cluster.microarchitecture): \(cluster.coreCount) cores")
}
```

``ProcessorInfo/current`` initializes cpuinfo on first access and caches the result for the life of the process. The resulting ``ProcessorInfo`` value is immutable and `Sendable`.

``ProcessorInfo/current`` traps on catastrophic initialization failure (out-of-memory, unsupported kernel, a sandbox that denies the required syscalls). If your application needs to degrade gracefully, use the throwing initializer instead:

```swift
do {
    let info = try ProcessorInfo()
    // …
} catch {
    print("cpuinfo unavailable: \(error)")
}
```

## Serialization

Every type in a ``ProcessorInfo`` snapshot conforms to `Codable`, so you can serialize a full processor-info snapshot for benchmarking reports, diagnostics, or offline analysis. A snapshot taken on one architecture decodes on the other, with every ISA flag of the architecture it was not taken on reading `false`:

```swift
let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted
let data = try encoder.encode(ProcessorInfo.current)
```

## Architecture Detection

``Architecture/current`` reports the **binary slice's** architecture, not the host hardware. Under Rosetta 2 on Apple Silicon, an x86-64 binary reports `.x86_64`:

```swift
print("Architecture: \(Architecture.current)")
print("Is ARM family: \(Architecture.current.isARMFamily)")
```

For actual hardware topology, use ``ProcessorInfo/current`` instead.

## Runtime Version

Use ``CpuInfoVersion`` to surface package and vendored-cpuinfo commit identifiers in logs and bug reports:

```swift
print("cpuinfo \(CpuInfoVersion.packageVersion) (upstream \(CpuInfoVersion.vendoredCpuinfoCommit.prefix(12)))")
```
