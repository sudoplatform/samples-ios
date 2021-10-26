//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Date {

    /// Converts Date to NSNumber representing milliseconds since epoch.
    ///
    /// - Returns: Milliseconds since epoch.
    func toMillisecondsSinceEpoch() -> NSNumber {
        return floor(self.timeIntervalSince1970 * 1000) as NSNumber
    }

}
