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

/// The system's cache hierarchy organized by level.
///
/// Each array contains one ``CacheLevel`` entry per distinct cache instance.
/// For example, on a 10-core CPU with per-core L1 caches, ``l1Data`` will
/// have 10 entries.
///
/// - Example:
/// ```swift
/// let caches = ProcessorInfo.current.caches
/// print("\(caches.l1Data.count)× L1d, \(caches.l2.count)× L2, \(caches.l3.count)× L3")
/// ```
public struct CacheHierarchy: Sendable, Equatable, Hashable, Codable, CustomStringConvertible {
    /// L1 data cache instances.
    public let l1Data: [CacheLevel]
    /// L1 instruction cache instances.
    public let l1Instruction: [CacheLevel]
    /// L2 cache instances (typically unified).
    public let l2: [CacheLevel] // swiftlint:disable:this identifier_name
    /// L3 cache instances (typically shared across cores).
    public let l3: [CacheLevel] // swiftlint:disable:this identifier_name
    /// L4 cache instances (rare; found on some Intel desktop parts).
    public let l4: [CacheLevel] // swiftlint:disable:this identifier_name

    public var description: String {
        var parts: [String] = []
        if !l1Data.isEmpty { parts.append("\(l1Data.count)x L1d") }
        if !l1Instruction.isEmpty { parts.append("\(l1Instruction.count)x L1i") }
        if !l2.isEmpty { parts.append("\(l2.count)x L2") }
        if !l3.isEmpty { parts.append("\(l3.count)x L3") }
        if !l4.isEmpty { parts.append("\(l4.count)x L4") }
        return parts.joined(separator: ", ")
    }

    init() {
        l1Data = collect(count: cpuinfo_get_l1d_caches_count(), get: cpuinfo_get_l1d_cache) {
            CacheLevel($0, index: $1, level: 1, kind: .data)
        }
        l1Instruction = collect(count: cpuinfo_get_l1i_caches_count(), get: cpuinfo_get_l1i_cache) {
            CacheLevel($0, index: $1, level: 1, kind: .instruction)
        }
        l2 = collect(count: cpuinfo_get_l2_caches_count(), get: cpuinfo_get_l2_cache) {
            CacheLevel($0, index: $1, level: 2, kind: .unified)
        }
        l3 = collect(count: cpuinfo_get_l3_caches_count(), get: cpuinfo_get_l3_cache) {
            CacheLevel($0, index: $1, level: 3, kind: .unified)
        }
        l4 = collect(count: cpuinfo_get_l4_caches_count(), get: cpuinfo_get_l4_cache) {
            CacheLevel($0, index: $1, level: 4, kind: .unified)
        }
    }
}
