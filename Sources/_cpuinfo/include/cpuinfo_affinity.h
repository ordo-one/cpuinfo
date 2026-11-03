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

#pragma once

#ifdef __linux__
#include <sched.h>
#include <pthread.h>

void cpuinfo_cpu_zero(cpu_set_t *set);
void cpuinfo_cpu_set(int cpu, cpu_set_t *set);
int cpuinfo_cpu_isset(int cpu, const cpu_set_t *set);
int cpuinfo_set_thread_affinity(cpu_set_t *set);
int cpuinfo_get_thread_affinity(cpu_set_t *set);
int cpuinfo_cpu_setsize(void);
#endif
