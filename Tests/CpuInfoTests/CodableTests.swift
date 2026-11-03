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

extension ProcessorInfoTests {
    // MARK: - Codable round-trip

    @Test("ProcessorInfo survives JSON round-trip")
    func codableRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(info)
        let decoded = try decoder.decode(ProcessorInfo.self, from: data)
        #expect(decoded.packages == info.packages)
        #expect(decoded.clusters == info.clusters)
        #expect(decoded.cores == info.cores)
        #expect(decoded.logicalProcessors == info.logicalProcessors)
        #expect(decoded.caches == info.caches)
        #expect(decoded.isa == info.isa)
        #expect(decoded.tsc == info.tsc)
        #expect(decoded.frequency == info.frequency)
    }

    @Test("individual model types survive JSON round-trip")
    func codableModelTypes() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let pkgData = try encoder.encode(info.packages[0])
        let pkgDecoded = try decoder.decode(ProcessorPackage.self, from: pkgData)
        #expect(pkgDecoded == info.packages[0])

        let clusterData = try encoder.encode(info.clusters[0])
        let clusterDecoded = try decoder.decode(Cluster.self, from: clusterData)
        #expect(clusterDecoded == info.clusters[0])

        let coreData = try encoder.encode(info.cores[0])
        let coreDecoded = try decoder.decode(Core.self, from: coreData)
        #expect(coreDecoded == info.cores[0])

        let lpData = try encoder.encode(info.logicalProcessors[0])
        let lpDecoded = try decoder.decode(LogicalProcessor.self, from: lpData)
        #expect(lpDecoded == info.logicalProcessors[0])

        let cacheData = try encoder.encode(info.caches)
        let cacheDecoded = try decoder.decode(CacheHierarchy.self, from: cacheData)
        #expect(cacheDecoded == info.caches)

        let levelData = try encoder.encode(info.caches.l1Data[0])
        let levelDecoded = try decoder.decode(CacheLevel.self, from: levelData)
        #expect(levelDecoded == info.caches.l1Data[0])

        let isaData = try encoder.encode(info.isa)
        let isaDecoded = try decoder.decode(ISAFeatures.self, from: isaData)
        #expect(isaDecoded == info.isa)

        if let tsc = info.tsc {
            let tscData = try encoder.encode(tsc)
            let tscDecoded = try decoder.decode(TSCInfo.self, from: tscData)
            #expect(tscDecoded == tsc)
        }

        if let freq = info.frequency {
            let freqData = try encoder.encode(freq)
            let freqDecoded = try decoder.decode(ProcessorFrequencyInfo.self, from: freqData)
            #expect(freqDecoded == freq)
        }
    }

    @Test("unknown microarchitecture raw value decodes as .unknown")
    func microarchitectureDecodesUnknown() throws {
        let decoded = try JSONDecoder().decode([Microarchitecture].self, from: Data("[4294967295, 2097420]".utf8))
        #expect(decoded == [.unknown, .zen4])
    }

    @Test("unknown architecture raw value decodes as .unknown")
    func architectureDecodesUnknown() throws {
        let decoded = try JSONDecoder().decode([Architecture].self, from: Data(#"["riscv64", "arm64"]"#.utf8))
        #expect(decoded == [.unknown, .arm64])
    }

    #if os(macOS) || os(Linux)
    @Test("snapshots written by 2.2.0 decode on any host and re-encode unchanged",
          arguments: ["arm64-macos", "x86_64-linux"])
    func releasedSnapshotsDecode(_ name: String) throws {
        let fixture = Data(try repositoryFile("Tests/Fixtures/processorinfo-2.2.0-\(name).json").utf8)
        let decoded = try JSONDecoder().decode(ProcessorInfo.self, from: fixture)
        func canonical(_ data: Data) throws -> Data {
            try JSONSerialization.data(withJSONObject: JSONSerialization.jsonObject(with: data), options: .sortedKeys)
        }
        #expect(try canonical(JSONEncoder().encode(decoded)) == canonical(fixture))
        #expect(decoded.isa.architecture == (name.hasPrefix("arm64") ? .arm64 : .x86_64))
        // Apple Silicon reports no cache flags, so its L2 is unified by position alone.
        if name == "arm64-macos" {
            #expect(decoded.caches.l2.allSatisfy { $0.isUnified && $0.flags.isEmpty })
        }
    }
    #endif

    @Test("ProcessorPackage keeps the processorOffset JSON key")
    func packageOffsetKey() throws {
        let json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(info.packages[0])) as? [String: Any]
        #expect(json?["processorOffset"] as? Int == info.packages[0].logicalProcessorOffset)
        #expect(json?["logicalProcessorOffset"] == nil)
    }

    // MARK: - Equatable / Hashable

    @Test("equal values produce equal hashes")
    func hashConsistency() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(info)
        let decoded = try decoder.decode(ProcessorInfo.self, from: data)

        #expect(decoded.packages[0].hashValue == info.packages[0].hashValue)
        #expect(decoded.clusters[0].hashValue == info.clusters[0].hashValue)
        #expect(decoded.cores[0].hashValue == info.cores[0].hashValue)
        #expect(decoded.logicalProcessors[0].hashValue == info.logicalProcessors[0].hashValue)
        #expect(decoded.caches.hashValue == info.caches.hashValue)
        #expect(decoded.caches.l1Data[0].hashValue == info.caches.l1Data[0].hashValue)
        #expect(decoded.isa.hashValue == info.isa.hashValue)
        #expect(decoded.tsc?.hashValue == info.tsc?.hashValue)
        #expect(decoded.frequency?.hashValue == info.frequency?.hashValue)
    }

    @Test("distinct values are not equal")
    func inequalityCheck() throws {
        let decoder = JSONDecoder()
        let json = #"{"id":%d,"microarchitecture":0,"logicalProcessorCount":1,"logicalProcessorOffset":%d}"#
        let first = try decoder.decode(Core.self, from: Data(String(format: json, 0, 0).utf8))
        let second = try decoder.decode(Core.self, from: Data(String(format: json, 1, 1).utf8))
        #expect(first != second)
    }
}
