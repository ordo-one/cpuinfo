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

extension ProcessorInfoTests {
    @Suite("TSCInfo")
    struct TSCInfoTests {
        #if arch(x86_64)
        @Test("ProcessorInfo.tsc returns plausible values on x86_64")
        func tscInfoX86() throws {
            let info = try ProcessorInfo()
            if let tsc = info.tsc {
                #expect(tsc.denominator > 0)
                #expect(tsc.numerator > 0)
                #expect(!tsc.description.isEmpty)
            }
            // nil is acceptable on AMD or older Intel — no failure
        }

        @Test("ProcessorInfo.frequency returns plausible values on x86_64")
        func frequencyInfoX86() throws {
            let info = try ProcessorInfo()
            if let freq = info.frequency {
                #expect(freq.baseFrequencyMHz > 0)
                #expect(freq.baseFrequencyHz != nil)
                #expect(!freq.description.isEmpty)
            }
        }

        @Test("core frequency populated when frequency info is available")
        func coreFrequencyFromLeaf16() throws {
            let info = try ProcessorInfo()
            if info.frequency != nil {
                #expect(info.cores[0].frequency != nil)
            }
        }
        #endif

        @Test("description rounds MHz to one decimal")
        func megahertzFormatting() {
            #expect(TSCInfo.megahertz(19_200_000) == "19.2")
            #expect(TSCInfo.megahertz(2_399_960_000) == "2400.0")
            #expect(TSCInfo.megahertz(25_000_000) == "25.0")
        }

        #if arch(arm64)
        @Test("ProcessorInfo.tsc is nil on ARM64")
        func tscInfoARM() throws {
            let info = try ProcessorInfo()
            #expect(info.tsc == nil)
        }

        @Test("ProcessorInfo.frequency is nil on ARM64")
        func frequencyInfoARM() throws {
            let info = try ProcessorInfo()
            #expect(info.frequency == nil)
        }
        #endif
    }
}
