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
    @Suite("ISA")
    struct ISATests {
        let info: ProcessorInfo

        init() throws {
            info = try ProcessorInfo()
        }

        @Test("each ISA flag decodes from its own key, and a missing flag decodes as false")
        func flagDecoding() throws {
            // An older snapshot lacks the flags added since. Set one flag at a time on a snapshot that has
            // no others, so every hand-written decoder line is checked against its own key, for both
            // architectures on any host.
            for (key, group) in try architectureGroups() {
                let skeleton = [key: droppingFlags(group)]
                let paths = flagPaths(group).map { [key] + $0 }.sorted { $0.lexicographicallyPrecedes($1) }
                #expect(paths.count > 10)
                for path in paths {
                    let decoded = try decodeISA(setting(skeleton, at: path, to: true))
                    // Read the result by property name rather than through the encoder, so that two flags
                    // with swapped keys fail too.
                    let features: Any = key == "x86" ? decoded.x86 : decoded.arm
                    let setFlags = propertyPaths(features).filter { property(features, at: $0) as? Bool == true }
                    #expect(setFlags.map { [key] + $0 } == [path])
                }
                // An explicit null or a missing feature group is a corrupt snapshot, not an old one.
                #expect(throws: DecodingError.self) { try decodeISA(setting(skeleton, at: paths[0], to: NSNull())) }
                #expect(throws: DecodingError.self) { try decodeISA([key: [String: Any]()]) }
            }
        }

        @Test("a snapshot from either architecture decodes, the other one reading all false")
        func eitherArchitectureDecodes() throws {
            for (key, group) in try architectureGroups() {
                #expect(flagPaths(group).allSatisfy { flag(group, at: $0) == false })
                let allTrue = flagPaths(group).reduce(group) { setting($0, at: $1, to: true) }
                let decoded = try decodeISA([key: allTrue])
                let reencoded = try JSONSerialization.jsonObject(with: JSONEncoder().encode(decoded))
                #expect((reencoded as? [String: Any])?.keys.sorted() == [key])
                #expect(flagPaths(reencoded).allSatisfy { flag(reencoded, at: $0) == true })
                #expect(key == "x86" ? decoded.arm == .unavailable : decoded.x86 == .unavailable)
                #expect(decoded.architecture == (key == "x86" ? .x86_64 : .arm64))
            }
            #expect(throws: DecodingError.self) { try decodeISA([String: Any]()) }
            let bothArchitectures = try Dictionary(uniqueKeysWithValues: architectureGroups())
            #expect(throws: DecodingError.self) { try decodeISA(bothArchitectures) }
        }

        @Test("encoded ISA keys are the stored property names")
        func encodedKeysArePropertyNames() throws {
            // CodingKeys are declared by hand, so check them against the properties rather than the encoder.
            let groups = try architectureGroups()
            #expect(Set(propertyPaths(X86Features.unavailable)) == Set(flagPaths(groups[0].1)))
            #expect(Set(propertyPaths(ARMFeatures.unavailable)) == Set(flagPaths(groups[1].1)))
        }

        @Test("a live snapshot encodes only the architecture it was taken on")
        func liveSnapshotEncodesHostOnly() throws {
            let keys = try (JSONSerialization.jsonObject(with: JSONEncoder().encode(info.isa)) as? [String: Any])?.keys
            #if arch(x86_64) || arch(i386)
            #expect(keys?.sorted() == ["x86"])
            #expect(info.isa.arm == .unavailable)
            #expect(info.isa.architecture == .x86_64)
            #elseif arch(arm64) || arch(arm)
            #expect(keys?.sorted() == ["arm"])
            #expect(info.isa.x86 == .unavailable)
            #expect(info.isa.architecture == .arm64)
            #endif
        }

        #if os(macOS) || os(Linux)
        @Test("every ARM and x86 cpuinfo_has_* query in cpuinfo.h is exposed, or left out on purpose")
        func everyQueryExposedOrLeftOut() throws {
            let header = try repositoryFile("Sources/_cpuinfo/include/cpuinfo.h")
            let queries = Set(header.matches(of: #/static inline bool (cpuinfo_has_(?:arm|x86)_\w+)\(void\)/#)
                .map { String($0.output.1) })
            let swift = try repositoryFile("Sources/CpuInfo/ISA/ARMFeatures.swift")
                + repositoryFile("Sources/CpuInfo/ISA/X86Features.swift")
            let exposed = Set(swift.matches(of: #/cpuinfo_has_(?:arm|x86)_\w+/#).map { String($0.output) })
            let leftOut = Set(Self.leftOut.map { "cpuinfo_has_\($0)" })
            #expect(queries.count > 50)
            #expect(queries.subtracting(exposed).subtracting(leftOut).isEmpty,
                    "New queries to expose or list in leftOut: \(queries.subtracting(exposed).subtracting(leftOut))")
            #expect(leftOut.subtracting(queries).isEmpty, "Gone from cpuinfo.h: \(leftOut.subtracting(queries))")
            #expect(leftOut.isDisjoint(with: exposed), "Exposed after all: \(leftOut.intersection(exposed))")
        }

        /// Queries for ARM32-only and legacy x86 extensions that the Swift API leaves out on purpose.
        static let leftOut: Set<String> = [
            "arm_idiv", "arm_thumb", "arm_thumb2", "arm_v5e", "arm_v6", "arm_v6k", "arm_v7", "arm_v7mp", "arm_v8",
            "arm_vfpv2", "arm_vfpv3", "arm_vfpv3_d32", "arm_vfpv3_fp16", "arm_vfpv3_fp16_d32", "arm_vfpv4",
            "arm_vfpv4_d32", "arm_wmmx", "arm_wmmx2",
            "x86_3dnow", "x86_3dnow_geode", "x86_3dnow_plus", "x86_clzero", "x86_cmpxchg16b", "x86_cmpxchg8b",
            "x86_daz", "x86_fpu", "x86_fxsave", "x86_lahf_sahf", "x86_misaligned_sse", "x86_mmx", "x86_mmx_plus",
            "x86_mpx", "x86_mwait", "x86_mwaitx", "x86_prefetch", "x86_prefetchw", "x86_prefetchwt1", "x86_tbm",
            "x86_xop", "x86_xsave", "x86_xtest"
        ]
        #endif

        #if arch(x86_64)
        @Test("SSE2 always present on x86-64")
        func sse2AlwaysPresent() {
            #expect(info.isa.x86.sse.sse2)
        }
        #endif

        #if arch(arm64)
        @Test("NEON always present on ARM64")
        func neonAlwaysPresent() {
            #expect(info.isa.arm.neon.neon)
        }
        #endif
    }
}

/// Each architecture's top-level key with its encoded flags, all `false`.
private func architectureGroups() throws -> [(String, Any)] {
    try [
        ("x86", JSONSerialization.jsonObject(with: JSONEncoder().encode(X86Features.unavailable))),
        ("arm", JSONSerialization.jsonObject(with: JSONEncoder().encode(ARMFeatures.unavailable)))
    ]
}

/// Each stored property's path in a feature struct, found by reflection rather than through `Codable`.
private func propertyPaths(_ value: Any, _ prefix: [String] = []) -> [[String]] {
    let children = Mirror(reflecting: value).children
    guard !children.isEmpty else { return [prefix] }
    return children.flatMap { propertyPaths($0.value, prefix + [$0.label ?? "?"]) }
}

private func property(_ value: Any, at path: [String]) -> Any? {
    guard let name = path.first else { return value }
    return Mirror(reflecting: value).children.first { $0.label == name }
        .flatMap { property($0.value, at: Array(path.dropFirst())) }
}

/// Each flag's key path in an encoded ISA snapshot, such as `["arm", "sve", "sve2p1"]`.
private func flagPaths(_ value: Any, _ prefix: [String] = []) -> [[String]] {
    guard let dict = value as? [String: Any] else { return [prefix] }
    return dict.flatMap { flagPaths($1, prefix + [$0]) }
}

private func droppingFlags(_ value: Any) -> Any {
    guard let dict = value as? [String: Any] else { return value }
    return dict.compactMapValues { $0 is [String: Any] ? droppingFlags($0) : nil }
}

private func setting(_ value: Any, at path: [String], to newValue: Any) -> Any {
    guard let key = path.first else { return newValue }
    var dict = value as? [String: Any] ?? [:]
    dict[key] = setting(dict[key] as Any, at: Array(path.dropFirst()), to: newValue)
    return dict
}

private func flag(_ value: Any, at path: [String]) -> Bool? {
    guard let key = path.first else { return value as? Bool }
    return (value as? [String: Any])?[key].flatMap { flag($0, at: Array(path.dropFirst())) }
}

private func decodeISA(_ object: Any) throws -> ISAFeatures {
    try JSONDecoder().decode(ISAFeatures.self, from: JSONSerialization.data(withJSONObject: object))
}
