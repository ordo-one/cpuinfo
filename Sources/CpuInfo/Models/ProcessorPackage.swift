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

/// A physical processor package (socket).
///
/// On desktop and laptop systems there is typically one package. Multi-socket
/// server systems may have two or more. Each package contains one or more
/// clusters, cores, and logical processors.
///
/// - Example:
/// ```swift
/// if let pkg = ProcessorInfo.current.packages.first {
///     print("\(pkg.name): \(pkg.coreCount) cores, \(pkg.logicalProcessorCount) threads")
/// }
/// ```
public struct ProcessorPackage: Sendable, Identifiable, Equatable, Hashable, Codable, CustomStringConvertible {
    /// Zero-based index of this package in the system.
    public let id: Int
    /// Marketing or model name of the processor (e.g. "Apple M2 Pro").
    public let name: String
    /// Number of physical cores in this package.
    public let coreCount: Int
    /// Number of clusters in this package.
    public let clusterCount: Int
    /// Number of logical processors (hardware threads) in this package.
    public let logicalProcessorCount: Int
    /// Index of the first core belonging to this package in ``ProcessorInfo/cores``.
    public let coreOffset: Int
    /// Index of the first cluster belonging to this package in ``ProcessorInfo/clusters``.
    public let clusterOffset: Int
    /// Index of the first logical processor belonging to this package in ``ProcessorInfo/logicalProcessors``.
    public let logicalProcessorOffset: Int

    /// Index of the first logical processor belonging to this package in ``ProcessorInfo/logicalProcessors``.
    @available(*, deprecated, renamed: "logicalProcessorOffset")
    public var processorOffset: Int { logicalProcessorOffset }

    public var description: String { name }

    // Keeps the pre-rename JSON key so existing snapshots still decode.
    private enum CodingKeys: String, CodingKey {
        case id, name, coreCount, clusterCount, logicalProcessorCount, coreOffset, clusterOffset
        case logicalProcessorOffset = "processorOffset"
    }

    init(_ pointer: UnsafePointer<cpuinfo_package>, index: Int) {
        id = index
        var pkg = pointer.pointee
        name                  = stringFromFixedCString(&pkg.name)
        coreCount             = Int(pkg.core_count)
        clusterCount          = Int(pkg.cluster_count)
        logicalProcessorCount = Int(pkg.processor_count)
        coreOffset            = Int(pkg.core_start)
        clusterOffset         = Int(pkg.cluster_start)
        logicalProcessorOffset = Int(pkg.processor_start)
    }
}
