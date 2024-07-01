//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import EmailExample

class FileReadableMock: FileReadable {

    var pathCallCount = 0
    var pathProperties: (name: String?, ext: String?)?
    var pathResult: String? {
        get {
            return pathResults.first
        }
        set {
            guard let pathResult = newValue else {
                pathResults.removeAll()
                return
            }
            pathResults.append(pathResult)
        }
    }
    var pathResults: [String] = []
    func path(forResource name: String?, ofType ext: String?) -> String? {
        pathCallCount += 1
        pathProperties = (name, ext)
        guard !pathResults.isEmpty else {
            return nil
        }
        return pathResults.removeFirst()
    }

    func contentsOfFile(forPath path: String) throws -> String {
        return ""
    }
}
