# ISA Feature Detection

Query instruction set extensions at runtime for x86 and ARM processors.

## Overview

``ISAFeatures`` provides runtime detection of CPU instruction set extensions. Features are organized by architecture and grouped by extension family (SSE, AVX, NEON, SVE, etc.).

Both ``ISAFeatures/arm`` and ``ISAFeatures/x86`` exist on every architecture. A snapshot holds the flags of the architecture it was taken on, which ``ISAFeatures/architecture`` reports, and every flag of the other one reads `false`. All ISA feature types conform to `Equatable`, `Hashable`, and `Codable`, so a snapshot taken on one architecture decodes on the other. Decoding a snapshot written by an older version reads any flag that version did not know as `false`.

## ARM Feature Detection

On ARM64 systems (macOS, iOS, visionOS on Apple Silicon, Linux on ARM), access features through `ISAFeatures.arm`:

```swift
#if arch(arm64)
let info = ProcessorInfo.current
let arm = info.isa.arm

// NEON (Advanced SIMD)
if arm.neon.neon {
    print("NEON supported")
    print("  Dot product: \(arm.neon.dotProd)")
    print("  BFloat16: \(arm.neon.bf16)")
}

// SVE (Scalable Vector Extension)
if arm.sve.sve {
    print("SVE supported")
    print("  SVE2: \(arm.sve.sve2)")
}

// SME (Scalable Matrix Extension)
if arm.sme.sme {
    print("SME supported")
}

// Cryptographic extensions
print("AES: \(arm.aes)")
print("SHA-2: \(arm.sha2)")

// Atomics (Large System Extensions)
print("LSE atomics: \(arm.atomics)")
#endif
```

## x86 Feature Detection

On x86-64 systems, access features through `ISAFeatures.x86`:

```swift
#if arch(x86_64)
let info = ProcessorInfo.current
let x86 = info.isa.x86

// SSE family
print("SSE4.2: \(x86.sse.sse4_2)")

// AVX family
print("AVX2: \(x86.avx.avx2)")
print("AVX-512F: \(x86.avx.avx512f)")

// AMX (Advanced Matrix Extensions)
if x86.amx.tile {
    print("AMX Tile supported")
}

// Other features
print("AES-NI: \(x86.aes)")
print("POPCNT: \(x86.popcnt)")
print("FMA3: \(x86.fma3)")
#endif
```

## Choosing a Code Path

Both feature sets compile everywhere, and on the other architecture every flag reads `false`, so a runtime check needs no conditional compilation:

```swift
let isa = ProcessorInfo.current.isa

if isa.x86.avx.avx512f {
    // AVX-512 path; false on ARM
} else if isa.arm.sve.sve2 {
    // SVE2 path; false on x86
}
```

Keep `#if arch(...)` for code that only builds on one architecture, such as SIMD intrinsics or inline assembly.
