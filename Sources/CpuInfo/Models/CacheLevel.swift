// ===----------------------------------------------------------------------===//
//
// Copyright © 2022-2026 Ordo One AB
//
// Licensed under Apache License v2.0
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: 2022-2026 Ordo One AB
//
// https://ordo.one
//
// ===----------------------------------------------------------------------===//

internal import _cpuinfo

/// Flags describing cache properties.
///
/// Bridges the `CPUINFO_CACHE_UNIFIED`, `CPUINFO_CACHE_INCLUSIVE`, and
/// `CPUINFO_CACHE_COMPLEX_INDEXING` bitmask macros from the C library.
public struct CacheFlags: OptionSet, Sendable, Hashable, Codable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }

    /// The platform reported the cache as unified. ARM platforms, Apple Silicon included, leave this unset
    /// for L2 and above, so ask ``CacheLevel/isUnified`` whether a cache serves both instructions and data.
    public static let unified         = Self(rawValue: UInt32(CPUINFO_CACHE_UNIFIED))
    /// All lines present in lower-level caches also exist in this cache.
    public static let inclusive       = Self(rawValue: UInt32(CPUINFO_CACHE_INCLUSIVE))
    /// Uses a complex (non-power-of-two modular) index function.
    public static let complexIndexing = Self(rawValue: UInt32(CPUINFO_CACHE_COMPLEX_INDEXING))
}

/// The kind of data a cache serves.
public enum CacheKind: String, Sendable, Equatable, Hashable, Codable, CustomStringConvertible {
    /// Data only.
    case data
    /// Instructions only.
    case instruction
    /// Both data and instructions (unified).
    case unified

    public var description: String {
        switch self {
        case .data:        "data"
        case .instruction: "instruction"
        case .unified:     "unified"
        }
    }
}

/// A single cache instance at a specific level.
///
/// Describes the geometry and properties of one cache — its size, line size,
/// associativity, and which logical processors share it.
///
/// - Example:
/// ```swift
/// let l1d = ProcessorInfo.current.caches.l1Data[0]
/// print("\(l1d.size / 1024) KiB, \(l1d.lineSize)-byte lines, \(l1d.associativity)-way")
/// ```
public struct CacheLevel: Sendable, Identifiable, Equatable, Hashable, Codable, CustomStringConvertible {
    /// Unique identifier for a cache level instance, combining the cache level
    /// number, kind, and index within that category to ensure uniqueness across
    /// all cache instances in the system.
    public struct ID: Hashable, Sendable, Codable, CustomStringConvertible { // swiftlint:disable:this type_name
        /// Cache level (1, 2, 3, or 4).
        public let level: Int
        /// Whether this cache holds data, instructions, or both.
        public let kind: CacheKind
        /// Zero-based index within caches of this level and kind.
        public let index: Int

        public var description: String {
            "L\(level)-\(kind)-\(index)"
        }
    }

    /// Unique identifier combining cache level, kind, and index.
    public let id: ID
    /// Cache level (1, 2, 3, or 4).
    public let level: Int
    /// Whether this cache holds data, instructions, or both, by where it sits in ``CacheHierarchy``:
    /// ``CacheHierarchy/l1Data`` and ``CacheHierarchy/l1Instruction`` hold data and instruction caches,
    /// and L2 and above are unified.
    public let kind: CacheKind
    /// Total cache size in bytes.
    public let size: Int
    /// Cache line size in bytes.
    public let lineSize: Int
    /// Set associativity. Zero indicates fully associative.
    public let associativity: Int
    /// Number of sets in the cache.
    public let sets: Int
    /// Number of partitions (slices) in the cache.
    public let partitions: Int
    /// Cache property flags (unified, inclusive, complex indexing), as the platform reported them.
    public let flags: CacheFlags
    /// Number of logical processors sharing this cache instance.
    public let logicalProcessorCount: Int
    /// Index of the first logical processor sharing this cache in ``ProcessorInfo/logicalProcessors``.
    public let logicalProcessorOffset: Int

    /// Whether this cache is fully associative (associativity is zero).
    public var isFullyAssociative: Bool { associativity == 0 }
    /// Whether this cache serves both instructions and data: every L2 and higher cache, and any cache the
    /// platform reports as unified.
    public var isUnified: Bool { kind == .unified || flags.contains(.unified) }
    /// Whether this cache is inclusive of lower-level caches.
    public var isInclusive: Bool { flags.contains(.inclusive) }
    /// Whether this cache uses complex (non-trivial) indexing.
    public var usesComplexIndexing: Bool { flags.contains(.complexIndexing) }

    public var description: String {
        let assoc = isFullyAssociative ? "fully associative" : "\(associativity)-way"
        return "L\(level) \(kind): \(size) bytes, \(lineSize)-byte lines, \(assoc)"
    }

    init(_ pointer: UnsafePointer<cpuinfo_cache>, index: Int, level: Int, kind: CacheKind) {
        id              = ID(level: level, kind: kind, index: index)
        self.level      = level
        self.kind       = kind
        size            = Int(pointer.pointee.size)
        lineSize        = Int(pointer.pointee.line_size)
        associativity   = Int(pointer.pointee.associativity)
        sets            = Int(pointer.pointee.sets)
        partitions      = Int(pointer.pointee.partitions)
        flags           = CacheFlags(rawValue: pointer.pointee.flags)
        logicalProcessorCount  = Int(pointer.pointee.processor_count)
        logicalProcessorOffset = Int(pointer.pointee.processor_start)
    }
}
