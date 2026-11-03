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

/// A cluster of cores sharing the same microarchitecture.
///
/// On heterogeneous systems (Apple M-series, ARM big.LITTLE), different
/// clusters may have different microarchitectures.
///
/// - Example:
/// ```swift
/// // Print P-/E-core breakdown on Apple Silicon
/// for cluster in ProcessorInfo.current.clusters {
///     print("\(cluster.microarchitecture): \(cluster.coreCount) cores")
/// }
/// ```
public struct Cluster: Sendable, Identifiable, Equatable, Hashable, Codable, CustomStringConvertible {
    /// Zero-based index of this cluster in the system.
    public let id: Int
    /// The microarchitecture of cores in this cluster.
    public let microarchitecture: Microarchitecture
    /// Number of physical cores in this cluster.
    public let coreCount: Int
    /// Index of the first core belonging to this cluster in ``ProcessorInfo/cores``.
    public let coreOffset: Int
    /// Number of logical processors (hardware threads) in this cluster.
    public let logicalProcessorCount: Int
    /// Index of the first logical processor belonging to this cluster in ``ProcessorInfo/logicalProcessors``.
    public let logicalProcessorOffset: Int
    /// The nominal base frequency in Hz from CPUID leaf 0x16, on x86 processors that report it (Intel since
    /// Skylake; AMD generally does not) - the same value as ``ProcessorFrequencyInfo/baseFrequencyHz`` for
    /// every cluster, E-cores included. `nil` on ARM and where the leaf is missing: cpuinfo reports no
    /// per-core clock on Linux or Apple platforms.
    public let frequency: UInt64?

    public var description: String {
        var desc = "Cluster \(id): \(microarchitecture), \(coreCount) core\(coreCount == 1 ? "" : "s")"
        if let freq = frequency {
            desc += " @ \(freq) Hz"
        }
        return desc
    }

    init(_ pointer: UnsafePointer<cpuinfo_cluster>, index: Int, frequencyOverride: UInt64? = nil) {
        id                     = index
        microarchitecture      = Microarchitecture(rawValue: pointer.pointee.uarch.rawValue) ?? .unknown
        coreCount              = Int(pointer.pointee.core_count)
        coreOffset             = Int(pointer.pointee.core_start)
        logicalProcessorCount  = Int(pointer.pointee.processor_count)
        logicalProcessorOffset = Int(pointer.pointee.processor_start)
        let platformFreq       = pointer.pointee.frequency > 0 ? pointer.pointee.frequency : nil
        frequency              = platformFreq ?? frequencyOverride
    }
}
