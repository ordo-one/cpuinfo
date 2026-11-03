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
#if (CPUINFO_ARCH_X86 || CPUINFO_ARCH_X86_64) && defined(__linux__)
#include "../src/x86/linux/init.c"
#include "../src/x86/linux/cpuinfo.c"
#endif
