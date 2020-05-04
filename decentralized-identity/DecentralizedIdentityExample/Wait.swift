//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum WaitError: Error, LocalizedError {
    case timeout

    var errorDescription: String? {
        switch self {
        case .timeout: return "The operation timed out."
        }
    }
}

extension String {
    var filename: String {
        return components(separatedBy: "?")
            .first.flatMap {
                $0.components(separatedBy: "/").last
            } ?? self
    }
}

fileprivate let DEFAULT_TIMEOUT: TimeInterval = 20

func _wait<T, E: Error>(file: String = #file,
              function: String = #function,
              line: Int = #line,
              timeoutAfter: TimeInterval? = DEFAULT_TIMEOUT,
              for closure: @escaping (@escaping (Result<T, E>) -> Void) throws -> Void) throws -> T {
    do {
        let group = DispatchGroup()

        var value: Result<T, E>?
        group.enter()
        try closure { t in
            value = t
            group.leave()
        }

        if let timeout = timeoutAfter {
            _ = group.wait(timeout: .now() + timeout)
        }
        else {
            group.wait()
        }

        if let v = value { return try v.get() }
        throw WaitError.timeout
    }
    catch {
        #if DEBUG
        print("--------- THROWING ERROR -----------")
        print("TRACE: \(function) \(file.filename):\(line)")
        print("ERROR: \((error as NSError).domain).\(error as Any)")
        print("------------------------------------")
        #endif
        throw error
    }
}

func wait<T>(file: String = #file,
             function: String = #function,
             line: Int = #line,
             timeoutAfter: TimeInterval? = DEFAULT_TIMEOUT,
             for closure: @escaping (@escaping (Result<T, Error>) -> Void) throws -> Void) throws -> T {
    try _wait(file: file, function: function, line: line, timeoutAfter: timeoutAfter) { fn in try closure(fn) }
}

func wait(file: String = #file,
          function: String = #function,
          line: Int = #line,
          timeoutAfter: TimeInterval? = DEFAULT_TIMEOUT,
          for closure: @escaping (@escaping (Result<Void, Error>) -> Void) throws -> Void) throws {
    try _wait(
        file: file,
        function: function,
        line: line,
        timeoutAfter: timeoutAfter) { (fn: @escaping (Result<Void, Error>) -> Void) in
            try closure(fn)
    }
}
