//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoVirtualCards

extension FundingSource.Network {

    /// Returns as a string.
    var string: String {
        switch self {
        case .amex:
            return "AMEX"
        case .diners:
            return "Diners"
        case .discover:
            return "Discover"
        case .jcb:
            return "JCB"
        case .mastercard:
            return "MasterCard"
        case .unionpay:
            return "UnionPay"
        case .visa:
            return "VISA"
        default:
            return ""
        }
    }
}
