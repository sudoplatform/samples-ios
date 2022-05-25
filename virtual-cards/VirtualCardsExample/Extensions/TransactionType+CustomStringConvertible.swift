//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoVirtualCards

extension TransactionType: CustomStringConvertible {

    // MARK: - Conformance: CustomStringConvertible

    public var description: String {
        switch self {
        case .pending:
            return "Pending"
        case .complete:
            return "Completed"
        case .refund:
            return "Refunded"
        case .decline:
            return "Declined"
        case let .unknown(type):
            return type
        }
    }
}
