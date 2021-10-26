//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Array {
    
    /// Converts Array to JSON data.
    ///
    /// - Returns: JSON data.
    func toJSONData() -> Data? {
        guard JSONSerialization.isValidJSONObject(self),
            let data = try? JSONSerialization.data(withJSONObject: self, options: []) else {
            return nil
        }
        
        return data
    }
    
    /// Converts Array to pretty formatted JSON string.
    /// 
    /// - Returns: Pretty formated JSON string.
    func toJSONPrettyString() -> String? {
        guard JSONSerialization.isValidJSONObject(self),
            let data = try? JSONSerialization.data(withJSONObject: self, options: .prettyPrinted) else {
            return nil
        }
        
        return String(data: data, encoding: String.Encoding.utf8)
    }
    
}
