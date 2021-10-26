//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// A custom logger for `SudoKeyManager`.
class Logger {
    
    static let sharedInstance = Logger()

    enum LogLevel: Int {
        case none = 0
        case error
        case warn
        case info
        case debug
        
        func toString() -> String {
            switch self {
            case .none: return "NONE"
            case .error: return "ERROR"
            case .warn: return "WARN"
            case .info: return "INFO"
            case .debug: return "DEBUG"
            }
        }
    }

    /// Log level.
    var logLevel: LogLevel = .info
    
    /// Logs the given message at a specific log level.
    ///
    /// - Parameters:
    ///   - logLevel: Log level.
    ///   - message: Log message.
    ///   - function: Name of the calling function.
    ///   - file: Name of the source file where this method is called.
    ///   - line: Line number of the source file where this method is called.
    func log(_ logLevel: LogLevel = .info, message: String, function: String = #function, file: String = #file, line: Int = #line) {
        if self.logLevel.rawValue >= logLevel.rawValue {
            NSLog("[\(logLevel.toString())] \(function):\(file):\(line): \(message)")
        }
    }

}
