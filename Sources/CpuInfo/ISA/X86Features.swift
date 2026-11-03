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

/// x86/x86-64 instruction set feature detection.
///
/// Features are grouped into nested structs by extension family
/// (SSE, AVX, AMX). Individual features are `Bool` properties
/// that reflect runtime CPUID queries performed by cpuinfo.
public struct X86Features: Sendable, Equatable, Hashable, Codable {
    /// SSE family feature flags.
    public struct SSEFeatures: Sendable, Equatable, Hashable, Codable {
        /// SSE — 128-bit SIMD single-precision float (Pentium III, 1999).
        public let sse: Bool
        /// SSE2 — 128-bit SIMD double-precision float and packed integer (Pentium 4, 2001); baseline for x86-64.
        public let sse2: Bool
        /// SSE3 — horizontal arithmetic and complex-number instructions (Prescott, 2004).
        public let sse3: Bool
        /// SSSE3 — supplemental byte shuffles including PSHUFB (Merom, 2006).
        public let ssse3: Bool
        /// SSE4.1 — dword multiply, blend, dot product, streaming load (Penryn, 2007).
        public let sse4_1: Bool // swiftlint:disable:this identifier_name
        /// SSE4.2 — string/text processing, CRC32, POPCNT (Nehalem, 2008).
        public let sse4_2: Bool // swiftlint:disable:this identifier_name
        /// SSE4a — AMD-only extensions: LZCNT, EXTRQ/INSERTQ, MOVNTSD (Barcelona, 2007).
        public let sse4a: Bool
        #if arch(x86_64) || arch(i386)
        init() {
            sse    = cpuinfo_has_x86_sse()
            sse2   = cpuinfo_has_x86_sse2()
            sse3   = cpuinfo_has_x86_sse3()
            ssse3  = cpuinfo_has_x86_ssse3()
            sse4_1 = cpuinfo_has_x86_sse4_1()
            sse4_2 = cpuinfo_has_x86_sse4_2()
            sse4a  = cpuinfo_has_x86_sse4a()
        }
        #endif
    }

    /// AVX and AVX-512 family feature flags.
    public struct AVXFeatures: Sendable, Equatable, Hashable, Codable {
        /// AVX — 256-bit SIMD with non-destructive three-operand VEX encoding (Sandy Bridge, 2011).
        public let avx: Bool
        /// AVX2 — 256-bit integer SIMD, gather loads, per-element variable shifts (Haswell, 2013).
        public let avx2: Bool
        /// AVX-VNNI — int8/int16 dot-product instructions in VEX encoding (Alder Lake).
        public let avxVnni: Bool
        /// AVX-512 Foundation — 512-bit vectors, 32 ZMM registers, opmask registers (Skylake-X, 2016).
        public let avx512f: Bool
        /// AVX-512 Prefetch — gather/scatter prefetch hints (Knights Landing only).
        public let avx512pf: Bool
        /// AVX-512 Exponential and Reciprocal — transcendental approximations (Knights Landing only).
        public let avx512er: Bool
        /// AVX-512 Conflict Detection — scatter/gather hazard detection for vectorized loops.
        public let avx512cd: Bool
        /// AVX-512 Doubleword and Quadword — 32-/64-bit integer and FP operations absent from AVX-512F.
        public let avx512dq: Bool
        /// AVX-512 Byte and Word — 8-/16-bit integer support for 512-bit vectors.
        public let avx512bw: Bool
        /// AVX-512 Vector Length — apply AVX-512 instructions to 128- and 256-bit registers.
        public let avx512vl: Bool
        /// AVX-512 IFMA — 52-bit integer fused multiply-add for big-integer arithmetic.
        public let avx512ifma: Bool
        /// AVX-512 VBMI — vector byte manipulation (VPERMB, VPMULTISHIFTQB).
        public let avx512vbmi: Bool
        /// AVX-512 VBMI2 — compress, expand, and shift-with-bytes instructions.
        public let avx512vbmi2: Bool
        /// AVX-512 BITALG — bit-level algorithms (VPOPCNTB/W, VPSHUFBITQMB).
        public let avx512bitalg: Bool
        /// AVX-512 VPOPCNTDQ — vector population count for 32- and 64-bit elements.
        public let avx512vpopcntdq: Bool
        /// AVX-512 VNNI — int8/int16 dot-product for deep-learning inference (Cascade Lake).
        public let avx512vnni: Bool
        /// AVX-512 BF16 — BFloat16 dot-product (Cooper Lake).
        public let avx512bf16: Bool
        /// AVX-512 FP16 — IEEE-754 half-precision arithmetic (Sapphire Rapids).
        public let avx512fp16: Bool
        /// AVX-512 VP2INTERSECT — pairwise intersection of dword/qword vectors (Tiger Lake, subsequently removed).
        public let avx512vp2intersect: Bool
        /// AVX-512 4VNNIW — 4-register packed neural-network instructions (Knights Mill only).
        public let avx512_4vnniw: Bool // swiftlint:disable:this identifier_name
        /// AVX-512 4FMAPS — 4-register single-precision FMA (Knights Mill only).
        public let avx512_4fmaps: Bool // swiftlint:disable:this identifier_name
        /// AVX10.1 — unified AVX10 ISA across P- and E-cores, 256-bit baseline (2024+).
        public let avx10_1: Bool // swiftlint:disable:this identifier_name
        /// AVX10.2 — AVX10 revision 2.
        public let avx10_2: Bool // swiftlint:disable:this identifier_name
        #if arch(x86_64) || arch(i386)
        init() {
            avx               = cpuinfo_has_x86_avx()
            avx2              = cpuinfo_has_x86_avx2()
            avxVnni           = cpuinfo_has_x86_avxvnni()
            avx512f           = cpuinfo_has_x86_avx512f()
            avx512pf          = cpuinfo_has_x86_avx512pf()
            avx512er          = cpuinfo_has_x86_avx512er()
            avx512cd          = cpuinfo_has_x86_avx512cd()
            avx512dq          = cpuinfo_has_x86_avx512dq()
            avx512bw          = cpuinfo_has_x86_avx512bw()
            avx512vl          = cpuinfo_has_x86_avx512vl()
            avx512ifma        = cpuinfo_has_x86_avx512ifma()
            avx512vbmi        = cpuinfo_has_x86_avx512vbmi()
            avx512vbmi2       = cpuinfo_has_x86_avx512vbmi2()
            avx512bitalg      = cpuinfo_has_x86_avx512bitalg()
            avx512vpopcntdq   = cpuinfo_has_x86_avx512vpopcntdq()
            avx512vnni        = cpuinfo_has_x86_avx512vnni()
            avx512bf16        = cpuinfo_has_x86_avx512bf16()
            avx512fp16        = cpuinfo_has_x86_avx512fp16()
            avx512vp2intersect = cpuinfo_has_x86_avx512vp2intersect()
            avx512_4vnniw     = cpuinfo_has_x86_avx512_4vnniw()
            avx512_4fmaps     = cpuinfo_has_x86_avx512_4fmaps()
            avx10_1           = cpuinfo_has_x86_avx10_1()
            avx10_2           = cpuinfo_has_x86_avx10_2()
        }
        #endif
    }

    /// Intel AMX (Advanced Matrix Extensions) feature flags.
    public struct AMXFeatures: Sendable, Equatable, Hashable, Codable {
        /// AMX-BF16 — BFloat16 tile matrix multiply-accumulate (Sapphire Rapids).
        public let bf16: Bool
        /// AMX-TILE — load/store and configuration of TMM tile registers; foundation for all AMX ops.
        public let tile: Bool
        /// AMX-INT8 — signed/unsigned int8 tile matrix multiply-accumulate with int32 accumulation.
        public let int8: Bool
        /// AMX-FP16 — half-precision float tile matrix multiply-accumulate (Granite Rapids).
        public let fp16: Bool
        /// AMX-FP8 — FP8 (E4M3 / E5M2) tile dot-product accumulating to FP32.
        public let fp8: Bool
        #if arch(x86_64) || arch(i386)
        init() {
            bf16 = cpuinfo_has_x86_amx_bf16()
            tile = cpuinfo_has_x86_amx_tile()
            int8 = cpuinfo_has_x86_amx_int8()
            fp16 = cpuinfo_has_x86_amx_fp16()
            fp8  = cpuinfo_has_x86_amx_fp8()
        }
        #endif
    }

    /// SSE family features.
    public let sse: SSEFeatures
    /// AVX and AVX-512 family features.
    public let avx: AVXFeatures
    /// Intel AMX features.
    public let amx: AMXFeatures
    /// FMA3 — 3-operand fused multiply-add, destructive form (Haswell / Piledriver).
    public let fma3: Bool
    /// FMA4 — 4-operand fused multiply-add, non-destructive form (AMD Bulldozer only; removed in Zen).
    public let fma4: Bool
    /// F16C — half-precision float conversion (VCVTPH2PS / VCVTPS2PH; Ivy Bridge).
    public let f16c: Bool
    /// AES-NI — hardware AES round instructions (Westmere).
    public let aes: Bool
    /// VAES — AES-NI on 256- and 512-bit vectors (Ice Lake).
    public let vaes: Bool
    /// SHA-NI — hardware SHA-1 and SHA-256 round instructions (Goldmont, Zen).
    public let sha: Bool
    /// RDRAND — on-die DRBG-seeded hardware RNG (Ivy Bridge).
    public let rdrand: Bool
    /// RDSEED — seed-grade hardware RNG suitable for cryptographic key material (Broadwell).
    public let rdseed: Bool
    /// BMI1 — bit manipulation: ANDN, BEXTR, BLSI, BLSMSK, BLSR, TZCNT.
    public let bmi: Bool
    /// BMI2 — bit manipulation: BZHI, MULX, PDEP, PEXT, SHLX / SHRX / SARX.
    public let bmi2: Bool
    /// ADX — multi-precision add-carry (ADOX / ADCX) for big-integer and cryptographic math.
    public let adx: Bool
    /// POPCNT — population count (number of set bits) instruction.
    public let popcnt: Bool
    /// LZCNT — leading-zero count instruction (Haswell / Zen; AMD ABM).
    public let lzcnt: Bool
    /// PCLMULQDQ — 64×64→128-bit carry-less multiply for GF(2ⁿ) math (AES-GCM, CRC).
    public let pclmulqdq: Bool
    /// VPCLMULQDQ — PCLMULQDQ on 256- and 512-bit vectors (Ice Lake).
    public let vpclmulqdq: Bool
    /// GFNI — Galois Field New Instructions: affine transforms over GF(2⁸).
    public let gfni: Bool
    /// RDTSC — read time-stamp counter (present since Pentium).
    public let rdtsc: Bool
    /// RDTSCP — RDTSC + processor-ID read as a single serializing load (Nehalem).
    public let rdtscp: Bool
    /// RDPID — read processor ID register without entering kernel mode (Goldmont Plus / Ice Lake).
    public let rdpid: Bool
    /// Invariant TSC — time-stamp counter ticks at constant rate across P-states and C-states;
    /// required for reliable wall-clock timing.
    public let invariantTSC: Bool
    /// CMOV — conditional move instructions (Pentium Pro).
    public let cmov: Bool
    /// MOVBE — move with byte-swap for big-endian load/store (Atom, Haswell).
    public let movbe: Bool
    /// CLWB — cache-line write-back retaining the line in cache (Skylake-X); used for persistent memory.
    public let clwb: Bool
    /// HLE — hardware lock elision (legacy Intel TSX; microcoded off on most CPUs due to errata).
    public let hle: Bool
    /// RTM — restricted transactional memory (Intel TSX; largely disabled via microcode).
    public let rtm: Bool
    /// AVX-VNNI-INT8 — VNNI with signed int8 sources in VEX encoding (Alder Lake / Sapphire Rapids).
    public let avxVnniInt8: Bool
    /// AVX-VNNI-INT16 — VNNI with int16 sources in VEX encoding (Granite Rapids).
    public let avxVnniInt16: Bool
    /// AVX-NE-CONVERT — non-exception-raising BF16/FP16 ↔ FP32 conversion (Granite Rapids).
    public let avxNeConvert: Bool

    #if arch(x86_64) || arch(i386)
    init() {
        sse          = SSEFeatures()
        avx          = AVXFeatures()
        amx          = AMXFeatures()
        fma3         = cpuinfo_has_x86_fma3()
        fma4         = cpuinfo_has_x86_fma4()
        f16c         = cpuinfo_has_x86_f16c()
        aes          = cpuinfo_has_x86_aes()
        vaes         = cpuinfo_has_x86_vaes()
        sha          = cpuinfo_has_x86_sha()
        rdrand       = cpuinfo_has_x86_rdrand()
        rdseed       = cpuinfo_has_x86_rdseed()
        bmi          = cpuinfo_has_x86_bmi()
        bmi2         = cpuinfo_has_x86_bmi2()
        adx          = cpuinfo_has_x86_adx()
        popcnt       = cpuinfo_has_x86_popcnt()
        lzcnt        = cpuinfo_has_x86_lzcnt()
        pclmulqdq    = cpuinfo_has_x86_pclmulqdq()
        vpclmulqdq   = cpuinfo_has_x86_vpclmulqdq()
        gfni         = cpuinfo_has_x86_gfni()
        rdtsc        = cpuinfo_has_x86_rdtsc()
        rdtscp       = cpuinfo_has_x86_rdtscp()
        rdpid        = cpuinfo_has_x86_rdpid()
        invariantTSC = cpuinfo_x86_has_invariant_tsc()
        cmov         = cpuinfo_has_x86_cmov()
        movbe        = cpuinfo_has_x86_movbe()
        clwb         = cpuinfo_has_x86_clwb()
        hle          = cpuinfo_has_x86_hle()
        rtm          = cpuinfo_has_x86_rtm()
        avxVnniInt8  = cpuinfo_has_x86_avx_vnni_int8()
        avxVnniInt16 = cpuinfo_has_x86_avx_vnni_int16()
        avxNeConvert = cpuinfo_has_x86_avx_ne_convert()
    }
    #endif
}

extension X86Features.SSEFeatures {
    // Declared rather than synthesized so that `init(flag:)` can name it in its signature.
    enum CodingKeys: String, CodingKey {
        case sse, sse2, sse3, ssse3, sse4a
        case sse4_1, sse4_2 // swiftlint:disable:this identifier_name
    }

    /// Decodes a snapshot; a flag that an older version did not write decodes as `false`.
    public init(from decoder: any Decoder) throws {
        let flags = try decoder.container(keyedBy: CodingKeys.self)
        try self.init { try flags.decodeFlag($0) }
    }

    /// Every flag `false`, for a snapshot taken on another architecture.
    static let unavailable = Self { _ in false }

    private init(flag: (CodingKeys) throws -> Bool) rethrows {
        sse    = try flag(.sse)
        sse2   = try flag(.sse2)
        sse3   = try flag(.sse3)
        ssse3  = try flag(.ssse3)
        sse4_1 = try flag(.sse4_1)
        sse4_2 = try flag(.sse4_2)
        sse4a  = try flag(.sse4a)
    }
}

extension X86Features.AVXFeatures {
    // Declared rather than synthesized so that `init(flag:)` can name it in its signature.
    enum CodingKeys: String, CodingKey {
        case avx, avx2, avxVnni, avx512f, avx512pf, avx512er, avx512cd, avx512dq, avx512bw, avx512vl, avx512ifma
        case avx512vbmi, avx512vbmi2, avx512bitalg, avx512vpopcntdq, avx512vnni, avx512bf16, avx512fp16
        case avx512vp2intersect
        case avx512_4vnniw, avx512_4fmaps, avx10_1, avx10_2 // swiftlint:disable:this identifier_name
    }

    /// Decodes a snapshot; a flag that an older version did not write decodes as `false`.
    public init(from decoder: any Decoder) throws {
        let flags = try decoder.container(keyedBy: CodingKeys.self)
        try self.init { try flags.decodeFlag($0) }
    }

    /// Every flag `false`, for a snapshot taken on another architecture.
    static let unavailable = Self { _ in false }

    private init(flag: (CodingKeys) throws -> Bool) rethrows {
        avx                = try flag(.avx)
        avx2               = try flag(.avx2)
        avxVnni            = try flag(.avxVnni)
        avx512f            = try flag(.avx512f)
        avx512pf           = try flag(.avx512pf)
        avx512er           = try flag(.avx512er)
        avx512cd           = try flag(.avx512cd)
        avx512dq           = try flag(.avx512dq)
        avx512bw           = try flag(.avx512bw)
        avx512vl           = try flag(.avx512vl)
        avx512ifma         = try flag(.avx512ifma)
        avx512vbmi         = try flag(.avx512vbmi)
        avx512vbmi2        = try flag(.avx512vbmi2)
        avx512bitalg       = try flag(.avx512bitalg)
        avx512vpopcntdq    = try flag(.avx512vpopcntdq)
        avx512vnni         = try flag(.avx512vnni)
        avx512bf16         = try flag(.avx512bf16)
        avx512fp16         = try flag(.avx512fp16)
        avx512vp2intersect = try flag(.avx512vp2intersect)
        avx512_4vnniw      = try flag(.avx512_4vnniw)
        avx512_4fmaps      = try flag(.avx512_4fmaps)
        avx10_1            = try flag(.avx10_1)
        avx10_2            = try flag(.avx10_2)
    }
}

extension X86Features.AMXFeatures {
    // Declared rather than synthesized so that `init(flag:)` can name it in its signature.
    enum CodingKeys: String, CodingKey {
        case bf16, tile, int8, fp16, fp8
    }

    /// Decodes a snapshot; a flag that an older version did not write decodes as `false`.
    public init(from decoder: any Decoder) throws {
        let flags = try decoder.container(keyedBy: CodingKeys.self)
        try self.init { try flags.decodeFlag($0) }
    }

    /// Every flag `false`, for a snapshot taken on another architecture.
    static let unavailable = Self { _ in false }

    private init(flag: (CodingKeys) throws -> Bool) rethrows {
        bf16 = try flag(.bf16)
        tile = try flag(.tile)
        int8 = try flag(.int8)
        fp16 = try flag(.fp16)
        fp8  = try flag(.fp8)
    }
}

extension X86Features {
    // Declared rather than synthesized so that `init(flag:)` can name it in its signature.
    enum CodingKeys: String, CodingKey {
        case sse, avx, amx, fma3, fma4, f16c, aes, vaes, sha, rdrand, rdseed, bmi, bmi2, adx, popcnt, lzcnt
        case pclmulqdq, vpclmulqdq, gfni, rdtsc, rdtscp, rdpid, invariantTSC, cmov, movbe, clwb, hle, rtm
        case avxVnniInt8, avxVnniInt16, avxNeConvert
    }

    /// Decodes a snapshot; a flag that an older version did not write decodes as `false`.
    public init(from decoder: any Decoder) throws {
        let flags = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            sse: flags.decode(SSEFeatures.self, forKey: .sse),
            avx: flags.decode(AVXFeatures.self, forKey: .avx),
            amx: flags.decode(AMXFeatures.self, forKey: .amx)
        ) { try flags.decodeFlag($0) }
    }

    /// Every flag `false`, for a snapshot taken on another architecture.
    static let unavailable = Self(sse: .unavailable, avx: .unavailable, amx: .unavailable) { _ in false }

    private init(
        sse: SSEFeatures, avx: AVXFeatures, amx: AMXFeatures, flag: (CodingKeys) throws -> Bool
    ) rethrows {
        self.sse = sse
        self.avx = avx
        self.amx = amx
        fma3         = try flag(.fma3)
        fma4         = try flag(.fma4)
        f16c         = try flag(.f16c)
        aes          = try flag(.aes)
        vaes         = try flag(.vaes)
        sha          = try flag(.sha)
        rdrand       = try flag(.rdrand)
        rdseed       = try flag(.rdseed)
        bmi          = try flag(.bmi)
        bmi2         = try flag(.bmi2)
        adx          = try flag(.adx)
        popcnt       = try flag(.popcnt)
        lzcnt        = try flag(.lzcnt)
        pclmulqdq    = try flag(.pclmulqdq)
        vpclmulqdq   = try flag(.vpclmulqdq)
        gfni         = try flag(.gfni)
        rdtsc        = try flag(.rdtsc)
        rdtscp       = try flag(.rdtscp)
        rdpid        = try flag(.rdpid)
        invariantTSC = try flag(.invariantTSC)
        cmov         = try flag(.cmov)
        movbe        = try flag(.movbe)
        clwb         = try flag(.clwb)
        hle          = try flag(.hle)
        rtm          = try flag(.rtm)
        avxVnniInt8  = try flag(.avxVnniInt8)
        avxVnniInt16 = try flag(.avxVnniInt16)
        avxNeConvert = try flag(.avxNeConvert)
    }
}
