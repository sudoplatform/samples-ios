//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// `LogDriverProtocol` conforming instance that logs any messages and output errors using the `NSLog` helper
public struct NSLogDriver: LogDriverProtocol {

    // MARK: - Properties: Static

    /// Shared and immutable driver instance that uses the `LogLevel.info` logging level
    public static let sharedInstance = NSLogDriver(level: .info)

    // MARK: - Properties: LogDriverProtocol

    public var logLevel: LogLevel

    // MARK: - Lifecycle

    public init(level: LogLevel) {
        self.logLevel = level
    }

    // MARK: - Conformance: LogDriverProtocol

    public func outputMessage(_ message: String) {
        NSLog("%@", message)
    }

    public func outputError(_ error: Error, withUserInfo userInfo: [String: Any]?) {
        NSLog("%@", error as NSError)
    }
}
