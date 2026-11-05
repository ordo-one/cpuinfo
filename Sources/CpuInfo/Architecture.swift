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

/// The instruction-set architecture of the current **binary slice**.
///
/// **Rosetta / translation note:** Under Rosetta 2 on Apple Silicon,
/// an x86-64 binary reports `.x86_64` even though the host hardware
/// is ARM64. This is intentional — ``current`` describes the compiled
/// binary, not the host. For actual hardware topology, use
/// ``ProcessorInfo/current`` and its ``ProcessorInfo/cores`` / ``ProcessorInfo/clusters``.
///
/// New cases can arrive in minor releases as more architectures are supported, so switch
/// over this type with a `default` case, as below.
///
/// - Example:
/// ```swift
/// switch Architecture.current {
/// case .arm64:  print("Native Apple Silicon or ARM64 Linux")
/// case .x86_64: print("x86-64 (may be running under Rosetta 2)")
/// default:      print("Other: \(Architecture.current)")
/// }
/// ```
public enum Architecture: String, Sendable, Equatable, Hashable, Codable, CustomStringConvertible {
    /// 32-bit x86.
    case x86
    /// x86-64, which an x86-64 slice also reports under Rosetta 2.
    case x86_64
    /// 32-bit ARM.
    case arm
    /// 64-bit ARM (AArch64).
    case arm64
    /// An architecture this version does not recognize.
    case unknown

    /// The architecture of this binary slice, fixed when it is compiled.
    ///
    /// - Example:
    /// ```swift
    /// if Architecture.current.isARMFamily {
    ///     // take an ARM-specific code path
    /// }
    /// ```
    public static let current: Architecture = {
        #if arch(x86_64)
        return .x86_64
        #elseif arch(i386)
        return .x86
        #elseif arch(arm64)
        return .arm64
        #elseif arch(arm)
        return .arm
        #else
        return .unknown
        #endif
    }()

    /// Decodes a raw value, mapping values this version does not know to ``unknown``.
    public init(from decoder: any Decoder) throws {
        self = Self(rawValue: try decoder.singleValueContainer().decode(String.self)) ?? .unknown
    }

    /// True if this slice targets any x86 variant.
    public var isX86Family: Bool { self == .x86 || self == .x86_64 }

    /// True if this slice targets any ARM variant.
    public var isARMFamily: Bool { self == .arm || self == .arm64 }

    public var description: String {
        switch self {
        case .x86:     "x86"
        case .x86_64:  "x86-64"
        case .arm:     "ARM (32-bit)"
        case .arm64:   "ARM64"
        case .unknown: "unknown"
        }
    }
}
