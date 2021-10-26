//
//  Logger.swift
//  KeyManager
//
//  Created by cchoi on 17/08/2016.
//  Copyright © 2015 Anonyome Labs, Inc. All rights reserved.
//

import Foundation

/**
    A custom logger for `KeyManager`.
 */
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

    /**
        Log level.
     */
    var logLevel: LogLevel = .info
    
    /**
        Logs the given message at a specific log level.
     
        - Parameters:
            - logLevel: log level.
            - message: log message.
     */
    func log(_ logLevel: LogLevel = .info, message: String, function: String = #function, file: String = #file, line: Int = #line) {
        if self.logLevel.rawValue >= logLevel.rawValue {
            NSLog("[\(logLevel.toString())] \(function):\(file):\(line): \(message)")
        }
    }

}
