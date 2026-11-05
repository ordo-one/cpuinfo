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

@testable import CpuInfo
#if os(macOS)
import Darwin
#endif
import Testing

@Suite("ProcessorInfo")
struct ProcessorInfoTests {
    let info: ProcessorInfo

    init() throws {
        info = try ProcessorInfo()
    }

    @Test("at least one package")
    func packageCount() {
        #expect(info.packages.count >= 1)
    }

    @Test("package has non-empty name")
    func packageName() {
        #expect(!info.packages[0].name.isEmpty)
    }

    @Test("at least one cluster")
    func clusterCount() {
        #expect(info.clusters.count >= 1)
    }

    @Test("cluster count matches sum across packages")
    func clusterConsistency() {
        let expected = info.packages.reduce(0) { $0 + $1.clusterCount }
        #expect(info.clusters.count == expected)
    }

    @Test("core count matches sum across packages")
    func coreConsistency() {
        let expected = info.packages.reduce(0) { $0 + $1.coreCount }
        #expect(info.cores.count == expected)
    }

    @Test("logical processor count >= core count")
    func hyperthreadingOrEqual() {
        #expect(info.logicalProcessors.count >= info.cores.count)
    }

    @Test("L1 data cache present with valid geometry")
    func l1d() {
        #expect(!info.caches.l1Data.isEmpty)
        #expect(info.caches.l1Data[0].size > 0)
        #expect(info.caches.l1Data[0].lineSize > 0)
    }

    @Test("L2 cache larger than L1d")
    func l2SizeOrdering() {
        guard !info.caches.l2.isEmpty else { return }
        #expect(info.caches.l2[0].size > info.caches.l1Data[0].size)
    }

    @Test("L2 and above are unified")
    func l2AndAboveUnified() {
        for cache in info.caches.l2 + info.caches.l3 + info.caches.l4 {
            #expect(cache.kind == .unified)
            #expect(cache.isUnified)
        }
    }

    @Test("every offset and count stays inside its array")
    func offsetsInRange() {
        func inRange(_ offset: Int, _ count: Int, _ total: Int) -> Bool {
            offset >= 0 && count >= 0 && offset + count <= total
        }
        let processors = info.logicalProcessors.count
        for package in info.packages {
            #expect(inRange(package.coreOffset, package.coreCount, info.cores.count))
            #expect(inRange(package.clusterOffset, package.clusterCount, info.clusters.count))
            #expect(inRange(package.logicalProcessorOffset, package.logicalProcessorCount, processors))
        }
        for cluster in info.clusters {
            #expect(inRange(cluster.coreOffset, cluster.coreCount, info.cores.count))
            #expect(inRange(cluster.logicalProcessorOffset, cluster.logicalProcessorCount, processors))
        }
        for core in info.cores {
            #expect(inRange(core.logicalProcessorOffset, core.logicalProcessorCount, processors))
        }
        let caches = info.caches.l1Data + info.caches.l1Instruction + info.caches.l2 + info.caches.l3 + info.caches.l4
        for cache in caches {
            #expect(inRange(cache.logicalProcessorOffset, cache.logicalProcessorCount, processors))
        }
    }

    @Test("Architecture.current is not unknown")
    func archNotUnknown() {
        #expect(Architecture.current != .unknown)
        #expect(Architecture.current.isARMFamily || Architecture.current.isX86Family)
    }

    #if os(Linux)
    @Test("currentCore returns a value on Linux")
    func currentCore() {
        #expect(ProcessorInfo.currentCore != nil)
    }

    @Test("currentLogicalProcessor returns a value on Linux")
    func currentLogicalProcessor() {
        #expect(ProcessorInfo.currentLogicalProcessor != nil)
    }
    #else
    @Test("currentCore returns nil on non-Linux")
    func currentCoreNonLinux() {
        #expect(ProcessorInfo.currentCore == nil)
    }

    @Test("currentLogicalProcessor returns nil on non-Linux")
    func currentLogicalProcessorNonLinux() {
        #expect(ProcessorInfo.currentLogicalProcessor == nil)
    }
    #endif

    // MARK: - current / init

    @Test("ProcessorInfo.current returns a valid snapshot")
    func currentReturnsValue() {
        #expect(ProcessorInfo.current.packages.count == info.packages.count)
    }

    @Test("repeated current access returns identical data")
    func currentIdempotent() {
        let first = ProcessorInfo.current
        let second = ProcessorInfo.current
        #expect(first == second)
    }

    @Test("init() and current return the same snapshot")
    func initAndCurrentAgree() throws {
        let viaInit = try ProcessorInfo()
        let viaCurrent = ProcessorInfo.current
        #expect(viaInit == viaCurrent)
    }

    #if os(macOS) || os(Linux)
    @Test("concurrent first access initializes once and agrees", .disabled(if: exitTestsLackSanitizer))
    func concurrentFirstAccess() async {
        // A fresh process, so the racing tasks hit the uninitialized cache.
        await #expect(processExitsWith: .success) {
            let results = await withTaskGroup(of: ProcessorInfo.self, returning: [ProcessorInfo].self) { group in
                for _ in 0..<50 {
                    group.addTask { ProcessorInfo.current }
                }
                return await group.reduce(into: []) { $0.append($1) }
            }
            precondition(results.count == 50 && results.allSatisfy { $0 == results[0] })
        }
    }

    @Test("current-CPU getters work as the first API call", .disabled(if: exitTestsLackSanitizer))
    func currentGettersBeforeInitialization() async {
        await #expect(processExitsWith: .success) {
            _ = ProcessorInfo.currentLogicalProcessor
        }
        await #expect(processExitsWith: .success) {
            _ = ProcessorInfo.currentCore
        }
    }
    #endif

    // MARK: - CustomStringConvertible

    @Test("description strings are non-empty")
    func descriptions() {
        #expect(!info.packages[0].description.isEmpty)
        #expect(!info.clusters[0].description.isEmpty)
        #expect(!info.cores[0].description.isEmpty)
        #expect(!info.logicalProcessors[0].description.isEmpty)
        #expect(!info.caches.l1Data[0].description.isEmpty)
        #expect(!Architecture.current.description.isEmpty)
    }

    @Test("package description matches name")
    func packageDescription() {
        #expect(info.packages[0].description == info.packages[0].name)
    }

    @Test("cluster description contains core count")
    func clusterDescription() {
        let cluster = info.clusters[0]
        #expect(cluster.description.contains("\(cluster.coreCount)"))
    }

    @Test("core description contains thread count")
    func coreDescription() {
        let core = info.cores[0]
        #expect(core.description.contains("\(core.logicalProcessorCount)"))
    }

    @Test("cache description contains size and line size")
    func cacheDescription() {
        let cache = info.caches.l1Data[0]
        #expect(cache.description.contains("\(cache.size)"))
        #expect(cache.description.contains("\(cache.lineSize)"))
    }

    @Test("CacheLevel.ID description format")
    func cacheLevelIDDescription() {
        let cacheID = info.caches.l1Data[0].id
        #expect(cacheID.description == "L\(cacheID.level)-\(cacheID.kind)-\(cacheID.index)")
    }

    // MARK: - Microarchitecture

    @Test("microarchitecture description is not empty")
    func microarchitectureDescription() {
        for cluster in info.clusters {
            #expect(!"\(cluster.microarchitecture)".isEmpty)
        }
    }

    @Test("known microarchitectures have specific descriptions")
    func microarchitectureKnownDescriptions() {
        #expect(Microarchitecture.unknown.description == "Unknown")
        #expect(Microarchitecture.zen4.description.contains("Zen 4"))
        #expect(Microarchitecture.cortexA78.description.contains("Cortex-A78"))
        #expect(Microarchitecture.firestorm.description.contains("Firestorm"))
        #expect(Microarchitecture.haswell.description.contains("Haswell"))
        #expect(Microarchitecture.gracemont.description.contains("Gracemont"))
    }

    // MARK: - Architecture

    @Test("x86 family detection")
    func architectureX86Family() {
        #expect(Architecture.x86.isX86Family)
        #expect(Architecture.x86_64.isX86Family)
        #expect(!Architecture.x86.isARMFamily)
        #expect(!Architecture.x86_64.isARMFamily)
    }

    @Test("ARM family detection")
    func architectureARMFamily() {
        #expect(Architecture.arm.isARMFamily)
        #expect(Architecture.arm64.isARMFamily)
        #expect(!Architecture.arm.isX86Family)
        #expect(!Architecture.arm64.isX86Family)
    }

    @Test("unknown architecture is neither family")
    func architectureUnknownFamily() {
        #expect(!Architecture.unknown.isX86Family)
        #expect(!Architecture.unknown.isARMFamily)
    }
}

#if os(macOS)
// SwiftPM dlopens the test bundle on macOS, so an exit-test child aborts with "Interceptors are not working" under ASan.
private let exitTestsLackSanitizer = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "__asan_init") != nil // RTLD_DEFAULT
#elseif os(Linux)
private let exitTestsLackSanitizer = false
#endif
