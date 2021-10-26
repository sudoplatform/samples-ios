//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSAppSync

/// Cache policy that determines how data is accessed when performing a `PlatformQueryOperation`.
public enum CachePolicy {
    /// Use the device cached data.
    case cacheOnly
    /// Query and use the data on the server.
    case remoteOnly
    /// Use the device cached data.
    @available(*, deprecated, renamed: "cacheOnly")
    case useCache
    /// Query and use the data on the server.
    @available(*, deprecated, renamed: "remoteOnly")
    case useOnline

    // MARK: - Internal

    /// Converts `Self` to the matching AWS `CachePolicy`.
    func toAWSCachePolicy() -> AWSAppSync.CachePolicy {
        switch self {
        case .useCache, .cacheOnly:
            return AWSAppSync.CachePolicy.returnCacheDataDontFetch
        case .useOnline, .remoteOnly:
            return AWSAppSync.CachePolicy.fetchIgnoringCacheData
        }
    }
}
