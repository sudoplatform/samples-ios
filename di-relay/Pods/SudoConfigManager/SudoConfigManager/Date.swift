//
// Copyright © 2022 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Date {

    /// Instantiates a Date object using milliseconds since Epoch.
    ///
    /// - Parameter millisecondsSinceEpoch: milliseconds since Epoch.
    init(millisecondsSinceEpoch: Double) {
        self.init(timeIntervalSince1970: millisecondsSinceEpoch / 1000)
    }

    /// The milliseconds representation of this date since Epoch.
    var millisecondsSinceEpoch: Int {
        return Int(floor(self.timeIntervalSince1970 * 1000))
    }

}
