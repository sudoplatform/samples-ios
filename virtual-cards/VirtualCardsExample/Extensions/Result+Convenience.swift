//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Result {

    // MARK: - Convenience

    /// If the result is an error, its `Error` instance will be returned. If success, `nil` will be returned instead.
    var error: Error? {
        guard case let .failure(error) = self else {
            return nil
        }
        return error
    }
}
