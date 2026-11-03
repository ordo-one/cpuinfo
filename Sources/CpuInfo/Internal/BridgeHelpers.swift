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

// MARK: - Fixed C char array → String

/// Reads a null-terminated string from a fixed-size inline C char array
/// (represented as a Swift tuple).
///
/// Callers must copy the C struct to a local `var` before passing the
/// char-array field, because `withUnsafeBytes(of:)` requires `inout`.
@inline(__always)
func stringFromFixedCString<T>(_ tuple: inout T) -> String {
    withUnsafeBytes(of: &tuple) { rawBuf in
        let length = rawBuf.firstIndex(of: 0) ?? rawBuf.count
        guard length > 0 else { return "" }
        // swiftlint:disable:next optional_data_string_conversion
        return String(decoding: rawBuf[..<length], as: UTF8.self)
    }
}

// MARK: - Safe count helper

/// Converts a cpuinfo UInt32 count to a Range<Int>.
@inline(__always)
func safeRange(_ count: UInt32) -> Range<Int> {
    0..<Int(count)
}

/// Builds one model per cpuinfo element, skipping indices whose getter returns `nil`.
@inline(__always)
func collect<C, T>(
    count: UInt32,
    get: (UInt32) -> UnsafePointer<C>?,
    make: (UnsafePointer<C>, Int) -> T
) -> [T] {
    safeRange(count).compactMap { index in get(UInt32(index)).map { make($0, index) } }
}
