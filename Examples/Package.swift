// swift-tools-version: 6.0

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

import PackageDescription

let package = Package(
    name: "Examples",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .visionOS(.v2)
    ],
    dependencies: [
        .package(name: "cpuinfo", path: "..")
    ],
    targets: [
        .target(
            name: "LsCpuLib",
            dependencies: [
                .product(name: "CpuInfo", package: "cpuinfo")
            ],
            path: "lscpu/Sources"
        ),
        .executableTarget(
            name: "lscpu",
            dependencies: ["LsCpuLib"],
            path: "lscpu/EntryPoint"
        ),
        .testTarget(
            name: "LsCpuTests",
            dependencies: ["LsCpuLib"],
            path: "lscpu/Tests"
        ),
        .target(
            name: "LinuxPinLib",
            dependencies: [
                .product(name: "CpuInfo", package: "cpuinfo")
            ],
            path: "linuxPin/Sources"
        ),
        .executableTarget(
            name: "linuxPin",
            dependencies: ["LinuxPinLib"],
            path: "linuxPin/EntryPoint"
        ),
        .testTarget(
            name: "LinuxPinTests",
            dependencies: ["LinuxPinLib"],
            path: "linuxPin/Tests"
        )
    ]
)
