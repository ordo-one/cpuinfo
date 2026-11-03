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
#include "../src/arm/linux/midr.c"
#endif
