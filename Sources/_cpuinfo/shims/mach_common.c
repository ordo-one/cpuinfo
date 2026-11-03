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

#ifdef __APPLE__
/* Upstream narrows the uint64_t hw.cacheconfig values to uint32_t; silenced here
 * so the vendored file stays as shipped. */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wshorten-64-to-32"
#include "../src/mach/topology.c"
#pragma clang diagnostic pop
#endif
