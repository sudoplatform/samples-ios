//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Date {

    fileprivate var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        dateFormatter.dateFormat = "MM/dd/YYYY"
        return dateFormatter
    }

    /// Returns a format that is presentable for a date stamp in the `CardDetailViewController`.
    var transactionPresentable: String {
        return dateFormatter.string(from: self)
    }
}
