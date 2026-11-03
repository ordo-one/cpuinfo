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
import Foundation

// swiftlint:disable:next type_body_length
public struct LsCpu {
    public static func run() {
        let info: ProcessorInfo
        do {
            info = try ProcessorInfo()
        } catch {
            print("Error: \(error)")
            return
        }

        printHeader("System Processor Information")
        printVersion()
        printArchitecture()
        printTopology(info)
        printClusters(info)
        printCores(info)
        printLogicalProcessors(info)
        printFrequencyInfo(info)
        printCacheHierarchy(info)
        printISAFeatures(info)
    }

    static func printVersion() {
        printSection("Package")
        printField("Version", CpuInfoVersion.packageVersion)
        printField("Vendored cpuinfo", String(CpuInfoVersion.vendoredCpuinfoCommit.prefix(12)))
        print()
    }

    // MARK: - Formatting Helpers

    static let labelWidth = 38

    static func printHeader(_ title: String) {
        let bar = String(repeating: "=", count: 60)
        print(bar)
        print(" \(title)")
        print(bar)
        print()
    }

    static func printSection(_ title: String) {
        print("--- \(title) ", terminator: "")
        print(String(repeating: "-", count: max(0, 56 - title.count)))
        print()
    }

    static func printField(_ label: String, _ value: String) {
        let padding = String(repeating: " ", count: max(1, labelWidth - label.count))
        print("  \(label)\(padding)\(value)")
    }

    static func printField(_ label: String, _ value: Int) {
        printField(label, "\(value)")
    }

    static func printCheck(_ label: String, _ supported: Bool) {
        printField(label, supported ? "yes" : "no")
    }

    // MARK: - Sections

    static func printArchitecture() {
        printSection("Architecture")
        let arch = Architecture.current
        printField("Binary architecture (CPUINFO_ARCH)", "\(arch)")
        printField("x86 family", arch.isX86Family ? "yes" : "no")
        printField("ARM family", arch.isARMFamily ? "yes" : "no")
        print()
    }

    static func printTopology(_ info: ProcessorInfo) {
        printSection("Topology Summary")
        printField("Packages (sockets)", info.packages.count)
        printField("Clusters", info.clusters.count)
        printField("Physical cores", info.cores.count)
        printField("Logical processors (threads)", info.logicalProcessors.count)

        let threadsPerCore = info.cores.isEmpty ? 1 :
            info.logicalProcessors.count / info.cores.count
        printField("Threads per core (SMT)", threadsPerCore)
        print()
    }

    static func printClusters(_ info: ProcessorInfo) {
        printSection("Packages")
        for pkg in info.packages {
            printField("Package \(pkg.id)", pkg.name)
            printField("  Cores", pkg.coreCount)
            printField("  Clusters", pkg.clusterCount)
            printField("  Logical processors", pkg.logicalProcessorCount)
        }
        print()

        if !info.clusters.isEmpty {
            printSection("Clusters (heterogeneous topology)")
            for cluster in info.clusters {
                printField("Cluster \(cluster.id)", cluster.microarchitecture.description)
                printField("  Cores", cluster.coreCount)
                printField("  Logical processors", cluster.logicalProcessorCount)
                if let freq = cluster.frequency {
                    printField("  Frequency", formatFrequency(freq))
                }
            }
            print()
        }
    }

    static func printCores(_ info: ProcessorInfo) {
        printSection("Cores")

        // Group cores by microarchitecture
        var groups: [(Microarchitecture, Int)] = []
        for core in info.cores {
            if let last = groups.last, last.0 == core.microarchitecture {
                groups[groups.count - 1].1 += 1
            } else {
                groups.append((core.microarchitecture, 1))
            }
        }

        for (uarch, count) in groups {
            printField(uarch.description, "\(count) core\(count == 1 ? "" : "s")")
        }

        // Show per-core detail if heterogeneous or few cores
        if info.cores.count <= 16 {
            print()
            for core in info.cores {
                var detail = "uarch=\(core.microarchitecture), threads=\(core.logicalProcessorCount)"
                if let freq = core.frequency {
                    detail += ", freq=\(formatFrequency(freq))"
                }
                printField("  Core \(core.id)", detail)
            }
        }
        print()
    }

    static func printLogicalProcessors(_ info: ProcessorInfo) {
        if info.logicalProcessors.count <= 32 {
            printSection("Logical Processors")
            for proc in info.logicalProcessors {
                printField("  Processor \(proc.id)", "SMT thread \(proc.smtID)")
            }
            print()
        }
    }

    static func printFrequencyInfo(_ info: ProcessorInfo) {
        if let freq = info.frequency {
            printSection("Processor Frequency (CPUID leaf 0x16)")
            if let baseHz = freq.baseFrequencyHz {
                printField("Base frequency", formatFrequency(baseHz))
            }
            if let maxHz = freq.maxFrequencyHz {
                printField("Max frequency", formatFrequency(maxHz))
            }
            if let busHz = freq.busFrequencyHz {
                printField("Bus frequency", formatFrequency(busHz))
            }
            print()
        }

        if let tsc = info.tsc {
            printSection("TSC / Crystal Clock (CPUID leaf 0x15)")
            printField("TSC ratio", "\(tsc.numerator) / \(tsc.denominator)")
            if let crystalHz = tsc.crystalClockHz {
                let source = tsc.crystalClockKnown ? "reported by CPU" : "inferred from model"
                printField("Crystal clock", "\(formatFrequency(crystalHz)) (\(source))")
            }
            if let tscHz = tsc.tscFrequencyHz {
                printField("TSC frequency", formatFrequency(tscHz))
            }
            print()
        }
    }

    static func sameGeometry(_ lhs: CacheLevel, _ rhs: CacheLevel) -> Bool {
        lhs.size == rhs.size && lhs.lineSize == rhs.lineSize && lhs.associativity == rhs.associativity
            && lhs.sets == rhs.sets && lhs.partitions == rhs.partitions && lhs.flags == rhs.flags
            && lhs.logicalProcessorCount == rhs.logicalProcessorCount
    }

    static func printCacheHierarchy(_ info: ProcessorInfo) {
        printSection("Cache Hierarchy")

        func printCacheArray(_ label: String, _ caches: [CacheLevel]) {
            // Group caches with identical geometry and sharing, e.g. P- and E-cluster L2s apart.
            var groups: [(cache: CacheLevel, count: Int)] = []
            for cache in caches {
                if let index = groups.firstIndex(where: { sameGeometry($0.cache, cache) }) {
                    groups[index].count += 1
                } else {
                    groups.append((cache, 1))
                }
            }
            for (representative, count) in groups {
                printCacheGroup(label, representative, count)
            }
        }

        func printCacheGroup(_ label: String, _ representative: CacheLevel, _ count: Int) {
            let kindStr: String
            switch representative.kind {
            case .data:        kindStr = "Data"
            case .instruction: kindStr = "Instruction"
            case .unified:     kindStr = "Unified"
            }

            let sizeStr = formatBytes(representative.size)
            printField("\(label) (\(kindStr))", "\(count)x \(sizeStr)")
            printField("  Line size", "\(representative.lineSize) bytes")

            if representative.isFullyAssociative {
                printField("  Associativity", "fully associative")
            } else {
                printField("  Associativity", "\(representative.associativity)-way set associative")
            }

            printField("  Sets", representative.sets)
            printField("  Partitions", representative.partitions)
            let procCount = representative.logicalProcessorCount
            printField("  Shared by", "\(procCount) logical processor\(procCount == 1 ? "" : "s")")

            var flags: [String] = []
            if representative.isUnified { flags.append("unified") }
            if representative.isInclusive { flags.append("inclusive") }
            if representative.usesComplexIndexing { flags.append("complex-indexing") }
            if !flags.isEmpty {
                printField("  Flags", flags.joined(separator: ", "))
            }
            print()
        }

        printCacheArray("L1d", info.caches.l1Data)
        printCacheArray("L1i", info.caches.l1Instruction)
        printCacheArray("L2", info.caches.l2)
        printCacheArray("L3", info.caches.l3)
        printCacheArray("L4", info.caches.l4)
    }

    static func printISAFeatures(_ info: ProcessorInfo) { // swiftlint:disable:this function_body_length
        printSection("Instruction Set Extensions")

        #if arch(arm64) || arch(arm)
        let arm = info.isa.arm

        printField("NEON (Advanced SIMD)", "")
        printCheck("  NEON", arm.neon.neon)
        printCheck("  NEON-FP16 (half-precision)", arm.neon.fp16)
        printCheck("  NEON-FMA (fused multiply-add)", arm.neon.fma)
        printCheck("  NEON v8", arm.neon.v8)
        printCheck("  NEON-RDM (rounding double multiply)", arm.neon.rdm)
        printCheck("  NEON-FP16 Arith", arm.neon.fp16Arith)
        printCheck("  NEON-DOT (dot product)", arm.neon.dotProd)
        printCheck("  NEON-BF16 (bfloat16)", arm.neon.bf16)
        printCheck("  NEON-FP8DOT4 (fp8 dot product)", arm.neon.fp8Dot4)
        printCheck("  NEON-F8MM (fp8 matrix multiply)", arm.neon.f8mm)
        print()

        printField("SVE (Scalable Vector Extension)", "")
        printCheck("  SVE", arm.sve.sve)
        printCheck("  SVE2", arm.sve.sve2)
        printCheck("  SVE2p1", arm.sve.sve2p1)
        printCheck("  SVE-BF16", arm.sve.sveBf16)
        print()

        printField("SME (Scalable Matrix Extension)", "")
        printCheck("  SME", arm.sme.sme)
        printCheck("  SME2", arm.sme.sme2)
        printCheck("  SME2p1", arm.sme.sme2p1)
        printCheck("  SME-MOP4", arm.sme.mop4)
        printCheck("  SME-I16I32", arm.sme.i16i32)
        printCheck("  SME-BI32I32", arm.sme.bi32i32)
        printCheck("  SME-B16B16", arm.sme.b16b16)
        printCheck("  SME-F16F16", arm.sme.f16f16)
        print()

        printField("Cryptography & Atomics", "")
        printCheck("  AES (hardware AES)", arm.aes)
        printCheck("  SHA-1", arm.sha1)
        printCheck("  SHA-2 (SHA-256)", arm.sha2)
        printCheck("  PMULL (polynomial multiply long)", arm.pmull)
        printCheck("  CRC32", arm.crc32)
        printCheck("  LSE Atomics (ARMv8.1)", arm.atomics)
        print()

        printField("Floating Point & Matrix", "")
        printCheck("  Scalar FP16 Arith (ARMv8.2)", arm.scalarFP16Arith)
        printCheck("  BF16 (bfloat16)", arm.bf16)
        printCheck("  FP8 (8-bit float convert)", arm.fp8)
        printCheck("  FHM (half-precision multiply)", arm.fhm)
        printCheck("  I8MM (int8 matrix multiply)", arm.i8mm)
        printCheck("  JSCVT (JS FP convert)", arm.jscvt)
        printCheck("  FCMA (complex number arith)", arm.fcma)
        #endif

        #if arch(x86_64) || arch(i386)
        let x86 = info.isa.x86

        printField("SSE (Streaming SIMD Extensions)", "")
        printCheck("  SSE", x86.sse.sse)
        printCheck("  SSE2", x86.sse.sse2)
        printCheck("  SSE3", x86.sse.sse3)
        printCheck("  SSSE3 (Supplemental SSE3)", x86.sse.ssse3)
        printCheck("  SSE4.1", x86.sse.sse4_1)
        printCheck("  SSE4.2", x86.sse.sse4_2)
        printCheck("  SSE4a (AMD)", x86.sse.sse4a)
        print()

        printField("AVX (Advanced Vector Extensions)", "")
        printCheck("  AVX", x86.avx.avx)
        printCheck("  AVX2", x86.avx.avx2)
        printCheck("  AVX-VNNI", x86.avx.avxVnni)
        printCheck("  AVX-VNNI-INT8", x86.avxVnniInt8)
        printCheck("  AVX-VNNI-INT16", x86.avxVnniInt16)
        printCheck("  AVX-NE-CONVERT", x86.avxNeConvert)
        printCheck("  AVX10.1", x86.avx.avx10_1)
        printCheck("  AVX10.2", x86.avx.avx10_2)
        print()

        printField("AVX-512", "")
        printCheck("  AVX-512F (Foundation)", x86.avx.avx512f)
        printCheck("  AVX-512CD (Conflict Detection)", x86.avx.avx512cd)
        printCheck("  AVX-512BW (Byte/Word)", x86.avx.avx512bw)
        printCheck("  AVX-512DQ (Doubleword/Quad)", x86.avx.avx512dq)
        printCheck("  AVX-512VL (Vector Length)", x86.avx.avx512vl)
        printCheck("  AVX-512PF (Prefetch)", x86.avx.avx512pf)
        printCheck("  AVX-512ER (Exp. & Reciprocal)", x86.avx.avx512er)
        printCheck("  AVX-512IFMA (Int. FMA)", x86.avx.avx512ifma)
        printCheck("  AVX-512VBMI", x86.avx.avx512vbmi)
        printCheck("  AVX-512VBMI2", x86.avx.avx512vbmi2)
        printCheck("  AVX-512BITALG (Bit Algorithms)", x86.avx.avx512bitalg)
        printCheck("  AVX-512VPOPCNTDQ (Pop Count)", x86.avx.avx512vpopcntdq)
        printCheck("  AVX-512VNNI (Vector Neural Net)", x86.avx.avx512vnni)
        printCheck("  AVX-512BF16 (bfloat16)", x86.avx.avx512bf16)
        printCheck("  AVX-512FP16 (float16)", x86.avx.avx512fp16)
        printCheck("  AVX-512VP2INTERSECT", x86.avx.avx512vp2intersect)
        printCheck("  AVX-512-4VNNIW", x86.avx.avx512_4vnniw)
        printCheck("  AVX-512-4FMAPS", x86.avx.avx512_4fmaps)
        print()

        printField("AMX (Advanced Matrix Extensions)", "")
        printCheck("  AMX-TILE", x86.amx.tile)
        printCheck("  AMX-BF16", x86.amx.bf16)
        printCheck("  AMX-INT8", x86.amx.int8)
        printCheck("  AMX-FP16", x86.amx.fp16)
        printCheck("  AMX-FP8", x86.amx.fp8)
        print()

        printField("Cryptography & Bit Manipulation", "")
        printCheck("  AES-NI (hardware AES)", x86.aes)
        printCheck("  VAES (vectorized AES)", x86.vaes)
        printCheck("  SHA (SHA-1/SHA-256)", x86.sha)
        printCheck("  PCLMULQDQ (carry-less multiply)", x86.pclmulqdq)
        printCheck("  VPCLMULQDQ (vectorized CLMUL)", x86.vpclmulqdq)
        printCheck("  GFNI (Galois Field)", x86.gfni)
        printCheck("  RDRAND (hardware RNG)", x86.rdrand)
        printCheck("  RDSEED (hardware RNG seed)", x86.rdseed)
        printCheck("  BMI (Bit Manipulation Instr.)", x86.bmi)
        printCheck("  BMI2", x86.bmi2)
        printCheck("  ADX (multi-precision add)", x86.adx)
        printCheck("  POPCNT (population count)", x86.popcnt)
        printCheck("  LZCNT (leading zero count)", x86.lzcnt)
        print()

        printField("Misc", "")
        printCheck("  FMA3 (fused multiply-add 3-op)", x86.fma3)
        printCheck("  FMA4 (fused multiply-add 4-op)", x86.fma4)
        printCheck("  F16C (float16 convert)", x86.f16c)
        printCheck("  CMOV (conditional move)", x86.cmov)
        printCheck("  MOVBE (big-endian move)", x86.movbe)
        printCheck("  CLWB (cache line write-back)", x86.clwb)
        printCheck("  RDTSC (time stamp counter)", x86.rdtsc)
        printCheck("  RDTSCP (serialized TSC)", x86.rdtscp)
        printCheck("  RDPID (processor ID)", x86.rdpid)
        printCheck("  Invariant TSC", x86.invariantTSC)
        printCheck("  HLE (HW Lock Elision)", x86.hle)
        printCheck("  RTM (Restricted Tx Memory)", x86.rtm)
        #endif

        print()
    }

    // MARK: - Formatting Utilities

    static func formatBytes(_ bytes: Int) -> String {
        if bytes >= 1024 * 1024 {
            let mebibytes = Double(bytes) / (1024.0 * 1024.0)
            if mebibytes == mebibytes.rounded() {
                return "\(Int(mebibytes)) MiB"
            }
            return String(format: "%.1f MiB", mebibytes)
        } else if bytes >= 1024 {
            let kibibytes = Double(bytes) / 1024.0
            if kibibytes == kibibytes.rounded() {
                return "\(Int(kibibytes)) KiB"
            }
            return String(format: "%.1f KiB", kibibytes)
        }
        return "\(bytes) B"
    }

    static func formatFrequency(_ hertz: UInt64) -> String {
        if hertz >= 1_000_000_000 {
            return String(format: "%.2f GHz", Double(hertz) / 1_000_000_000.0)
        } else if hertz >= 1_000_000 {
            // Tenths shown only when non-zero: crystal clocks like 38.4 / 19.2 MHz.
            let tenths = (hertz + 50_000) / 100_000
            return tenths % 10 == 0 ? "\(tenths / 10) MHz" : "\(tenths / 10).\(tenths % 10) MHz"
        }
        return "\(hertz) Hz"
    }
}
