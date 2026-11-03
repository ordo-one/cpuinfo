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

#include <cpuinfo.h>
#if (CPUINFO_ARCH_ARM || CPUINFO_ARCH_ARM64) && defined(__linux__)
#include "../src/arm/linux/init.c"
#include "../src/arm/linux/cpuinfo.c"
#include "../src/arm/linux/chipset.c"
#include "../src/arm/linux/hwcap.c"
#if CPUINFO_ARCH_ARM
#include "../src/arm/linux/aarch32-isa.c"
#endif
#if CPUINFO_ARCH_ARM64
#include "../src/arm/linux/aarch64-isa.c"
#endif
#endif
