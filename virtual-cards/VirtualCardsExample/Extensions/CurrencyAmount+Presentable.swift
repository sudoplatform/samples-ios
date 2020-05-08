//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SudoVirtualCards

extension CurrencyAmount {

    /// Converts a currency amount value to presentable string.
    ///
    /// **WARNING: This only works for USD**
    var presentableString: String {
        guard currency == "USD" else {
            fatalError("presentableString is only supported for currencies of USD")
        }
        let doubleVal = Double(amount) / 100.0
        return String(format: "$%.2f", doubleVal)
    }
}
