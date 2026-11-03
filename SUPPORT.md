# Getting Support

This page routes questions and issues to the right place. CpuInfo is a thin Swift wrapper around [pytorch/cpuinfo](https://github.com/pytorch/cpuinfo), so the correct channel depends on what you're seeing.

## Is it a CPU-detection issue, or a wrapper issue?

**Report upstream — [pytorch/cpuinfo issues](https://github.com/pytorch/cpuinfo/issues)**

- Wrong microarchitecture (e.g. your new CPU is reported as `.unknown` or as a previous generation)
- Wrong instruction-set flags (a feature is reported `true`/`false` against CPUID reality)
- Wrong cache geometry (size, line size, associativity, sharing topology)
- Wrong topology (cores, clusters, logical-processor counts) on a given CPU model

This package does not modify upstream detection logic. Opening these upstream gets the fix to every language wrapper (PyTorch, Swift, Rust, …) at once. Once upstream merges a fix, ping us and we will bump the vendored commit.

**Report here — [ordo-one/cpuinfo issues](https://github.com/ordo-one/cpuinfo/issues)**

- Swift API behaviour: `ProcessorInfo`, `CPUSet`, `CpuInfoError`, typed-throws surfaces, Codable round-trips, host operations (`currentCore`, `currentLogicalProcessor`, `currentThreadAffinity`, `setCurrentThreadAffinity`)
- TSC and frequency values (`ProcessorInfo.tsc`, `ProcessorInfo.frequency`, `isa.x86.invariantTSC`): this package reads CPUID leaves 0x15, 0x16, and 0x80000007 itself, so wrong values belong here, not upstream
- Build / `Package.swift` / platform-wiring problems
- Documentation, example, DocC, or README bugs
- Vendor-bump script (`Scripts/update-cpuinfo.sh`) issues
- Crashes, undefined behaviour, or memory-safety issues in any layer, including the vendored C library (in scope here even if the root cause is upstream - we will coordinate; report exploitable ones privately per [SECURITY.md](SECURITY.md))

## Include this in every bug report

The runtime exposes two constants and a snapshot dump that collapse most "what version / what CPU?" back-and-forth. Please paste them into the issue:

```swift
print("cpuinfo \(CpuInfoVersion.packageVersion) (upstream \(CpuInfoVersion.vendoredCpuinfoCommit.prefix(12)))")
print("Architecture: \(Architecture.current)")
// Optional but extremely helpful on topology / cache / feature-flag bugs:
let json = try JSONEncoder().encode(ProcessorInfo.current)
print(String(data: json, encoding: .utf8)!)
```

Also state the host OS and version, the Swift toolchain version (`swift --version`), and whether the binary is being run natively, under Rosetta 2, or inside a container/cgroup.

## Feature requests

Open an issue with the `enhancement` label. Before doing so, check whether the feature belongs upstream — see the first section above. Wrapper-level ergonomics, Swift-native helpers, additional `Codable` fixtures, and DocC improvements are always in scope here.

## Security

See [SECURITY.md](SECURITY.md) for vulnerability disclosure and response SLA.

## Usage questions

1. Check the rendered [DocC documentation](https://swiftpackageindex.com/ordo-one/cpuinfo/documentation/cpuinfo) — `GettingStarted`, `ProcessorTopology`, `CacheHierarchyGuide`, `ISAFeatureDetection`, and `Examples` cover the common cases.
2. Check the [README](README.md) — it has runnable snippets for every major feature.
3. Look at `Examples/lscpu` and `Examples/linuxPin` — they are full working programs exercising the public API end-to-end.
4. If none of the above answers your question, open an issue and prefix the title with `question:`. We treat these as low-priority but will respond within roughly 30 days, same as security reports.

## Response expectations

CpuInfo is maintained by a small team and is not a commercial product. We aim for a first response within 30 days on confirmed bugs and security reports; feature requests and usage questions may take longer. Tagged releases follow SemVer.
