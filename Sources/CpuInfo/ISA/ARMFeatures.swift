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

internal import _cpuinfo

/// ARM/ARM64 instruction set feature detection.
///
/// Features are grouped into nested structs by extension family
/// (NEON, SVE, SME). Individual features are `Bool` properties
/// that reflect runtime queries performed by cpuinfo.
public struct ARMFeatures: Sendable, Equatable, Hashable, Codable {
    /// NEON (Advanced SIMD) feature flags.
    public struct NEONFeatures: Sendable, Equatable, Hashable, Codable {
        /// NEON — 128-bit Advanced SIMD (ARMv7-A optional; mandatory on all ARMv8-A).
        public let neon: Bool
        /// NEON FP16 — half-precision load/store/convert (ARMv8.0 optional).
        public let fp16: Bool
        /// NEON FMA — fused multiply-add for single- and double-precision SIMD lanes.
        public let fma: Bool
        /// NEON v8 — ARMv8-A additions to Advanced SIMD, including full double-precision FP support.
        public let v8: Bool // swiftlint:disable:this identifier_name
        /// RDM — rounding double-multiply accumulate (SQRDMLAH / SQRDMLSH; ARMv8.1-A).
        public let rdm: Bool
        /// FP16 arithmetic — IEEE-754 half-precision arithmetic in SIMD (ARMv8.2-A).
        public let fp16Arith: Bool
        /// DotProd — int8 dot product in NEON (UDOT / SDOT; ARMv8.2-A optional, ARMv8.4 mandatory).
        public let dotProd: Bool
        /// NEON BF16 — BFloat16 multiply-accumulate (ARMv8.6-A).
        public let bf16: Bool
        /// FP8DOT4 — FP8 four-way dot product accumulating to single precision (FDOT).
        public let fp8Dot4: Bool
        /// F8MM — FP8 matrix multiply-accumulate (FMMLA with FP8 sources).
        public let f8mm: Bool
        #if arch(arm64) || arch(arm)
        init() {
            neon      = cpuinfo_has_arm_neon()
            fp16      = cpuinfo_has_arm_neon_fp16()
            fma       = cpuinfo_has_arm_neon_fma()
            v8        = cpuinfo_has_arm_neon_v8()
            rdm       = cpuinfo_has_arm_neon_rdm()
            fp16Arith = cpuinfo_has_arm_neon_fp16_arith()
            dotProd   = cpuinfo_has_arm_neon_dot()
            bf16      = cpuinfo_has_arm_neon_bf16()
            fp8Dot4   = cpuinfo_has_arm_neon_f8dot4()
            f8mm      = cpuinfo_has_arm_neon_f8mm()
        }
        #endif
    }

    /// SVE (Scalable Vector Extension) feature flags.
    public struct SVEFeatures: Sendable, Equatable, Hashable, Codable {
        /// SVE — vector-length-agnostic SIMD, 128- to 2048-bit vectors (ARMv8.2-A optional).
        public let sve: Bool
        /// SVE2 — superset of SVE that also covers NEON-equivalent integer/string workloads (ARMv9.0-A).
        public let sve2: Bool
        /// SVE2.1 — further SVE2 instruction additions (ARMv9.4-A).
        public let sve2p1: Bool
        /// SVE-BF16 — BFloat16 matrix multiply-accumulate in SVE.
        public let sveBf16: Bool
        #if arch(arm64) || arch(arm)
        init() {
            sve     = cpuinfo_has_arm_sve()
            sve2    = cpuinfo_has_arm_sve2()
            sve2p1  = cpuinfo_has_arm_sve2p1()
            sveBf16 = cpuinfo_has_arm_sve_bf16()
        }
        #endif
    }

    /// SME (Scalable Matrix Extension) feature flags.
    public struct SMEFeatures: Sendable, Equatable, Hashable, Codable {
        /// SME — streaming-mode ZA tile register state and outer-product FMA (ARMv9.2-A).
        public let sme: Bool
        /// SME2 — second revision of SME with additional dot-product and accumulation instructions.
        public let sme2: Bool
        /// SME2.1 — third revision of SME with further instruction additions.
        public let sme2p1: Bool
        /// SME MOP4 — quarter-tile outer-product instructions (FMOP4A, SMOP4A, …).
        public let mop4: Bool
        /// SME i16→i32 — 16-bit integer widening outer product accumulating to 32-bit.
        public let i16i32: Bool
        /// SME binary i32 — binary int32 outer product.
        public let bi32i32: Bool
        /// SME B16B16 — BFloat16 outer product accumulating to BFloat16.
        public let b16b16: Bool
        /// SME F16F16 — half-precision FP outer product accumulating to half-precision.
        public let f16f16: Bool
        #if arch(arm64) || arch(arm)
        init() {
            sme     = cpuinfo_has_arm_sme()
            sme2    = cpuinfo_has_arm_sme2()
            sme2p1  = cpuinfo_has_arm_sme2p1()
            mop4    = cpuinfo_has_arm_sme_mop4()
            i16i32  = cpuinfo_has_arm_sme_i16i32()
            bi32i32 = cpuinfo_has_arm_sme_bi32i32()
            b16b16  = cpuinfo_has_arm_sme_b16b16()
            f16f16  = cpuinfo_has_arm_sme_f16f16()
        }
        #endif
    }

    /// NEON (Advanced SIMD) features.
    public let neon: NEONFeatures
    /// SVE (Scalable Vector Extension) features.
    public let sve: SVEFeatures
    /// SME (Scalable Matrix Extension) features.
    public let sme: SMEFeatures
    /// AES — hardware AES round instructions (AESE / AESD / AESMC / AESIMC).
    public let aes: Bool
    /// SHA-1 — hardware SHA-1 round instructions (SHA1C / SHA1P / SHA1M / SHA1SU0 / SHA1SU1 / SHA1H).
    public let sha1: Bool
    /// SHA-2 — hardware SHA-256 round instructions (SHA256H / SHA256H2 / SHA256SU0 / SHA256SU1).
    public let sha2: Bool
    /// PMULL — polynomial multiply long (PMULL / PMULL2) for GF(2ⁿ) math including AES-GCM.
    public let pmull: Bool
    /// CRC32 — CRC-32 and CRC-32C instructions (ARMv8.0-A optional, ARMv8.1 mandatory).
    public let crc32: Bool
    /// LSE — Large System Extensions: single-instruction atomics (LDADD, CAS, SWP, …); ARMv8.1-A.
    public let atomics: Bool
    /// Scalar FP16 arithmetic — IEEE-754 half-precision arithmetic in the scalar FPU (ARMv8.2-A).
    ///
    /// Distinct from ``NEONFeatures/fp16Arith`` which covers the same extension in vector form.
    public let scalarFP16Arith: Bool
    /// BF16 — BFloat16 scalar multiply-accumulate (ARMv8.6-A).
    public let bf16: Bool
    /// FP8 — 8-bit floating-point (E4M3 / E5M2) conversion instructions and the FPMR mode register.
    public let fp8: Bool
    /// FHM — FMLAL / FMLSL: FP16 → FP32 widening multiply-accumulate (ARMv8.2-A FHM).
    public let fhm: Bool
    /// I8MM — int8 matrix multiply (SMMLA / USMMLA / UMMLA; ARMv8.6-A).
    public let i8mm: Bool
    /// JSCVT — FJCVTZS: JavaScript-style float-to-int truncation conversion (ARMv8.3-A).
    public let jscvt: Bool
    /// FCMA — complex-number multiply-accumulate (FCADD, FCMLA; ARMv8.3-A).
    public let fcma: Bool

    #if arch(arm64) || arch(arm)
    init() {
        neon      = NEONFeatures()
        sve       = SVEFeatures()
        sme       = SMEFeatures()
        aes       = cpuinfo_has_arm_aes()
        sha1      = cpuinfo_has_arm_sha1()
        sha2      = cpuinfo_has_arm_sha2()
        pmull     = cpuinfo_has_arm_pmull()
        crc32     = cpuinfo_has_arm_crc32()
        atomics        = cpuinfo_has_arm_atomics()
        scalarFP16Arith = cpuinfo_has_arm_fp16_arith()
        bf16           = cpuinfo_has_arm_bf16()
        fp8            = cpuinfo_has_arm_fp8()
        fhm       = cpuinfo_has_arm_fhm()
        i8mm      = cpuinfo_has_arm_i8mm()
        jscvt     = cpuinfo_has_arm_jscvt()
        fcma      = cpuinfo_has_arm_fcma()
    }
    #endif
}

extension ARMFeatures.NEONFeatures {
    // Declared rather than synthesized so that `init(flag:)` can name it in its signature.
    enum CodingKeys: String, CodingKey {
        case neon, fp16, fma, rdm, fp16Arith, dotProd, bf16, fp8Dot4, f8mm
        case v8 // swiftlint:disable:this identifier_name
    }

    /// Decodes a snapshot; a flag that an older version did not write decodes as `false`.
    public init(from decoder: any Decoder) throws {
        let flags = try decoder.container(keyedBy: CodingKeys.self)
        try self.init { try flags.decodeFlag($0) }
    }

    /// Every flag `false`, for a snapshot taken on another architecture.
    static let unavailable = Self { _ in false }

    private init(flag: (CodingKeys) throws -> Bool) rethrows {
        neon      = try flag(.neon)
        fp16      = try flag(.fp16)
        fma       = try flag(.fma)
        v8        = try flag(.v8)
        rdm       = try flag(.rdm)
        fp16Arith = try flag(.fp16Arith)
        dotProd   = try flag(.dotProd)
        bf16      = try flag(.bf16)
        fp8Dot4   = try flag(.fp8Dot4)
        f8mm      = try flag(.f8mm)
    }
}

extension ARMFeatures.SVEFeatures {
    // Declared rather than synthesized so that `init(flag:)` can name it in its signature.
    enum CodingKeys: String, CodingKey {
        case sve, sve2, sve2p1, sveBf16
    }

    /// Decodes a snapshot; a flag that an older version did not write decodes as `false`.
    public init(from decoder: any Decoder) throws {
        let flags = try decoder.container(keyedBy: CodingKeys.self)
        try self.init { try flags.decodeFlag($0) }
    }

    /// Every flag `false`, for a snapshot taken on another architecture.
    static let unavailable = Self { _ in false }

    private init(flag: (CodingKeys) throws -> Bool) rethrows {
        sve     = try flag(.sve)
        sve2    = try flag(.sve2)
        sve2p1  = try flag(.sve2p1)
        sveBf16 = try flag(.sveBf16)
    }
}

extension ARMFeatures.SMEFeatures {
    // Declared rather than synthesized so that `init(flag:)` can name it in its signature.
    enum CodingKeys: String, CodingKey {
        case sme, sme2, sme2p1, mop4, i16i32, bi32i32, b16b16, f16f16
    }

    /// Decodes a snapshot; a flag that an older version did not write decodes as `false`.
    public init(from decoder: any Decoder) throws {
        let flags = try decoder.container(keyedBy: CodingKeys.self)
        try self.init { try flags.decodeFlag($0) }
    }

    /// Every flag `false`, for a snapshot taken on another architecture.
    static let unavailable = Self { _ in false }

    private init(flag: (CodingKeys) throws -> Bool) rethrows {
        sme     = try flag(.sme)
        sme2    = try flag(.sme2)
        sme2p1  = try flag(.sme2p1)
        mop4    = try flag(.mop4)
        i16i32  = try flag(.i16i32)
        bi32i32 = try flag(.bi32i32)
        b16b16  = try flag(.b16b16)
        f16f16  = try flag(.f16f16)
    }
}

extension ARMFeatures {
    // Declared rather than synthesized so that `init(flag:)` can name it in its signature.
    enum CodingKeys: String, CodingKey {
        case neon, sve, sme, aes, sha1, sha2, pmull, crc32, atomics, scalarFP16Arith, bf16, fp8, fhm, i8mm, jscvt, fcma
    }

    /// Decodes a snapshot; a flag that an older version did not write decodes as `false`.
    public init(from decoder: any Decoder) throws {
        let flags = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            neon: flags.decode(NEONFeatures.self, forKey: .neon),
            sve: flags.decode(SVEFeatures.self, forKey: .sve),
            sme: flags.decode(SMEFeatures.self, forKey: .sme)
        ) { try flags.decodeFlag($0) }
    }

    /// Every flag `false`, for a snapshot taken on another architecture.
    static let unavailable = Self(neon: .unavailable, sve: .unavailable, sme: .unavailable) { _ in false }

    private init(
        neon: NEONFeatures, sve: SVEFeatures, sme: SMEFeatures, flag: (CodingKeys) throws -> Bool
    ) rethrows {
        self.neon = neon
        self.sve  = sve
        self.sme  = sme
        aes             = try flag(.aes)
        sha1            = try flag(.sha1)
        sha2            = try flag(.sha2)
        pmull           = try flag(.pmull)
        crc32           = try flag(.crc32)
        atomics         = try flag(.atomics)
        scalarFP16Arith = try flag(.scalarFP16Arith)
        bf16            = try flag(.bf16)
        fp8             = try flag(.fp8)
        fhm             = try flag(.fhm)
        i8mm            = try flag(.i8mm)
        jscvt           = try flag(.jscvt)
        fcma            = try flag(.fcma)
    }
}
