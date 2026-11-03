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

/// A physical processor core.
///
/// Each core belongs to exactly one ``Cluster`` and one ``ProcessorPackage``,
/// and contains one or more ``LogicalProcessor`` instances (hardware threads).
///
/// - Example:
/// ```swift
/// for core in ProcessorInfo.current.cores {
///     print("Core \(core.id): \(core.microarchitecture), \(core.logicalProcessorCount) threads")
/// }
/// ```
public struct Core: Sendable, Identifiable, Equatable, Hashable, Codable, CustomStringConvertible {
    /// Zero-based index of this core in the system.
    public let id: Int
    /// The microarchitecture of this core.
    public let microarchitecture: Microarchitecture
    /// The nominal base frequency in Hz from CPUID leaf 0x16, on x86 processors that report it (Intel since
    /// Skylake; AMD generally does not) - the same value as ``ProcessorFrequencyInfo/baseFrequencyHz`` for
    /// every core, E-cores included. `nil` on ARM and where the leaf is missing: cpuinfo reports no
    /// per-core clock on Linux or Apple platforms.
    public let frequency: UInt64?
    /// Number of logical processors (hardware threads) on this core.
    public let logicalProcessorCount: Int
    /// Index of the first logical processor on this core in ``ProcessorInfo/logicalProcessors``.
    public let logicalProcessorOffset: Int

    public var description: String {
        let threads = logicalProcessorCount
        var desc = "Core \(id): \(microarchitecture), \(threads) thread\(threads == 1 ? "" : "s")"
        if let freq = frequency {
            desc += " @ \(freq) Hz"
        }
        return desc
    }

    init(_ pointer: UnsafePointer<cpuinfo_core>, index: Int, frequencyOverride: UInt64? = nil) {
        id                     = index
        microarchitecture      = Microarchitecture(rawValue: pointer.pointee.uarch.rawValue) ?? .unknown
        let platformFreq       = pointer.pointee.frequency > 0 ? pointer.pointee.frequency : nil
        frequency              = platformFreq ?? frequencyOverride
        logicalProcessorCount  = Int(pointer.pointee.processor_count)
        logicalProcessorOffset = Int(pointer.pointee.processor_start)
    }
}
