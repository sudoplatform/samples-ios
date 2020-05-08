//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension String {

    func inserting(separator: String, every n: Int) -> String {
        var result = ""
        self.enumerated().forEach { i, character in
            if i != 0, i != self.count, i % n == 0 {
                result += separator
            }
            result += String(character)
        }
        return result
    }
}
