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
@testable import LsCpuLib

#if os(macOS) || os(Linux)
@Test func lscpuPrintsSections() async throws {
    let result = try #require(await #expect(processExitsWith: .success, observing: [\.standardOutputContent]) {
        LsCpu.run()
    })
    // swiftlint:disable:next optional_data_string_conversion
    let output = String(decoding: result.standardOutputContent, as: UTF8.self)
    for section in ["System Processor Information", "--- Topology Summary", "--- Cache Hierarchy", "  L1d (Data)"] {
        #expect(output.contains(section), "missing \(section)")
    }
}
#endif

@Suite("formatBytes")
struct FormatBytesTests {
    @Test("formats bytes below 1 KiB")
    func bytesOnly() {
        #expect(LsCpu.formatBytes(512) == "512 B")
        #expect(LsCpu.formatBytes(0) == "0 B")
    }

    @Test("formats exact KiB values")
    func exactKiB() {
        #expect(LsCpu.formatBytes(1024) == "1 KiB")
        #expect(LsCpu.formatBytes(64 * 1024) == "64 KiB")
    }

    @Test("formats fractional KiB values")
    func fractionalKiB() {
        #expect(LsCpu.formatBytes(1536) == "1.5 KiB")
    }

    @Test("formats exact MiB values")
    func exactMiB() {
        #expect(LsCpu.formatBytes(1024 * 1024) == "1 MiB")
        #expect(LsCpu.formatBytes(4 * 1024 * 1024) == "4 MiB")
    }

    @Test("formats fractional MiB values")
    func fractionalMiB() {
        #expect(LsCpu.formatBytes(1536 * 1024) == "1.5 MiB")
    }
}

@Suite("formatFrequency")
struct FormatFrequencyTests {
    @Test("formats Hz values")
    func hertz() {
        #expect(LsCpu.formatFrequency(44100) == "44100 Hz")
    }

    @Test("formats MHz values")
    func megahertz() {
        #expect(LsCpu.formatFrequency(800_000_000) == "800 MHz")
        #expect(LsCpu.formatFrequency(38_400_000) == "38.4 MHz")
        #expect(LsCpu.formatFrequency(99_960_000) == "100 MHz")
    }

    @Test("formats GHz values")
    func gigahertz() {
        #expect(LsCpu.formatFrequency(2_400_000_000) == "2.40 GHz")
    }
}
