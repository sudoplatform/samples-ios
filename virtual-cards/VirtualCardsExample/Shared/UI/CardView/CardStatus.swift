//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit

/// Enumeration of supported status states a `VirtualCard` can exist in
enum CardStatus: String, CaseIterable, Equatable {
    /// The card is valid and being used by a sudo
    case issued
    /// The card is open, but suspended from making transactions.
    case suspended
    /// The card is closed and can no longer be used for transactions
    case closed
    /// The card status is unsupported or otherwise unresolvable
    case failed
    /// The card was unable to be provisioned
    case unknown

    var tagImage: UIImage? {
        switch self {
        case .closed:
            return UIImage(named: "cardTagClosed", in: Bundle.main, compatibleWith: nil)
        case .suspended:
            return UIImage(named: "cardTagSuspended", in: Bundle.main, compatibleWith: nil)
        default:
            return nil
        }
    }
}
