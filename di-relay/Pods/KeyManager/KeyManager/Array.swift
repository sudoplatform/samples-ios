//
//  Array.swift
//  KeyManager
//
//  Created by cchoi on 17/08/2016.
//  Copyright © 2015 Anonyome Labs, Inc. All rights reserved.
//

import Foundation

extension Array {
    
    /**
        Converts Array to JSON data.
     
        - Returns: JSON data.
     */
    func toJSONData() -> Data? {
        guard JSONSerialization.isValidJSONObject(self),
            let data = try? JSONSerialization.data(withJSONObject: self, options: []) else {
            return nil
        }
        
        return data
    }
    
    /**
        Converts Array to pretty formatted JSON data.
     
        - Returns: JSON ata.
     */
    func toJSONPrettyString() -> String? {
        guard JSONSerialization.isValidJSONObject(self),
            let data = try? JSONSerialization.data(withJSONObject: self, options: .prettyPrinted) else {
            return nil
        }
        
        return String(data: data, encoding: String.Encoding.utf8)
    }
    
}
