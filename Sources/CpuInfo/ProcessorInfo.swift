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

internal import _cpuinfo
import Synchronization
#if canImport(Glibc)
internal import Glibc
#elseif canImport(Musl)
internal import Musl
#endif

/// Snapshot of the current system's processor topology, cache hierarchy,
/// and supported instruction sets.
///
/// `ProcessorInfo` is an immutable, `Sendable` value captured once at first
/// access and cached for the life of the process. Subsequent reads are O(1)
/// and allocation-free.
///
/// - Example:
/// ```swift
/// import CpuInfo
///
/// let info = ProcessorInfo.current
/// print("Cores: \(info.cores.count)")
/// if let l1d = info.caches.l1Data.first {
///     print("L1d: \(l1d.size / 1024) KiB")
/// }
/// ```
///
/// A system may have multiple physical processor packages (sockets), each
/// containing many cores with many logical processors — "CPU" would be
/// ambiguous, hence the name.
public struct ProcessorInfo: Sendable, Equatable, Hashable, Codable {
    /// Physical processor packages (sockets) in the system.
    public let packages: [ProcessorPackage]
    /// Clusters of cores grouped by microarchitecture.
    public let clusters: [Cluster]
    /// Physical processor cores.
    public let cores: [Core]
    /// Logical processors (hardware threads).
    public let logicalProcessors: [LogicalProcessor]
    /// The system's cache hierarchy organized by level.
    public let caches: CacheHierarchy
    /// Instruction set features supported by the processor.
    public let isa: ISAFeatures
    /// TSC / crystal-clock information from CPUID leaf 0x15.
    /// `nil` on non-x86 hosts and on x86 hosts that do not expose the leaf.
    public let tsc: TSCInfo?
    /// Processor frequency tiers from CPUID leaf 0x16.
    /// `nil` on non-x86 hosts and on x86 hosts that do not expose the leaf.
    public let frequency: ProcessorFrequencyInfo?

    // MARK: - Cached singleton

    private static let _cached = Mutex<Result<Self, CpuInfoError>?>(nil)

    /// The processor information for the current host.
    ///
    /// The first access initializes the underlying cpuinfo library and caches
    /// the result for the life of the process. Subsequent accesses are O(1).
    ///
    /// - Precondition: The host exposes CPU topology. All supported OSes do.
    /// - Note: Traps on catastrophic initialization failure (out-of-memory,
    ///         a kernel that refuses to expose CPU info, or an overly
    ///         restrictive sandbox). For explicit error handling, use
    ///         ``init()``.
    ///
    /// - Example:
    /// ```swift
    /// let info = ProcessorInfo.current
    /// for cluster in info.clusters {
    ///     print("\(cluster.microarchitecture): \(cluster.coreCount) cores")
    /// }
    /// ```
    public static var current: Self {
        switch loadOrCached() {
        case .success(let info): return info
        case .failure(let error):
            fatalError("ProcessorInfo.current: \(error)")
        }
    }

    /// Loads processor information for the current host, throwing if the
    /// underlying cpuinfo library cannot be initialized.
    ///
    /// The outcome of the first call, failure included, is cached for the life of
    /// the process: later calls (including of ``current``) return it without
    /// re-running initialization. Upstream cpuinfo initializes only once per
    /// process, so a retry could not succeed anyway.
    ///
    /// - Throws: ``CpuInfoError`` with ``CpuInfoError/Code/initializationFailed``
    ///   if cpuinfo initialization fails. The exact failure mode (OOM,
    ///   unsupported kernel, sandbox) is written to the cpuinfo log on stderr.
    ///
    /// - Example:
    /// ```swift
    /// do {
    ///     let info = try ProcessorInfo()
    ///     print("Cores: \(info.cores.count)")
    /// } catch {
    ///     print("Running in a degraded mode: \(error)")
    /// }
    /// ```
    public init() throws(CpuInfoError) {
        switch Self.loadOrCached() {
        case .success(let info): self = info
        case .failure(let error): throw error
        }
    }

    private static func loadOrCached() -> Result<Self, CpuInfoError> {
        _cached.withLock { cached in
            if let cached { return cached }
            guard cpuinfo_initialize() else {
                let result: Result<Self, CpuInfoError> =
                    .failure(CpuInfoError(code: .initializationFailed))
                cached = result
                return result
            }
            let result: Result<Self, CpuInfoError> = .success(Self(validated: ()))
            cached = result
            return result
        }
    }

    private init(validated: Void) {
        let tsc = TSCInfo.load()
        let freq = ProcessorFrequencyInfo.load()
        self.tsc = tsc
        self.frequency = freq
        let freqOverride = freq?.baseFrequencyHz

        packages = collect(count: cpuinfo_get_packages_count(), get: cpuinfo_get_package) {
            ProcessorPackage($0, index: $1)
        }
        clusters = collect(count: cpuinfo_get_clusters_count(), get: cpuinfo_get_cluster) {
            Cluster($0, index: $1, frequencyOverride: freqOverride)
        }
        cores = collect(count: cpuinfo_get_cores_count(), get: cpuinfo_get_core) {
            Core($0, index: $1, frequencyOverride: freqOverride)
        }
        logicalProcessors = collect(count: cpuinfo_get_processors_count(), get: cpuinfo_get_processor) {
            LogicalProcessor($0, index: $1)
        }
        caches = CacheHierarchy()
        isa    = ISAFeatures()
    }

    // MARK: - Thread context (host operations)
    //
    // These queries and the affinity setter operate on the *calling thread* of
    // the *current process*. They are host-level operations with no
    // relationship to any specific `ProcessorInfo` value — which is why they
    // live on the type rather than on an instance. Calling them on a decoded
    // snapshot from another machine would be meaningless, so the static form
    // removes the temptation.

    /// The logical processor the calling thread is currently scheduled on,
    /// indexed into ``ProcessorInfo/current``'s ``logicalProcessors``.
    ///
    /// Backed by `sched_getcpu(2)` on Linux; returns `nil` on macOS, iOS, and
    /// visionOS (no equivalent syscall) and on Linux when the kernel reports
    /// an ID outside the current host's topology (extremely unusual).
    ///
    /// The calling thread may be migrated to a different processor between
    /// this call returning and the caller inspecting the value. Use
    /// ``setCurrentThreadAffinity(_:)`` first to pin the thread.
    ///
    /// - Example:
    /// ```swift
    /// if let proc = ProcessorInfo.currentLogicalProcessor {
    ///     print("Thread on processor \(proc.id) (SMT \(proc.smtID))")
    /// }
    /// ```
    public static var currentLogicalProcessor: LogicalProcessor? {
        // cpuinfo aborts if queried before initialization, so load the cache first.
        guard case .success(let info) = loadOrCached(),
              let ptr = cpuinfo_get_current_processor(),
              let base = cpuinfo_get_processor(0) else { return nil }
        let index = ptr - base
        return info.logicalProcessors.indices.contains(index) ? info.logicalProcessors[index] : nil
    }

    /// The physical core the calling thread is currently scheduled on,
    /// indexed into ``ProcessorInfo/current``'s ``cores``.
    ///
    /// Same platform and transiency caveats as ``currentLogicalProcessor``.
    ///
    /// - Example:
    /// ```swift
    /// if let core = ProcessorInfo.currentCore {
    ///     print("Thread on core \(core.id) (\(core.microarchitecture))")
    /// }
    /// ```
    public static var currentCore: Core? {
        guard case .success(let info) = loadOrCached(),
              let ptr = cpuinfo_get_current_core(),
              let base = cpuinfo_get_core(0) else { return nil }
        let index = ptr - base
        return info.cores.indices.contains(index) ? info.cores[index] : nil
    }

    // MARK: - Thread affinity (host operation)

    /// The calling thread's current CPU-affinity mask.
    ///
    /// Returns the mask the kernel currently enforces for this thread: the
    /// set from the last ``setCurrentThreadAffinity(_:)`` call, bounded by
    /// restrictions such as a cgroup `cpuset.cpus` constraint.
    ///
    /// Returns `nil` on non-Linux (no equivalent of `sched_getaffinity(2)`)
    /// and on Linux if the `pthread_getaffinity_np(3)` call fails.
    ///
    /// - Example:
    /// ```swift
    /// if let allowed = ProcessorInfo.currentThreadAffinity {
    ///     print("Allowed CPUs: \(allowed.sortedCPUs)")
    /// }
    /// ```
    public static var currentThreadAffinity: CPUSet? {
        #if os(Linux)
        var cpuSet = cpu_set_t()
        guard cpuinfo_get_thread_affinity(&cpuSet) == 0 else { return nil }
        return CPUSet(cpuSet)
        #else
        return nil
        #endif
    }

    /// Pins the calling thread to the given set of logical processors.
    ///
    /// The set contains Linux CPU identifiers as exposed by
    /// ``LogicalProcessor/linuxID``. Pinning is a kernel-level scheduling
    /// constraint: the OS will not migrate this thread to a logical
    /// processor outside the set until the affinity is changed again.
    /// Threads created afterwards by this thread, and images it `execve(2)`s,
    /// inherit the mask; other existing threads keep theirs.
    ///
    /// - Parameter set: The CPUs the calling thread is allowed to run on.
    /// - Throws:
    ///   - ``CpuInfoError/Code/threadAffinityUnsupported`` on non-Linux
    ///     platforms (macOS, iOS, visionOS).
    ///   - ``CpuInfoError/Code/threadAffinityFailed`` if the underlying
    ///     `pthread_setaffinity_np(3)` call returns a non-zero status
    ///     (permission denied in a sandbox, `EINVAL` for an empty set or a
    ///     CPU outside the allowed mask, etc.), or if any ID is outside
    ///     `0..<CPU_SETSIZE` (the bad IDs are listed in ``CpuInfoError/diagnostic``).
    ///
    /// - Example:
    /// ```swift
    /// let info = ProcessorInfo.current
    /// guard let procID = ProcessorInfo.currentLogicalProcessor?.id,
    ///       let l2 = info.caches.l2.first(where: {
    ///           ($0.logicalProcessorOffset ..< $0.logicalProcessorOffset + $0.logicalProcessorCount)
    ///               .contains(procID)
    ///       })
    /// else { return }
    ///
    /// let siblingIDs = (l2.logicalProcessorOffset ..< l2.logicalProcessorOffset + l2.logicalProcessorCount)
    ///     .compactMap { info.logicalProcessors[$0].linuxID }
    /// try ProcessorInfo.setCurrentThreadAffinity(CPUSet(siblingIDs))
    /// ```
    public static func setCurrentThreadAffinity(_ set: CPUSet) throws(CpuInfoError) {
        #if os(Linux)
        var cpuSet = try set.cSet()
        let result = cpuinfo_set_thread_affinity(&cpuSet)
        guard result == 0 else {
            throw CpuInfoError(code: .threadAffinityFailed, errno: result, call: "pthread_setaffinity_np")
        }
        #else
        _ = set
        throw CpuInfoError(code: .threadAffinityUnsupported)
        #endif
    }
}

#if os(Linux)
extension CPUSet {
    init(_ cSet: cpu_set_t) {
        var cSet = cSet
        self.init((0..<Int(cpuinfo_cpu_setsize())).filter { cpuinfo_cpu_isset(Int32($0), &cSet) != 0 })
    }

    // CPU_SET silently ignores IDs outside 0..<CPU_SETSIZE, so reject them up front.
    func cSet() throws(CpuInfoError) -> cpu_set_t {
        let valid = 0..<Int(cpuinfo_cpu_setsize())
        let invalid = sortedCPUs.filter { !valid.contains($0) }
        guard invalid.isEmpty else {
            throw CpuInfoError(code: .threadAffinityFailed, diagnostic: "CPU IDs outside \(valid): \(invalid)")
        }
        var cSet = cpu_set_t()
        cpuinfo_cpu_zero(&cSet)
        for cpu in self {
            cpuinfo_cpu_set(Int32(cpu), &cSet)
        }
        return cSet
    }
}

extension CpuInfoError {
    init(code: Code, errno: Int32, call: String) {
        self.init(code: code, diagnostic: "\(call) failed: \(String(cString: strerror(errno))) (errno \(errno))")
    }
}
#endif
