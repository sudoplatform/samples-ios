//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Generic non-specific error.
public struct AnyError: Error, CustomStringConvertible, LocalizedError, Equatable {

    // MARK: Properties

    /// A descrption of error.
    public let description: String

    // MARK: - Lifecycle

    /// Initialize an instance.
    ///
    /// - Parameters:
    ///     - description: A description of error.
    public init(_ description: String) {
        self.description = description
    }

    /// Initialize an instance.
    ///
    /// - Parameters:
    ///     - other: An other error.
    public init(_ other: Error) {
        self.init(String(describing: other))
    }

    /// An unknown error.
    public static var unknown: AnyError {
        return AnyError("An unknown error occurred.")
    }

    // MARK: - Conformance: LocalizedError

    public var errorDescription: String? {
        return description
    }
}
