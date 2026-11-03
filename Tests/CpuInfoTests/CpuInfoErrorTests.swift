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

@Suite("CpuInfoError")
struct CpuInfoErrorTests {
    @Test("equatable by code and diagnostic")
    func equatable() {
        let plain = CpuInfoError(code: .initializationFailed)
        let same = CpuInfoError(code: .initializationFailed)
        let otherCode = CpuInfoError(code: .threadAffinityUnsupported)
        let withDiagnostic = CpuInfoError(code: .initializationFailed, diagnostic: "oops")
        #expect(plain == same)
        #expect(plain != otherCode)
        #expect(plain != withDiagnostic)
    }

    @Test("description includes label")
    func description() {
        let err = CpuInfoError(code: .initializationFailed)
        #expect(err.description.contains("initializationFailed"))
    }

    @Test("description includes diagnostic when present")
    func descriptionWithDiagnostic() {
        let err = CpuInfoError(code: .threadAffinityFailed, diagnostic: "returned 22")
        #expect(err.description.contains("threadAffinityFailed"))
        #expect(err.description.contains("returned 22"))
    }

    @Test("unknown code renders as code(N)")
    func unknownCodeRenders() {
        let err = CpuInfoError(code: .init(rawValue: 999))
        #expect(err.description.contains("999"))
    }
}
