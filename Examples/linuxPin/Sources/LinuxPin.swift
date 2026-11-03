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

import CpuInfo

/// Demonstrates pinning the current thread to all logical processors
/// sharing the same L2 cache, using the Swift-native CPUSet API.
public enum LinuxPin {

    /// The result of a successful pinning operation.
    public struct PinResult: Sendable {
        /// The Linux CPU IDs the thread asked to be pinned to.
        public let pinnedLinuxCPUs: [Int]
        /// The mask the kernel enforces after the call; a cpuset can narrow it below the request.
        public let effectiveLinuxCPUs: [Int]
        /// The L2 cache that was used to determine the pin set.
        public let l2Cache: CacheLevel
    }

    /// Pin the calling thread to all logical processors sharing the same L2
    /// cache as the current processor. Returns the pin result, or throws
    /// if the current processor cannot be determined, no matching L2 cache
    /// exists, or the kernel rejects the affinity call.
    ///
    /// On non-Linux platforms this throws ``LinuxPinError/noCurrentProcessor``,
    /// since the current processor is unknown there.
    public static func pinToL2() throws -> PinResult {
        let info = try ProcessorInfo()

        guard let processor = ProcessorInfo.currentLogicalProcessor else {
            throw LinuxPinError.noCurrentProcessor
        }

        guard let currentL2 = info.caches.l2.first(where: {
            ($0.logicalProcessorOffset ..< $0.logicalProcessorOffset + $0.logicalProcessorCount)
                .contains(processor.id)
        }) else {
            throw LinuxPinError.noMatchingCache
        }

        let start = currentL2.logicalProcessorOffset
        let end = start + currentL2.logicalProcessorCount
        let pinnedIDs = (start ..< end).compactMap { info.logicalProcessors[$0].linuxID }

        try ProcessorInfo.setCurrentThreadAffinity(CPUSet(pinnedIDs))
        let effective = ProcessorInfo.currentThreadAffinity?.sortedCPUs ?? []
        return PinResult(pinnedLinuxCPUs: pinnedIDs, effectiveLinuxCPUs: effective, l2Cache: currentL2)
    }

    /// Entry point for the executable — prints diagnostics.
    public static func run() {
        do {
            _ = try ProcessorInfo()
        } catch {
            print("Error: \(error)")
            return
        }

        guard let processor = ProcessorInfo.currentLogicalProcessor else {
            print("Error: Could not determine the current logical processor.")
            print("  (Requires Linux with sched_getcpu() support — run inside a Linux container.)")
            return
        }

        print("Current logical processor: \(processor.id) (SMT thread \(processor.smtID))")
        if let linuxID = processor.linuxID {
            print("Linux CPU ID:              \(linuxID)")
        }
        if let allowed = ProcessorInfo.currentThreadAffinity {
            print("Allowed CPU mask:          \(allowed.sortedCPUs)")
        }

        let result: PinResult
        do {
            result = try pinToL2()
        } catch {
            print("Error: \(error)")
            return
        }

        print()
        print("L2 cache:                  \(result.l2Cache.size / 1024) KiB, \(result.l2Cache.associativity)-way")
        print("Logical processors sharing this L2: \(result.l2Cache.logicalProcessorCount)")
        print()
        print("Requested Linux CPUs: \(result.pinnedLinuxCPUs)")
        print("Effective Linux CPUs: \(result.effectiveLinuxCPUs)")

        if let after = ProcessorInfo.currentLogicalProcessor {
            let afterLinuxID = after.linuxID.map(String.init) ?? "?"
            print("Now running on logical processor: \(after.id) (Linux CPU \(afterLinuxID))")

            let allowed = result.effectiveLinuxCPUs.contains { $0 == after.linuxID }
            print("Verified on pinned CPU: \(allowed ? "yes" : "no")")
        }
    }
}

/// Errors specific to the linuxPin example.
public enum LinuxPinError: Error, CustomStringConvertible {
    case noCurrentProcessor
    case noMatchingCache

    public var description: String {
        switch self {
        case .noCurrentProcessor: "Could not determine the current logical processor (requires Linux)."
        case .noMatchingCache:    "No L2 cache covers the current logical processor."
        }
    }
}
