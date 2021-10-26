//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Class that abstracts `LogDriverProtocol` instance and provides convenience methods for general logging
public final class Logger {

    // MARK: - Properties

    /// `LogDriverProtocol` conforming instance to send any output message requests to
    private let driver: LogDriverProtocol

    /// Identifier (usually unique) used in the output message when logging
    public let logIdentifier: String

    // MARK: - Lifecycle

    public init(identifier: String, driver: LogDriverProtocol) {
        logIdentifier = identifier
        self.driver = driver
    }

    // MARK: - Helpers: Internal

    internal func log(_ logLevel: LogLevel, closure: () -> String?, function: String, file: String, line: Int) {
        guard logLevel >= self.driver.logLevel else {
            return
        }

        guard let message = closure() else {
            return
        }

        let details = LogDetails(
            identifier: logIdentifier,
            level: logLevel,
            date: Date(),
            message: message,
            function: function,
            file: file,
            line: line
        )

        let outputMessage = driver.processDetails(details)
        driver.outputMessage(outputMessage)
    }

    // MARK: - Helpers: Public

    /// Will log the result of the given message closure with the underlying driver using the `LogLevel.verbose` level.
    /// **Note:** The `message` can also be a direct string that will automatically be turned into a closure.
    /// - Parameters:
    ///   - message: The message to log
    public func verbose(_ message: @autoclosure () -> String?, function: String = #function, file: String = #file, line: Int = #line) {
        log(.verbose, closure: message, function: function, file: file, line: line)
    }

    /// Will log the result of the given message closure with the underlying driver using the `LogLevel.verbose` level
    /// - Parameters:
    ///   - message: The message to log
    public func verbose(_ function: String = #function, file: String = #file, line: Int = #line, message: () -> String?) {
        log(.verbose, closure: message, function: function, file: file, line: line)
    }

    /// Will log the result of the given message closure with the underlying driver using the `LogLevel.debug` level.
    /// **Note:** The `message` can also be a direct string that will automatically be turned into a closure.
    /// - Parameters:
    ///   - message: The message to log
    public func debug(_ message: @autoclosure () -> String?, function: String = #function, file: String = #file, line: Int = #line) {
        log(.debug, closure: message, function: function, file: file, line: line)
    }

    /// Will log the result of the given message closure with the underlying driver using the `LogLevel.debug` level
    /// - Parameters:
    ///   - message: The message to log
    public func debug(_ function: String = #function, file: String = #file, line: Int = #line, message: () -> String?) {
        log(.debug, closure: message, function: function, file: file, line: line)
    }

    /// Will log the result of the given message closure with the underlying driver using the `LogLevel.info` level.
    /// **Note:** The `message` can also be a direct string that will automatically be turned into a closure.
    /// - Parameters:
    ///   - message: The message to log
    public func info(_ message: @autoclosure () -> String?, function: String = #function, file: String = #file, line: Int = #line) {
        log(.info, closure: message, function: function, file: file, line: line)
    }

    /// Will log the result of the given message closure with the underlying driver using the `LogLevel.info` level
    /// - Parameters:
    ///   - message: The message to log
    public func info(_ function: String = #function, file: String = #file, line: Int = #line, message: () -> String?) {
        log(.info, closure: message, function: function, file: file, line: line)
    }

    /// Will log the result of the given message closure with the underlying driver using the `LogLevel.warning` level.
    /// **Note:** The `message` can also be a direct string that will automatically be turned into a closure.
    /// - Parameters:
    ///   - message: The message to log
    public func warning(_ message: @autoclosure () -> String?, function: String = #function, file: String = #file, line: Int = #line) {
        log(.warning, closure: message, function: function, file: file, line: line)
    }

    /// Will log the result of the given message closure with the underlying driver using the `LogLevel.warning` level
    /// - Parameters:
    ///   - message: The message to log
    public func warning(_ function: String = #function, file: String = #file, line: Int = #line, message: () -> String?) {
        log(.warning, closure: message, function: function, file: file, line: line)
    }

    /// Will log the result of the given message closure with the underlying driver using the `LogLevel.error` level.
    /// **Note:** The `message` can also be a direct string that will automatically be turned into a closure.
    /// - Parameters:
    ///   - message: The message to log
    public func error(_ message: @autoclosure () -> String?, function: String = #function, file: String = #file, line: Int = #line) {
        log(.error, closure: message, function: function, file: file, line: line)
    }

    /// Will log the result of the given message closure with the underlying driver using the `LogLevel.error` level
    /// - Parameters:
    ///   - message: The message to log
    public func error(_ function: String = #function, file: String = #file, line: Int = #line, message: () -> String?) {
        log(.error, closure: message, function: function, file: file, line: line)
    }

    /// Will output, but not log, the given error instance
    /// - Parameters:
    ///   - error: The error to send
    ///   - userInfo: Optional dictionary of error keys and values to send with the error
    public func outputError(_ error: Error, withUserInfo userInfo: [String: Any]? = nil) {
        driver.outputError(error, withUserInfo: userInfo)
    }
}
