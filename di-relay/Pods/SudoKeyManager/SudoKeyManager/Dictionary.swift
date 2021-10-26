//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Dictionary where Value: AnyObject {
    
    /// Intializes a new `Dictionary` instance from an array
    /// of name/value pairs.
    ///
    /// - Parameter pairs: Array of name/value pairs.
    init(_ pairs: [Element]) {
        self.init()
        for (k, v) in pairs {
            self[k] = v
        }
    }
    
    /// Converts Dictionary to JSON data.
    ///
    /// - Returns: JSON data.
    func toJSONData() -> Data? {
        guard JSONSerialization.isValidJSONObject(self),
            let data = try? JSONSerialization.data(withJSONObject: self, options: []) else {
            return nil
        }
        
        return data
    }
    
    /// Converts Dictionary to pretty formatted JSON string.
    ///
    /// - Returns: Pretty formatted JSON string.
    func toJSONPrettyString() -> String? {
        guard JSONSerialization.isValidJSONObject(self),
            let data = try? JSONSerialization.data(withJSONObject: self, options: .prettyPrinted) else {
            return nil
        }
        
        return String(data: data, encoding: String.Encoding.utf8)
    }
    
    /// Adds the content of another dictionary to this dictionary.
    ///
    /// - Parameter dictionary: Dictionary to add.
    mutating func addDictionary(_ dictionary: Dictionary) {
        dictionary.forEach { updateValue($1, forKey: $0) }
    }
    
}
