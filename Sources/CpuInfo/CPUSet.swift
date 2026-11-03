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

/// A set of Linux CPU identifiers suitable for thread-affinity operations.
///
/// `CPUSet` is a Swift-native replacement for the Linux `cpu_set_t` bitmap.
/// It is value-typed, `Sendable`, `Hashable`, and conforms to `SetAlgebra`
/// — so it composes with the same `Set`-style vocabulary (`union`,
/// `intersection`, `isSubset(of:)`, etc.) that Swift programmers already know.
///
/// `CPUSet` can be constructed on any platform; applying it to a thread via
/// ``ProcessorInfo/setCurrentThreadAffinity(_:)`` is Linux-only (throws
/// ``CpuInfoError/Code/threadAffinityUnsupported`` elsewhere). This lets
/// the same build target author both cross-platform binaries and the
/// Linux-conditional affinity logic.
///
/// Elements are `Int` Linux CPU identifiers as exposed by
/// ``LogicalProcessor/linuxID``.
///
/// - Example:
/// ```swift
/// let info = ProcessorInfo.current
/// var set: CPUSet = []
/// for proc in info.logicalProcessors {
///     if let id = proc.linuxID { set.insert(id) }
/// }
/// try ProcessorInfo.setCurrentThreadAffinity(set) // Linux only
/// ```
public struct CPUSet: Sendable, Equatable, Hashable, ExpressibleByArrayLiteral {
    @usableFromInline
    internal var storage: Set<Int>

    /// Creates an empty CPU set.
    public init() { storage = [] }

    /// Creates a CPU set containing the given CPU identifiers.
    public init<S: Sequence>(_ cpus: S) where S.Element == Int {
        storage = Set(cpus)
    }

    /// Creates a CPU set from an array literal of CPU identifiers.
    public init(arrayLiteral elements: Int...) {
        storage = Set(elements)
    }

    /// The CPU identifiers contained in this set, in ascending order.
    public var sortedCPUs: [Int] { storage.sorted() }

    /// The number of CPUs in this set.
    public var count: Int { storage.count }

    /// Whether the set contains no CPUs.
    public var isEmpty: Bool { storage.isEmpty }
}

// MARK: - SetAlgebra conformance

extension CPUSet: SetAlgebra {
    public typealias Element = Int

    public func contains(_ member: Int) -> Bool {
        storage.contains(member)
    }

    public func union(_ other: CPUSet) -> CPUSet {
        var copy = self
        copy.formUnion(other)
        return copy
    }

    public func intersection(_ other: CPUSet) -> CPUSet {
        var copy = self
        copy.formIntersection(other)
        return copy
    }

    public func symmetricDifference(_ other: CPUSet) -> CPUSet {
        var copy = self
        copy.formSymmetricDifference(other)
        return copy
    }

    @discardableResult
    public mutating func insert(_ newMember: Int) -> (inserted: Bool, memberAfterInsert: Int) {
        storage.insert(newMember)
    }

    @discardableResult
    public mutating func remove(_ member: Int) -> Int? {
        storage.remove(member)
    }

    @discardableResult
    public mutating func update(with newMember: Int) -> Int? {
        storage.update(with: newMember)
    }

    public mutating func formUnion(_ other: CPUSet) {
        storage.formUnion(other.storage)
    }

    public mutating func formIntersection(_ other: CPUSet) {
        storage.formIntersection(other.storage)
    }

    public mutating func formSymmetricDifference(_ other: CPUSet) {
        storage.formSymmetricDifference(other.storage)
    }
}

// MARK: - Sequence / convenience

extension CPUSet: Sequence {
    public func makeIterator() -> Set<Int>.Iterator {
        storage.makeIterator()
    }
}

extension CPUSet: CustomStringConvertible {
    public var description: String {
        "CPUSet(\(sortedCPUs.map(String.init).joined(separator: ", ")))"
    }
}
