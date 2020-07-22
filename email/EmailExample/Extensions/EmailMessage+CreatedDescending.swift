//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SudoEmail

extension Array where Element == EmailMessage {

    /// Sort the array by the created property, in descending order.
    mutating func sortByCreatedDescending() {
        self = sortedByCreatedDescending()
    }

    /// Returns the elements of the array, sorted by `created`, in descending order.
    func sortedByCreatedDescending() -> [EmailMessage] {
        return sorted(by: { $0.created > $1.created })
    }
}
