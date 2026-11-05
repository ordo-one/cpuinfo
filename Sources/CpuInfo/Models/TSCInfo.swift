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

/// TSC (Time Stamp Counter) and crystal-clock information from CPUID leaf 0x15.
///
/// Available on Intel processors that expose leaf 0x15. Provides the
/// TSC-to-crystal clock ratio and, when the CPU reports it, the crystal clock
/// frequency — together these yield the exact TSC frequency.
///
/// Access via ``ProcessorInfo/tsc`` — `nil` on non-x86 hosts and on x86 hosts
/// that do not expose the leaf (AMD processors, older Intel).
///
/// - Example:
/// ```swift
/// if let tsc = ProcessorInfo.current.tsc, let hz = tsc.tscFrequencyHz {
///     print("TSC at \(Double(hz) / 1e9) GHz")
/// }
/// ```
public struct TSCInfo: Sendable, Equatable, Hashable, Codable, CustomStringConvertible {
    /// TSC/crystal-clock ratio denominator (CPUID 0x15 EAX).
    public let denominator: UInt32
    /// TSC/crystal-clock ratio numerator (CPUID 0x15 EBX).
    public let numerator: UInt32
    /// Crystal-clock frequency in Hz.
    ///
    /// Reported directly by the CPU (``crystalClockKnown`` is `true`) or
    /// inferred from the CPU model. `nil` if neither source is available.
    public let crystalClockHz: UInt64?
    /// Computed TSC frequency in Hz: `crystalClockHz * numerator / denominator`.
    /// `nil` when ``crystalClockHz`` is unavailable.
    public let tscFrequencyHz: UInt64?
    /// `true` if the crystal-clock frequency was reported directly by CPUID
    /// (leaf 0x15 ECX ≠ 0) rather than inferred from the CPU model.
    public let crystalClockKnown: Bool

    public var description: String {
        var parts = ["TSC ratio: \(numerator)/\(denominator)"]
        if let crystalHz = crystalClockHz {
            parts.append("crystal: \(Self.megahertz(crystalHz)) MHz\(crystalClockKnown ? "" : " (inferred)")")
        }
        if let tscHz = tscFrequencyHz {
            parts.append("TSC: \(Self.megahertz(tscHz)) MHz")
        }
        return parts.joined(separator: ", ")
    }

    /// `hertz` in MHz rounded to one decimal place, e.g. `"19.2"`.
    static func megahertz(_ hertz: UInt64) -> String {
        let tenths = hertz / 100_000 + (hertz % 100_000 >= 50_000 ? 1 : 0)
        return "\(tenths / 10).\(tenths % 10)"
    }

    /// Populated by ``ProcessorInfo`` during initialization.
    /// Returns `nil` when the host does not expose CPUID leaf 0x15.
    internal static func load() -> Self? {
        #if arch(x86_64) || arch(i386)
        let info = cpuinfo_x86_query_tsc_info()
        guard info.available else { return nil }
        return Self(
            denominator: info.denominator,
            numerator: info.numerator,
            crystalClockHz: info.crystal_clock_hz > 0 ? info.crystal_clock_hz : nil,
            tscFrequencyHz: info.tsc_frequency_hz > 0 ? info.tsc_frequency_hz : nil,
            crystalClockKnown: info.crystal_clock_known
        )
        #else
        return nil
        #endif
    }
}
