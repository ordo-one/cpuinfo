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

/* cpuinfo_x86_freq.h — CPUID leaf 0x15 (TSC/crystal clock) and leaf 0x16 (processor frequency) */
#pragma once

#include <cpuinfo.h>

#if CPUINFO_ARCH_X86 || CPUINFO_ARCH_X86_64

#include <stdbool.h>
#include <stdint.h>

struct cpuinfo_x86_tsc_info {
    /* CPUID leaf 0x15 EAX: denominator of TSC/crystal ratio */
    uint32_t denominator;
    /* CPUID leaf 0x15 EBX: numerator of TSC/crystal ratio */
    uint32_t numerator;
    /* Crystal clock frequency in Hz (from ECX, or inferred from CPU model) */
    uint64_t crystal_clock_hz;
    /* Computed TSC frequency in Hz: crystal_clock_hz * numerator / denominator */
    uint64_t tsc_frequency_hz;
    /* True if crystal_clock_hz was reported by CPUID (ECX != 0) rather than model-inferred */
    bool crystal_clock_known;
    /* True if leaf 0x15 is supported and returned valid ratio data */
    bool available;
};

struct cpuinfo_x86_freq_info {
    /* CPUID leaf 0x16 EAX: processor base frequency in MHz */
    uint32_t base_frequency_mhz;
    /* CPUID leaf 0x16 EBX: maximum frequency in MHz */
    uint32_t max_frequency_mhz;
    /* CPUID leaf 0x16 ECX: bus (reference) frequency in MHz */
    uint32_t bus_frequency_mhz;
    /* True if leaf 0x16 is supported */
    bool available;
};

/* Query TSC/crystal clock info via CPUID leaf 0x15.
 * Standalone — does not depend on cpuinfo_initialize(). */
struct cpuinfo_x86_tsc_info cpuinfo_x86_query_tsc_info(void);

/* Query processor frequency info via CPUID leaf 0x16.
 * Standalone — does not depend on cpuinfo_initialize(). */
struct cpuinfo_x86_freq_info cpuinfo_x86_query_freq_info(void);

/* Check for invariant TSC (CPUID leaf 0x80000007 EDX bit 8).
 * Standalone — does not depend on cpuinfo_initialize(). */
bool cpuinfo_x86_has_invariant_tsc(void);

#endif /* CPUINFO_ARCH_X86 || CPUINFO_ARCH_X86_64 */
