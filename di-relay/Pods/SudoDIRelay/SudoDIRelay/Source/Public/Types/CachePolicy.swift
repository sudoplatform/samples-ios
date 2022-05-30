//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Cache policy that determines how data is accessed when performing a query method from
/// the Relay Service.
///
/// This is a veneer around `SudoOperations.CachePolicy`.
public enum CachePolicy: Equatable {
    /// Use the device cached data.
    case cacheOnly
    /// Query and use the data on the server.
    case remoteOnly
}
