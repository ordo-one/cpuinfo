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

/// A logical processor (hardware thread).
///
/// On CPUs with simultaneous multithreading (SMT / Hyper-Threading),
/// a single ``Core`` contains multiple logical processors.
///
/// - Example:
/// ```swift
/// let info = ProcessorInfo.current
/// let smtCount = info.logicalProcessors.count / max(info.cores.count, 1)
/// print("SMT factor: \(smtCount)")
/// ```
public struct LogicalProcessor: Sendable, Identifiable, Equatable, Hashable, Codable, CustomStringConvertible {
    /// Zero-based index of this logical processor in the system.
    public let id: Int
    /// SMT thread index within the parent ``Core`` (0 for the first thread, 1 for the second, etc.).
    public let smtID: Int
    /// Linux-specific CPU identifier used for thread affinity (`cpu_set_t` bit index).
    /// `nil` on non-Linux platforms.
    public let linuxID: Int?

    public var description: String {
        "Processor \(id) (SMT \(smtID))"
    }

    init(_ pointer: UnsafePointer<cpuinfo_processor>, index: Int) {
        id    = index
        smtID = Int(pointer.pointee.smt_id)
        #if os(Linux)
        linuxID = Int(pointer.pointee.linux_id)
        #else
        linuxID = nil
        #endif
    }
}
