---
name: Bug Report
about: Report a problem with the Swift wrapper
labels: bug
---

## Environment

- **Platform and OS version**: <!-- e.g. macOS 26.1 / Ubuntu 24.04 / iOS Simulator -->
- **Swift version**: <!-- output of `swift --version` -->
- **Architecture**: <!-- arm64 / x86_64 / x86_64 (Rosetta 2) -->
- **Running in a container or VM**: <!-- no / Docker / Apple container / other -->

## Version and snapshot

<!--
Paste the output of this snippet (see SUPPORT.md). The JSON snapshot is optional,
but it settles most topology, cache, and feature-flag questions straight away.

print("cpuinfo \(CpuInfoVersion.packageVersion) (upstream \(CpuInfoVersion.vendoredCpuinfoCommit.prefix(12)))")
print("Architecture: \(Architecture.current)")
let json = try JSONEncoder().encode(ProcessorInfo.current)
print(String(data: json, encoding: .utf8)!)
-->

```
```

## Description

<!-- A clear description of the bug. -->

## Steps to Reproduce

1.
2.
3.

## Expected Behavior

<!-- What you expected to happen. -->

## Actual Behavior

<!-- What actually happened. Include any error messages or output. -->

> **Note:** If this is a CPU detection or microarchitecture identification issue, please report it upstream at [pytorch/cpuinfo](https://github.com/pytorch/cpuinfo). This package is a Swift wrapper and does not modify the upstream detection logic.
