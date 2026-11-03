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

/// Runtime instruction-set availability.
///
/// Both ``x86`` and ``arm`` exist on every architecture, so a snapshot taken on one
/// decodes on the other. A snapshot holds the flags of the architecture it was taken
/// on; every flag of the other one reads `false`.
public struct ISAFeatures: Sendable, Equatable, Hashable, Codable {
    /// x86/x86-64 instruction set feature flags; all `false` in a snapshot taken on ARM.
    public var x86: X86Features { capturedX86 ?? .unavailable }

    /// ARM/ARM64 instruction set feature flags; all `false` in a snapshot taken on x86.
    public var arm: ARMFeatures { capturedARM ?? .unavailable }

    /// The architecture whose flags this snapshot holds: ``Architecture/x86_64`` for x86 flags,
    /// ``Architecture/arm64`` for ARM flags, and ``Architecture/unknown`` when it holds neither.
    ///
    /// ISA flags don't tell 32-bit from 64-bit, so check ``Architecture/isX86Family`` or
    /// ``Architecture/isARMFamily`` rather than comparing cases.
    public var architecture: Architecture {
        if capturedX86 != nil { return .x86_64 }
        if capturedARM != nil { return .arm64 }
        return .unknown
    }

    private let capturedX86: X86Features?
    private let capturedARM: ARMFeatures?

    private enum CodingKeys: String, CodingKey {
        case x86, arm
    }

    init() {
        #if arch(x86_64) || arch(i386)
        capturedX86 = X86Features()
        capturedARM = nil
        #elseif arch(arm64) || arch(arm)
        capturedX86 = nil
        capturedARM = ARMFeatures()
        #else
        capturedX86 = nil
        capturedARM = nil
        #endif
    }

    /// Decodes a snapshot taken on either architecture; it must hold the flags of exactly one.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        capturedX86 = try container.decodeIfPresent(X86Features.self, forKey: .x86)
        capturedARM = try container.decodeIfPresent(ARMFeatures.self, forKey: .arm)
        guard (capturedX86 == nil) != (capturedARM == nil) else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: decoder.codingPath,
                debugDescription: "An ISA snapshot holds the flags of exactly one architecture"))
        }
    }

    /// Encodes only the architecture the snapshot was taken on.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(capturedX86, forKey: .x86)
        try container.encodeIfPresent(capturedARM, forKey: .arm)
    }
}

extension KeyedDecodingContainer {
    /// Decodes an ISA flag, reading a key the snapshot lacks as `false`, so older snapshots still decode.
    /// An explicit `null` is a corrupt snapshot, not an old one, and still throws.
    func decodeFlag(_ key: Key) throws -> Bool {
        try contains(key) ? decode(Bool.self, forKey: key) : false
    }
}
