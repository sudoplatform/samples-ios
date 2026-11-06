//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol FileReadable: Sendable {
    func path(forResource name: String?, ofType ext: String?) -> String?

    func contentsOfFile(forPath path: String) throws -> String
}

struct DefaultFileReadable: FileReadable {

    // MARK: - Methods

    func path(forResource name: String?, ofType ext: String?) -> String? {
        Bundle.main.path(forResource: name, ofType: ext)
    }

    func contentsOfFile(forPath path: String) throws -> String {
        try String(contentsOfFile: path, encoding: .utf8)
    }
}
