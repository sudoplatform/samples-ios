//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension NSNumber {

    /// Converts NSNumber representing milliseconds since epoch to Date.
    ///
    /// - Returns: Date.
    func toDateFromMillisecondsSinceEpoch() -> Date {
        return Date(timeIntervalSince1970: self.doubleValue / 1000)
    }

}
