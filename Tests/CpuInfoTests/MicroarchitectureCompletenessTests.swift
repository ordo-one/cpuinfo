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

import Testing
@testable import CpuInfo

@Suite("Microarchitecture mapping completeness")
struct MicroarchitectureCompletenessTests {
    /// Every known upstream cpuinfo uarch enumerator must have a specific
    /// description string — never the `Unknown (0x…)` fallthrough. This
    /// catches vendor bumps that introduce new microarchitectures without
    /// a corresponding Swift mapping update.
    @Test("every known Swift Microarchitecture case has a specific description")
    func everyKnownCaseDescribed() {
        for uarch in Microarchitecture.allCases {
            let desc = uarch.description
            if uarch == .unknown {
                #expect(desc == "Unknown")
            } else {
                let hex = String(uarch.rawValue, radix: 16)
                #expect(!desc.hasPrefix("Unknown"),
                        "Microarchitecture \(uarch) (0x\(hex)) falls through to generic Unknown")
            }
        }
    }

    // Reads cpuinfo.h from the source checkout, which only host-side runs have.
    #if os(macOS) || os(Linux)
    @Test("every cpuinfo_uarch_* enumerator in cpuinfo.h has a Swift case, and vice versa")
    func headerMatchesSwiftCases() throws {
        let text = try repositoryFile("Sources/_cpuinfo/include/cpuinfo.h")
        let headerValues = Set(text.matches(of: #/cpuinfo_uarch_\w+ = (0x[0-9A-Fa-f]+|0),/#).compactMap { match in
            UInt32(match.output.1.replacing("0x", with: ""), radix: 16)
        })
        let swiftValues = Set(Microarchitecture.allCases.map(\.rawValue))
        #expect(headerValues.count > 100)
        let missing = headerValues.subtracting(swiftValues)
        let extra = swiftValues.subtracting(headerValues)
        #expect(missing.isEmpty, "Missing Swift cases: \(missing)")
        #expect(extra.isEmpty, "Swift cases not in cpuinfo.h: \(extra)")
    }
    #endif
}
