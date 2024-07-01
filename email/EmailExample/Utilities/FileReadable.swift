//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol FileReadable {
    func path(forResource name: String?, ofType ext: String?) -> String?

    func contentsOfFile(forPath path: String) throws -> String
}

class DefaultFileReadable: FileReadable {

    // MARK: - Properties

    var bundle = Bundle.main

    // MARK: - Methods

    func path(forResource name: String?, ofType ext: String?) -> String? {
        bundle.path(forResource: name, ofType: ext)
    }

    func contentsOfFile(forPath path: String) throws -> String {
        return try String(contentsOfFile: path)
    }
}
