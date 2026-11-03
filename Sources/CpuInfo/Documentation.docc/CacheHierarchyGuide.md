# Cache Hierarchy

Query cache sizes, geometry, and sharing topology.

## Overview

The ``CacheHierarchy`` struct organizes caches by level (L1 through L4). Each array contains one ``CacheLevel`` entry per distinct cache instance in the system.

For example, on a 10-core CPU with per-core L1 caches, ``CacheHierarchy/l1Data`` has 10 entries. If all cores share a single L3, ``CacheHierarchy/l3`` has one entry.

## Querying Caches

```swift
let caches = ProcessorInfo.current.caches

// L1 data cache
if let l1d = caches.l1Data.first {
    print("L1d: \(l1d.size / 1024) KB, \(l1d.lineSize)-byte lines")
    print("  \(l1d.associativity)-way associative, \(l1d.sets) sets")
}

// L2 cache
if let l2 = caches.l2.first {
    print("L2: \(l2.size / 1024) KB (shared by \(l2.logicalProcessorCount) threads)")
}

// L3 cache (may not exist on all systems)
if let l3 = caches.l3.first {
    print("L3: \(l3.size / (1024 * 1024)) MB")
}
```

## Cache Identity

Each ``CacheLevel`` has a unique ``CacheLevel/ID`` identifier that combines the cache level, kind, and index. This ensures that cache instances are uniquely identifiable across all levels — for example, an L1 data cache at index 0 and an L2 unified cache at index 0 have distinct IDs:

```swift
if let l1d = caches.l1Data.first {
    print(l1d.id)  // "L1-data-0"
}

if let l2 = caches.l2.first {
    print(l2.id)   // "L2-unified-0"
}
```

## Cache Properties

Each ``CacheLevel`` provides detailed geometry:

- ``CacheLevel/size`` — total cache size in bytes
- ``CacheLevel/lineSize`` — cache line size in bytes (typically 64)
- ``CacheLevel/associativity`` — set associativity (0 means fully associative)
- ``CacheLevel/sets`` — number of sets
- ``CacheLevel/partitions`` — number of partitions (slices)

## Cache Flags

The ``CacheFlags`` option set describes additional properties:

- ``CacheFlags/unified`` — cache serves both instructions and data (typical for L2+)
- ``CacheFlags/inclusive`` — all lines in lower-level caches also exist here
- ``CacheFlags/complexIndexing`` — uses non-trivial index mapping

Convenience properties are available on ``CacheLevel``:

```swift
if l2.isUnified {
    print("L2 is a unified cache")
}
```

## Processor Sharing

Each cache instance records which logical processors share it via ``CacheLevel/logicalProcessorCount`` and ``CacheLevel/logicalProcessorOffset``. This can be used to understand the sharing topology — for example, which cores share an L2 or L3 cache.
