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

private struct Bytes4 {
    var byte0: UInt8, byte1: UInt8, byte2: UInt8, byte3: UInt8
}

@Suite("stringFromFixedCString")
struct StringFromFixedCStringTests {

    @Test("all-zero buffer returns empty string")
    func allZero() {
        var buffer = Bytes4(byte0: 0, byte1: 0, byte2: 0, byte3: 0)
        #expect(stringFromFixedCString(&buffer) == "")
    }

    @Test("normal null-terminated string")
    func normalNullTerminated() {
        var buffer = Bytes4(byte0: 0x48, byte1: 0x69, byte2: 0, byte3: 0)
        #expect(stringFromFixedCString(&buffer) == "Hi")
    }

    @Test("full buffer with no null terminator reads entire buffer")
    func fullBufferNoNull() {
        var buffer = Bytes4(byte0: 0x41, byte1: 0x42, byte2: 0x43, byte3: 0x44)
        #expect(stringFromFixedCString(&buffer) == "ABCD")
    }

    @Test("single character followed by null")
    func singleChar() {
        var tuple: (UInt8, UInt8) = (0x41, 0)
        #expect(stringFromFixedCString(&tuple) == "A")
    }
}

@Suite("safeRange")
struct SafeRangeTests {

    @Test("zero count returns empty range")
    func zeroCount() {
        #expect(safeRange(0) == 0..<0)
    }

    @Test("count of 5 returns 0..<5")
    func fiveCount() {
        #expect(safeRange(5) == 0..<5)
    }

    @Test("count of 1 returns 0..<1")
    func oneCount() {
        #expect(safeRange(1) == 0..<1)
    }
}
