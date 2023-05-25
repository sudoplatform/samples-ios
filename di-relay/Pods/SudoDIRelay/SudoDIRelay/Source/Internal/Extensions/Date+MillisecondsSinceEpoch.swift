//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Date {

    /// Returns a `Date` initialized relative to 00:00:00 UTC on 1 January 1970 by a given number of milliseconds.
    init(millisecondsSince1970: Double) {
        let seconds: TimeInterval = (millisecondsSince1970 / 1000)
        self = Date(timeIntervalSince1970: seconds)
    }

    /// The interval between the date value and 00:00:00 UTC on 1 January 1970, represented in milliseconds.
    var millisecondsSince1970: Double {
        return timeIntervalSince1970 * 1000
    }
}
