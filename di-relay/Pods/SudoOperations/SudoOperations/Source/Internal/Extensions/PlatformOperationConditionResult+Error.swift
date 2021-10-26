//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension PlatformOperationConditionResult {
    var error: Error? {
        if case let .failure(error) = self {
            return error
        } else {
            return nil
        }
    }
}
