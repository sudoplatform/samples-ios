//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Array where Element: Operation {

    /// Returns the first element of the sequence that satisfies the given operation type.
    func first<T>(whereType opType: T.Type) -> T? where T: Operation {
        return first(where: { $0 is T }) as? T
    }
}
