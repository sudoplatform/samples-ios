//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Data {

    /// Converts Data to JSON serializable object, e.g. Dictionary or Array.
    ///
    /// - Returns: Dictionary or Array representing JSON data. nil if the data
    ///     does not represent JSON.
    func toJSONObject() -> Any? {
        return try? JSONSerialization.jsonObject(with: self, options: JSONSerialization.ReadingOptions.mutableContainers)
    }

}
