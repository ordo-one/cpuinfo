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

/// Errors thrown by the CpuInfo API.
///
/// Follows the `URLError` / `POSIXError` / `CocoaError` pattern: a lightweight
/// value type carrying a ``Code`` and an optional human-readable diagnostic.
/// The ``Code`` nested type uses `RawRepresentable` rather than a frozen
/// enum so that new cases can be added in future minor releases without
/// breaking exhaustive `switch` statements.
public struct CpuInfoError: Error, Sendable, Equatable, CustomStringConvertible {

    /// A specific failure condition.
    public struct Code: RawRepresentable, Hashable, Sendable {
        public let rawValue: Int32
        public init(rawValue: Int32) { self.rawValue = rawValue }

        /// The underlying cpuinfo library failed to initialize — typically
        /// out-of-memory, a kernel that does not expose processor information,
        /// or a sandbox that denies the required introspection syscalls.
        public static let initializationFailed    = Code(rawValue: 1)

        /// Thread affinity is not available on the current platform.
        /// Only Linux supports per-thread CPU pinning via ``ProcessorInfo/setCurrentThreadAffinity(_:)``.
        public static let threadAffinityUnsupported = Code(rawValue: 2)

        /// `pthread_setaffinity_np(3)` failed or the set held an ID outside `0..<CPU_SETSIZE`.
        /// ``diagnostic`` carries the errno and its message, or the bad IDs.
        public static let threadAffinityFailed    = Code(rawValue: 3)
    }

    /// The specific failure condition.
    public let code: Code

    /// Human-readable diagnostic context, when available. `nil` means the
    /// code itself fully describes the failure.
    public let diagnostic: String?

    public init(code: Code, diagnostic: String? = nil) {
        self.code = code
        self.diagnostic = diagnostic
    }

    public var description: String {
        let label: String
        switch code {
        case .initializationFailed:       label = "initializationFailed"
        case .threadAffinityUnsupported:  label = "threadAffinityUnsupported"
        case .threadAffinityFailed:       label = "threadAffinityFailed"
        default:                           label = "code(\(code.rawValue))"
        }
        if let diagnostic {
            return "CpuInfoError.\(label): \(diagnostic)"
        }
        return "CpuInfoError.\(label)"
    }
}
