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

@Suite("CpuInfo namespace")
struct CpuInfoNamespaceTests {
    @Test("packageVersion is a non-empty semver")
    func packageVersion() {
        #expect(!CpuInfoVersion.packageVersion.isEmpty)
        // Loose semver shape: "X.Y.Z" or "X.Y.Z-prerelease"
        let pattern = #/^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$/#
        #expect(CpuInfoVersion.packageVersion.wholeMatch(of: pattern) != nil,
                "packageVersion \(CpuInfoVersion.packageVersion) is not a valid SemVer")
    }

    @Test("vendoredCpuinfoCommit is a full SHA-1")
    func vendoredCpuinfoCommit() {
        #expect(CpuInfoVersion.vendoredCpuinfoCommit.count == 40)
        let hex = CharacterSet(charactersIn: "0123456789abcdef")
        let chars = CharacterSet(charactersIn: CpuInfoVersion.vendoredCpuinfoCommit)
        #expect(hex.isSuperset(of: chars),
                "vendoredCpuinfoCommit contains non-hex characters")
    }

    #if os(macOS) || os(Linux)
    @Test("CPUINFO_VERSION, vendoredCpuinfoCommit and NOTICES name the same vendored commit")
    func vendoredCommitInSync() throws {
        let commit = CpuInfoVersion.vendoredCpuinfoCommit
        #expect(try repositoryFile("CPUINFO_VERSION").trimmingCharacters(in: .whitespacesAndNewlines) == commit)
        #expect(try repositoryFile("NOTICES").contains("Vendored commit: \(commit)\n"))
    }
    #endif
}
