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
import LinuxPinLib
import Testing

#if os(Linux)
import Foundation

@Test func pinToL2Succeeds() async throws {
    let result = try await onDedicatedThread { try LinuxPin.pinToL2() }
    #expect(!result.pinnedLinuxCPUs.isEmpty, "Should pin to at least one CPU")
    #expect(Set(result.effectiveLinuxCPUs).isSubset(of: result.pinnedLinuxCPUs))
}

@Test func pinnedThreadRunsOnAllowedCPU() async throws {
    let (result, linuxID) = try await onDedicatedThread {
        (try LinuxPin.pinToL2(), ProcessorInfo.currentLogicalProcessor?.linuxID)
    }
    let allowed = Set(result.effectiveLinuxCPUs)
    let id = try #require(linuxID, "Current processor should have a linuxID on Linux")
    #expect(allowed.contains(id), "Current Linux CPU \(id) should be in pinned set \(allowed)")
}

// Pinning runs on a throwaway thread so no shared test worker stays pinned.
private func onDedicatedThread<T: Sendable>(_ body: @escaping @Sendable () throws -> T) async throws -> T {
    try await withCheckedThrowingContinuation { continuation in
        Thread { continuation.resume(with: Result { try body() }) }.start()
    }
}
#else
@Test func pinToL2ThrowsOnNonLinux() {
    // On non-Linux the flow fails at `currentLogicalProcessor` (nil on
    // macOS/iOS/visionOS) and surfaces as `LinuxPinError.noCurrentProcessor`
    // — any thrown error is acceptable for this test.
    do {
        _ = try LinuxPin.pinToL2()
        Issue.record("pinToL2 should have thrown on non-Linux")
    } catch {
        // expected
    }
}

@Test func setCurrentThreadAffinityThrowsUnsupportedOnNonLinux() throws {
    do {
        try ProcessorInfo.setCurrentThreadAffinity(CPUSet([0]))
        Issue.record("setCurrentThreadAffinity should have thrown on non-Linux")
    } catch {
        #expect(error.code == .threadAffinityUnsupported)
    }
}
#endif
