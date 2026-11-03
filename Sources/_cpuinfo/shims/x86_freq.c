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

/* x86_freq.c — CPUID leaf 0x15 (TSC/crystal clock) and leaf 0x16 (processor frequency) */
#include <cpuinfo.h>
#if CPUINFO_ARCH_X86 || CPUINFO_ARCH_X86_64

#include <cpuinfo_x86_freq.h>
#include <x86/cpuid.h>

/*
 * Crystal clock fallback for Intel family 6 when CPUID 0x15 ECX == 0.
 * Values sourced from Intel SDM Vol. 3, Table 19-4 and related sections.
 * Returns crystal clock frequency in Hz, or 0 if model is unrecognized.
 */
static uint64_t cpuinfo_x86_infer_crystal_clock(const struct cpuinfo_x86_model_info *model_info) {
    /* Only Intel family 6 has documented crystal clock values */
    if (model_info->family != 6) {
        return 0;
    }

    switch (model_info->model) {
        /* 24 MHz — Skylake / Kaby Lake / Coffee Lake / Whiskey Lake / Comet Lake (client) */
        case 0x4E: /* Skylake (mobile) */
        case 0x5E: /* Skylake (desktop) */
        case 0x8E: /* Kaby Lake (mobile) / Whiskey Lake / Amber Lake / Coffee Lake */
        case 0x9E: /* Kaby Lake (desktop) / Coffee Lake */
        case 0xA5: /* Comet Lake (desktop) */
        case 0xA6: /* Comet Lake (mobile) */
            return 24000000;

        /* 25 MHz — Skylake-X / Cascade Lake / Ice Lake server / Denverton */
        case 0x55: /* Skylake-X / Cascade Lake / Cooper Lake */
        case 0x6A: /* Ice Lake-SP (server) */
        case 0x6C: /* Ice Lake-D */
        case 0x5F: /* Goldmont (Denverton); matches Linux tsc.c */
            return 25000000;

        /* 19.2 MHz — Atom Goldmont / Goldmont Plus / Tremont */
        case 0x5C: /* Goldmont (Apollo Lake) */
        case 0x7A: /* Goldmont Plus (Gemini Lake) */
        case 0x86: /* Tremont (Jacobsville) */
        case 0x96: /* Tremont (Elkhart Lake) */
        case 0x9C: /* Tremont (Jasper Lake) */
            return 19200000;

        /* 24 MHz — Ice Lake / Tiger Lake / Cannon Lake / Rocket Lake (client) */
        case 0x66: /* Cannon Lake */
        case 0x7D: /* Ice Lake (desktop) */
        case 0x7E: /* Ice Lake (mobile) */
        case 0x8C: /* Tiger Lake (mobile) */
        case 0x8D: /* Tiger Lake (desktop) */
        case 0xA7: /* Rocket Lake */
            return 24000000;

        /* 24 MHz — Alder Lake / Raptor Lake / Meteor Lake (client) */
        case 0x97: /* Alder Lake (desktop) */
        case 0x9A: /* Alder Lake (mobile) */
        case 0xB7: /* Raptor Lake (desktop) */
        case 0xBA: /* Raptor Lake (mobile) */
        case 0xBF: /* Raptor Lake-S refresh */
        case 0xAA: /* Meteor Lake */
        case 0xAC: /* Meteor Lake */
            return 24000000;

        /* 38.4 MHz — Atom: Alder Lake-N / Sierra Forest / Grand Ridge */
        case 0xBE: /* Alder Lake-N */
        case 0xAF: /* Sierra Forest */
        case 0xB6: /* Grand Ridge */
            return 38400000;

        default:
            return 0;
    }
}

struct cpuinfo_x86_tsc_info cpuinfo_x86_query_tsc_info(void) {
    struct cpuinfo_x86_tsc_info result = {0};

    /* Check max supported leaf */
    const struct cpuid_regs leaf0 = cpuid(0);
    if (leaf0.eax < 0x15) {
        return result;
    }

    const struct cpuid_regs leaf15 = cpuid(0x15);

    /* EAX (denominator) and EBX (numerator) must both be non-zero for a valid ratio */
    if (leaf15.eax == 0 || leaf15.ebx == 0) {
        return result;
    }

    result.available = true;
    result.denominator = leaf15.eax;
    result.numerator = leaf15.ebx;

    /* ECX may directly report the crystal clock frequency */
    if (leaf15.ecx != 0) {
        result.crystal_clock_hz = (uint64_t)leaf15.ecx;
        result.crystal_clock_known = true;
    } else {
        /* Attempt model-based inference (Intel only) */
        const struct cpuid_regs leaf1 = cpuid(1);
        const enum cpuinfo_vendor vendor = cpuinfo_x86_decode_vendor(leaf0.ebx, leaf0.ecx, leaf0.edx);
        if (vendor == cpuinfo_vendor_intel) {
            const struct cpuinfo_x86_model_info model_info = cpuinfo_x86_decode_model_info(leaf1.eax);
            result.crystal_clock_hz = cpuinfo_x86_infer_crystal_clock(&model_info);
        }
        result.crystal_clock_known = false;
    }

    /* Compute TSC frequency if crystal clock is available */
    if (result.crystal_clock_hz != 0) {
        result.tsc_frequency_hz = result.crystal_clock_hz * (uint64_t)result.numerator / (uint64_t)result.denominator;
    }

    return result;
}

struct cpuinfo_x86_freq_info cpuinfo_x86_query_freq_info(void) {
    struct cpuinfo_x86_freq_info result = {0};

    /* Check max supported leaf */
    const struct cpuid_regs leaf0 = cpuid(0);
    if (leaf0.eax < 0x16) {
        return result;
    }

    const struct cpuid_regs leaf16 = cpuid(0x16);

    /* At least base frequency should be non-zero for the data to be useful */
    if (leaf16.eax == 0 && leaf16.ebx == 0 && leaf16.ecx == 0) {
        return result;
    }

    result.available = true;
    result.base_frequency_mhz = leaf16.eax & 0xFFFF;
    result.max_frequency_mhz = leaf16.ebx & 0xFFFF;
    result.bus_frequency_mhz = leaf16.ecx & 0xFFFF;

    return result;
}

bool cpuinfo_x86_has_invariant_tsc(void) {
    /* Check max extended leaf */
    const struct cpuid_regs ext0 = cpuid(0x80000000);
    if (ext0.eax < 0x80000007) {
        return false;
    }

    /* CPUID leaf 0x80000007 EDX bit 8: Invariant TSC */
    const struct cpuid_regs ext7 = cpuid(0x80000007);
    return (ext7.edx & UINT32_C(0x00000100)) != 0;
}

#endif /* CPUINFO_ARCH_X86 || CPUINFO_ARCH_X86_64 */
