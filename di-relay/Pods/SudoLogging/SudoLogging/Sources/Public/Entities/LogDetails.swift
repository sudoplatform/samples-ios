//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Basic struct holding information about a log request
public struct LogDetails: Equatable {

    /// The identifier assigned to the `Logger` instance that invoked the output message
    public var identifier: String

    /// The `LogLevel` type for the output
    public var level: LogLevel

    /// The datetime the message was logged
    public var date: Date

    /// The message being logged
    public var message: String

    /// The function that invoked the log
    public var function: String

    /// The file the invoking `function` resides in
    public var file: String

    /// The line within the invoking `function`
    public var line: Int
}
