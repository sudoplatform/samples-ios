//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Enumeration of supported logging levels
public enum LogLevel: Int, CaseIterable, Comparable, CustomStringConvertible {
    case verbose = 0
    case debug
    case info
    case warning
    case error
    case none

    // MARK: - Conformance: CustomStringConvertible

    public var description: String {
        switch self {
        case .verbose: return "Verbose"
        case .debug: return "Debug"
        case .info: return "Info"
        case .warning: return "Warning"
        case .error: return "Error"
        case .none: return "None"
        }
    }

    // MARK: - Conformance: Comparable

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

    // MARK: - Deprecated

    @available(
        iOS,
        deprecated: 0.1.0,
        message: "`allLevels` will be removed in 1.0 release in favour of the `CaseIterable` protocol. Please use `.allCases` instead"
    )
    public static let allLevels: [LogLevel] = [.verbose, .debug, .info, .warning, .error, .none]

}
