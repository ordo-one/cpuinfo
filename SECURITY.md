# Security Policy

## Scope

CpuInfo is a read-only introspection library that wraps [pytorch/cpuinfo](https://github.com/pytorch/cpuinfo). It queries the host processor once at first use and returns an immutable `Sendable` snapshot. It does not accept untrusted input, open network connections, or write to the filesystem. On x86 it issues `CPUID` instructions; on Linux it reads `/proc/cpuinfo` and files under `/sys/devices/system/cpu`; on Apple platforms it calls `sysctl` / `host_info`. The optional affinity helpers are Linux-only and act on the calling thread: `setCurrentThreadAffinity(_:)` / `currentThreadAffinity` call `pthread_setaffinity_np` / `pthread_getaffinity_np`.

## Potential Concerns

- **Vendored C code surface.** The bulk of the runtime logic lives in the vendored C library under `Sources/_cpuinfo/`. Detection-logic bugs (incorrect feature flags, wrong microarchitecture mapping, crashes on unfamiliar CPUs) should be reported to the upstream [pytorch/cpuinfo](https://github.com/pytorch/cpuinfo) project. Memory-safety issues anywhere in the package, including the vendored C code, are in scope for this repository - we will coordinate with upstream and ship a patched pin.
- **Kernel-provided data on Linux.** Parsing of `/proc/cpuinfo` and `/sys` happens in upstream C. A deliberately malformed kernel ABI could in principle exercise parser edge cases; in practice this requires a compromised kernel, which is already a higher privilege than this library grants.
- **Thread affinity.** `setCurrentThreadAffinity(_:)` applies a caller-controlled mask to the calling thread. Changing your own thread's mask needs no privilege (`CAP_SYS_NICE` matters only for other users' threads), but a seccomp filter or a cgroup cpuset can still reject it, so handle the thrown error.
- **One-shot initialization.** `ProcessorInfo.current` initializes cpuinfo once per process and never tears it down — this is intentional (cpuinfo is designed for process-lifetime use) but means there is no way to reclaim its small internal allocations before `exit`.

## Reporting a Vulnerability

Please do not open a public issue. Report via the repository's Security tab > Report a vulnerability (GitHub private vulnerability reporting).

We aim to respond within 30 days for confirmed vulnerabilities.

## Supported Versions

Security fixes land on `main` and are released as a new patch version. Only the latest minor release line receives fixes.
