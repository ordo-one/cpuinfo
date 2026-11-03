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

import Foundation
import Testing
@testable import CpuInfo

@Suite("CPUSet")
struct CPUSetTests {
    @Test("empty set has count zero")
    func empty() {
        let set = CPUSet()
        #expect(set.isEmpty)
        #expect(set.count == 0)
        #expect(set.sortedCPUs == [])
    }

    @Test("array-literal initialization")
    func arrayLiteral() {
        let set: CPUSet = [3, 1, 4, 1, 5, 9]
        #expect(set.count == 5) // 1 de-duplicated
        #expect(set.sortedCPUs == [1, 3, 4, 5, 9])
    }

    @Test("sequence initializer")
    func sequenceInit() {
        let set = CPUSet([0, 2, 4, 6, 8])
        #expect(set.count == 5)
        #expect(set.contains(4))
        #expect(!set.contains(5))
    }

    @Test("insert returns inserted-flag")
    func insert() {
        var set = CPUSet()
        let firstInsert = set.insert(7)
        #expect(firstInsert.inserted == true)
        #expect(firstInsert.memberAfterInsert == 7)
        let secondInsert = set.insert(7)
        #expect(secondInsert.inserted == false)
    }

    @Test("remove returns removed element or nil")
    func remove() {
        var set: CPUSet = [1, 2, 3]
        #expect(set.remove(2) == 2)
        #expect(set.remove(2) == nil)
        #expect(set.sortedCPUs == [1, 3])
    }

    @Test("update replaces existing element")
    func update() {
        var set: CPUSet = [1, 2, 3]
        #expect(set.update(with: 2) == 2) // already there
        #expect(set.update(with: 4) == nil) // new
        #expect(set.sortedCPUs == [1, 2, 3, 4])
    }

    @Test("union, intersection, symmetric difference")
    func setAlgebra() {
        let lower: CPUSet = [1, 2, 3]
        let upper: CPUSet = [3, 4, 5]
        #expect(lower.union(upper).sortedCPUs == [1, 2, 3, 4, 5])
        #expect(lower.intersection(upper).sortedCPUs == [3])
        #expect(lower.symmetricDifference(upper).sortedCPUs == [1, 2, 4, 5])
    }

    @Test("formUnion / formIntersection / formSymmetricDifference mutate in place")
    func inPlaceSetAlgebra() {
        var grown: CPUSet = [1, 2, 3]
        grown.formUnion([3, 4])
        #expect(grown.sortedCPUs == [1, 2, 3, 4])

        var narrowed: CPUSet = [1, 2, 3, 4]
        narrowed.formIntersection([2, 4, 6])
        #expect(narrowed.sortedCPUs == [2, 4])

        var toggled: CPUSet = [1, 2, 3]
        toggled.formSymmetricDifference([2, 3, 4])
        #expect(toggled.sortedCPUs == [1, 4])
    }

    @Test("isSubset / isSuperset from SetAlgebra defaults")
    func subsetSuperset() {
        let small: CPUSet = [1, 2]
        let large: CPUSet = [1, 2, 3]
        #expect(small.isSubset(of: large))
        #expect(large.isSuperset(of: small))
        #expect(!small.isSuperset(of: large))
    }

    @Test("equatable")
    func equatable() {
        #expect(CPUSet([1, 2, 3]) == CPUSet([3, 2, 1]))
        #expect(CPUSet([1, 2, 3]) != CPUSet([1, 2]))
    }

    @Test("hashable — equal sets hash equally")
    func hashable() {
        let ascending: CPUSet = [1, 2, 3]
        let descending: CPUSet = [3, 2, 1]
        #expect(ascending.hashValue == descending.hashValue)
    }

    @Test("iterates elements")
    func iterating() {
        let set: CPUSet = [10, 20, 30]
        var seen: Set<Int> = []
        for cpu in set { seen.insert(cpu) }
        #expect(seen == [10, 20, 30])
    }

    @Test("description lists sorted CPUs")
    func description() {
        let set: CPUSet = [5, 3, 9, 1]
        #expect(set.description == "CPUSet(1, 3, 5, 9)")
    }

    // MARK: Thread affinity

    #if os(Linux)
    @Test("currentThreadAffinity returns a non-empty CPUSet on Linux")
    func currentThreadAffinityLinux() {
        let set = ProcessorInfo.currentThreadAffinity
        #expect(set != nil)
        #expect(set?.isEmpty == false,
                "Every thread has at least one allowed CPU")
    }

    @Test("setCurrentThreadAffinity pins the thread and reads back exactly the pinned set")
    func affinityRoundTripLinux() async throws {
        let (id, mask, after) = try await onDedicatedThread { () throws(CpuInfoError) in
            let id = ProcessorInfo.currentLogicalProcessor?.linuxID
            if let id { try ProcessorInfo.setCurrentThreadAffinity(CPUSet([id])) }
            return (id, ProcessorInfo.currentThreadAffinity, ProcessorInfo.currentLogicalProcessor?.linuxID)
        }
        try #require(id != nil)
        #expect(mask == CPUSet([id!]))
        #expect(after == id)
    }

    @Test("empty CPUSet on Linux is rejected by the kernel")
    func emptySetRejected() throws {
        #expect(throws: CpuInfoError.self) { try ProcessorInfo.setCurrentThreadAffinity(CPUSet()) }
    }

    @Test("pinning to a CPU that is not online is rejected by the kernel")
    func offlineCPURejected() async throws {
        guard let id = offlineCPUID() else { return }
        // Dedicated thread: if the kernel accepts the ID anyway, no shared worker stays pinned.
        let error = await #expect(throws: CpuInfoError.self) {
            try await onDedicatedThread { () throws(CpuInfoError) in
                try ProcessorInfo.setCurrentThreadAffinity(CPUSet([id]))
            }
        }
        #expect(error?.code == .threadAffinityFailed)
        #expect(error?.diagnostic?.contains("errno") == true)
    }

    @Test("CPU IDs outside 0..<CPU_SETSIZE are rejected before the syscall")
    func outOfRangeCPURejected() {
        let error = #expect(throws: CpuInfoError.self) {
            try ProcessorInfo.setCurrentThreadAffinity(CPUSet([0, -1, 4096]))
        }
        #expect(error?.code == .threadAffinityFailed)
        #expect(error?.diagnostic?.contains("[-1, 4096]") == true)
    }
    #else
    @Test("currentThreadAffinity returns nil on non-Linux")
    func currentThreadAffinityNonLinux() {
        #expect(ProcessorInfo.currentThreadAffinity == nil)
    }

    @Test("setCurrentThreadAffinity throws .threadAffinityUnsupported on non-Linux")
    func affinityUnsupported() throws {
        let error = #expect(throws: CpuInfoError.self) { try ProcessorInfo.setCurrentThreadAffinity(CPUSet([0])) }
        #expect(error?.code == .threadAffinityUnsupported)
    }
    #endif
}

#if os(Linux)
/// One past the highest online Linux CPU ID, or `nil` if that is outside `cpu_set_t`.
private func offlineCPUID() -> Int? {
    let id = (ProcessorInfo.current.logicalProcessors.compactMap(\.linuxID).max() ?? -1) + 1
    return id < 1024 ? id : nil
}

/// Runs `body` on a new thread, so affinity it sets dies with that thread instead of pinning a shared test worker.
private func onDedicatedThread<T: Sendable>(
    _ body: @escaping @Sendable () throws(CpuInfoError) -> T
) async throws(CpuInfoError) -> T {
    let result = await withCheckedContinuation { (continuation: CheckedContinuation<Result<T, CpuInfoError>, Never>) in
        Thread { continuation.resume(returning: Result { () throws(CpuInfoError) in try body() }) }.start()
    }
    return try result.get()
}
#endif
