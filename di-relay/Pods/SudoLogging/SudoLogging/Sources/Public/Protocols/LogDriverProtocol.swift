//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// `LogDriverProtocol` conforming instance
public protocol LogDriverProtocol {

    /// The maximum `LogLevel` type the driver can process. Any logs above this level will not be logged.
    var logLevel: LogLevel { get set }

    /// Will process the given `LogDetails` instance and output a formatted message for logging
    /// - Parameter details: The details to process
    func processDetails(_ details: LogDetails) -> String

    /// Will log the given message to whatever mechanism the driver instance supports
    /// - Parameter message: The message to log
    func outputMessage(_ message: String)

    /// Will process the given error in whatever way the driver instance supports
    /// - Parameters:
    ///   - error: The error to process
    ///   - userInfo: Optional dictionary of error keys and values that provide additional error information
    func outputError(_ error: Error, withUserInfo userInfo: [String: Any]?)
}

// MARK: - Default `LogDriverProtocol` behaviour

public extension LogDriverProtocol {

    func processDetails(_ details: LogDetails) -> String {
        let date = "\(details.date)"
        let level = "\(details.level)"
        let identifier = details.identifier
        let fileName = "\((details.file as NSString).lastPathComponent):\(details.line)"
        let functionName = details.function
        let message = details.message

        return "\(date) [\(level)] [\(identifier)] [\(fileName)] \(functionName) > \(message)"
    }
}
