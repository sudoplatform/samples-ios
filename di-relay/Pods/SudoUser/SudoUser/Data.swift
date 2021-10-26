//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Data {

    /// Converts Data to HEX string.
    ///
    /// - Returns: HEX string representation of Data.
    func toHexString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }

    /// Converts Data to JSON serializable object, e.g. Dictionary or Array.
    ///
    /// - Returns: Dictionary or Array representing JSON data. nil if the data
    ///     does not represent JSON.
    func toJSONObject() -> Any? {
        return try? JSONSerialization.jsonObject(with: self, options: JSONSerialization.ReadingOptions.mutableContainers)
    }

    /// Converts JSON data to a pretty formatted string.
    ///
    /// - Return: Pretty formatted JSON string.
    func toJSONString() -> String? {
        guard let jsonObject = self.toJSONObject(),
            let data = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
            let str = String(data: data, encoding: .utf8) else {
                return nil
        }

        return str
    }

}
