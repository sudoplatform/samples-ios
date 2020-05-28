//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum TransactionDetailError: Error {
    case fundingSourceNotFound
    case sudoNotFound
    case failedToLoadData
}
