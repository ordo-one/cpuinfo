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

#if arch(x86_64) || arch(i386)
internal import _cpuinfo
#endif

/// Processor frequency tiers from CPUID leaf 0x16.
///
/// Available on Intel Skylake (6th-gen Core) and later. AMD processors
/// generally do not implement this leaf.
///
/// Access via ``ProcessorInfo/frequency`` — `nil` on non-x86 hosts and on
/// x86 hosts that do not expose the leaf.
///
/// - Example:
/// ```swift
/// if let freq = ProcessorInfo.current.frequency {
///     print("Base \(freq.baseFrequencyMHz) MHz, max \(freq.maxFrequencyMHz) MHz")
/// }
/// ```
public struct ProcessorFrequencyInfo: Sendable, Equatable, Hashable, Codable, CustomStringConvertible {
    /// Processor base frequency in MHz as reported by CPUID.
    public let baseFrequencyMHz: UInt32
    /// Maximum frequency in MHz as reported by CPUID. Zero if not reported.
    public let maxFrequencyMHz: UInt32
    /// Bus (reference) frequency in MHz as reported by CPUID. Zero if not reported.
    public let busFrequencyMHz: UInt32

    private func toHz(_ mhz: UInt32) -> UInt64? {
        mhz > 0 ? UInt64(mhz) * 1_000_000 : nil
    }

    /// Processor base frequency in Hz, or `nil` if not reported.
    public var baseFrequencyHz: UInt64? { toHz(baseFrequencyMHz) }

    /// Maximum frequency in Hz, or `nil` if not reported.
    public var maxFrequencyHz: UInt64? { toHz(maxFrequencyMHz) }

    /// Bus (reference) frequency in Hz, or `nil` if not reported.
    public var busFrequencyHz: UInt64? { toHz(busFrequencyMHz) }

    public var description: String {
        var parts: [String] = []
        if baseFrequencyMHz > 0 {
            parts.append("base: \(baseFrequencyMHz) MHz")
        }
        if maxFrequencyMHz > 0 {
            parts.append("max: \(maxFrequencyMHz) MHz")
        }
        if busFrequencyMHz > 0 {
            parts.append("bus: \(busFrequencyMHz) MHz")
        }
        return parts.isEmpty ? "no frequency data" : parts.joined(separator: ", ")
    }

    /// Populated by ``ProcessorInfo`` during initialization.
    /// Returns `nil` when the host does not expose CPUID leaf 0x16.
    internal static func load() -> Self? {
        #if arch(x86_64) || arch(i386)
        let info = cpuinfo_x86_query_freq_info()
        guard info.available else { return nil }
        return Self(
            baseFrequencyMHz: info.base_frequency_mhz,
            maxFrequencyMHz: info.max_frequency_mhz,
            busFrequencyMHz: info.bus_frequency_mhz
        )
        #else
        return nil
        #endif
    }
}
