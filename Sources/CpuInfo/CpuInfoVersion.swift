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

// A symbol named after the module followed by `Version` is left out of the symbol graph unless it is
// marked `@_documentation(visibility: public)`.
/// Package-level metadata for the CpuInfo Swift package.
///
/// Use these constants in bug reports, logs, or diagnostics so that a
/// downstream consumer can unambiguously identify which version of the
/// package — and which upstream [pytorch/cpuinfo](https://github.com/pytorch/cpuinfo)
/// commit — is linked into a running binary.
///
/// - Example:
/// ```swift
/// print("cpuinfo \(CpuInfoVersion.packageVersion) (upstream \(CpuInfoVersion.vendoredCpuinfoCommit.prefix(12)))")
/// ```
@_documentation(visibility: public)
public enum CpuInfoVersion {
    /// Semantic version of this Swift package, e.g. `"2.0.0"`.
    ///
    /// Updated by the maintainer at each release tag.
    public static let packageVersion = "2.3.0"

    /// Full 40-character git SHA of the vendored
    /// [pytorch/cpuinfo](https://github.com/pytorch/cpuinfo) commit.
    ///
    /// Kept in sync with the `CPUINFO_VERSION` file by
    /// `Scripts/update-cpuinfo.sh` on every vendor bump.
    public static let vendoredCpuinfoCommit = "e9320ce3398899fbecc986c82f49b5d59b80dff7"
}
