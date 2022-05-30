//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Protocol for repository implementations to implement to derive behaviour for resetting itself.
protocol Resetable {
    /// Reset the inner objects.
    func reset()
}
