//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// `Logging` conforming instances provide a convenience method to generate a `Logger` instance
public protocol Logging: class {

    /// Will generate a new `Logger` instance with the given identifier
    /// - Parameter logIdentifier: Identifier (preferably unique) used in the output message when logging
    func createLogger(_ logIdentifier: String) -> Logger
}
