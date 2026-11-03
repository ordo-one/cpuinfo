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
#if CPUINFO_ARCH_X86 || CPUINFO_ARCH_X86_64
#include "../src/x86/init.c"
#include "../src/x86/info.c"
#include "../src/x86/isa.c"
#include "../src/x86/vendor.c"
#include "../src/x86/uarch.c"
#include "../src/x86/name.c"
#include "../src/x86/topology.c"
#include "../src/x86/cache/init.c"
#include "../src/x86/cache/descriptor.c"
#endif
