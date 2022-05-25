//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoVirtualCards

extension TransactionDeclineReason: CustomStringConvertible {
    // MARK: - Conformance: CustomStringConvertible

    public var description: String {
        switch self {
        case let .unknown(declineReason):
            return declineReason
        case .insufficientFunds:
            return "Insufficient Funds"
        case .suspicious:
            return "Suspicious"
        case .cardStopped:
            return "Card Closed"
        case .cardExpired:
            return "Card Expired"
        case .merchantBlocked:
            return "Merchant Blocked"
        case .merchantCodeBlocked:
            return "Merchant Category Blocked"
        case .merchantCountryBlocked:
            return "Merchant Country Blocked"
        case .avsCheckFailed:
            return "Address Check Failed"
        case .cscCheckFailed:
            return "Security Code Check Failed"
        case .expiryCheckFailed:
            return "Card Expiry Check Failed"
        case .processingError:
            return "Processing Error"
        case .declined:
            return "Declined"
        case .velocityExceeded:
            return "Velocity Exceeded"
        case .currencyBlocked:
            return "Currency Blocked"
        case .fundingError:
            return "Funding Error"
        }
    }
}
