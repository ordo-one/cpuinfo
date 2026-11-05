// swift-tools-version: 6.2

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
import PackageDescription

// Library evolution flags for `CpuInfo`: enabled by the `LibraryEvolution` trait (SPM) or by
// CPUINFO_LIBRARY_EVOLUTION=1/true/yes (xcodebuild has no `-traits`).
let libraryEvolutionFlags: [SwiftSetting] = {
    let flags = ["-enable-library-evolution", "-emit-module-interface"]
    let env = ProcessInfo.processInfo.environment["CPUINFO_LIBRARY_EVOLUTION"]?.lowercased()
    if let env, ["1", "true", "yes"].contains(env) {
        return [.unsafeFlags(flags)]
    } else {
        return [.unsafeFlags(flags, .when(traits: ["LibraryEvolution"]))]
    }
}()

let package = Package(
    name: "cpuinfo",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .visionOS(.v2)
    ],
    products: [
        .library(name: "CpuInfo", targets: ["CpuInfo"])
    ],
    traits: [
        Trait(
            name: "LibraryEvolution",
            description: "Build `CpuInfo` with `-enable-library-evolution` "
                + "and `-emit-module-interface` for xcframework distribution. "
                + "Off by default for fast iteration; consumers shipping "
                + "binary frameworks should enable this trait."
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.5.0")
    ],
    targets: [

        // MARK: - Vendored C library
        //
        // A single target. Wrapper shim files in shims/ handle all
        // architecture and platform conditional compilation via
        // preprocessor guards. Vendored sources in src/ and deps/
        // are NOT compiled directly — only #include'd by the shims.
        .target(
            name: "_cpuinfo",
            path: "Sources/_cpuinfo",
            exclude: ["src", "deps", "include/cpuinfo-mock.h"],
            sources: ["shims"],
            publicHeadersPath: "include",
            cSettings: [
                .define("CPUINFO_LOG_LEVEL", to: "2"),
                .define("CPUINFO_LOG_TO_STDIO", to: "1"),
                .define("_GNU_SOURCE", to: "1", .when(platforms: [.linux])),
                .headerSearchPath("src"),
                .headerSearchPath("deps/clog/include")
            ]
        ),

        // MARK: - Swift public API
        .target(
            name: "CpuInfo",
            dependencies: ["_cpuinfo"],
            path: "Sources/CpuInfo",
            swiftSettings: libraryEvolutionFlags
        ),

        // MARK: - Tests
        .testTarget(
            name: "CpuInfoTests",
            dependencies: ["CpuInfo"]
        )
    ]
)
