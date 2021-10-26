//
//  Dictionary.swift
//  KeyManager
//
//  Created by cchoi on 17/08/2016.
//  Copyright © 2015 Anonyome Labs, Inc. All rights reserved.
//

import Foundation

/**
    Extention for JSON compatible dictionaries. Only dictionaries of type
    [NSObject: AnyObject] can be converted to JSON.
 */
extension Dictionary where Value: AnyObject {
    
    /**
        Intializes a new `Dictionary` instance from an array
        of name/value pairs.
     
        - Returns: A new initialized `Dictionary` instance.
     */
    init(_ pairs: [Element]) {
        self.init()
        for (k, v) in pairs {
            self[k] = v
        }
    }
    
    /**
        Converts Dictionary to JSON data.
     
        - Returns: JSON ata.
     */
    func toJSONData() -> Data? {
        guard JSONSerialization.isValidJSONObject(self),
            let data = try? JSONSerialization.data(withJSONObject: self, options: []) else {
            return nil
        }
        
        return data
    }
    
    /**
        Converts Dictionary to pretty formatted JSON data.
     
        - Returns: JSON ata.
     */
    func toJSONPrettyString() -> String? {
        guard JSONSerialization.isValidJSONObject(self),
            let data = try? JSONSerialization.data(withJSONObject: self, options: .prettyPrinted) else {
            return nil
        }
        
        return String(data: data, encoding: String.Encoding.utf8)
    }
    
    /**
        Adds the content of another dictionary to this dictionary.
     
        - Parameters:
            - dictionary: Dictionary to add.
     */
    mutating func addDictionary(_ dictionary: Dictionary) {
        dictionary.forEach { updateValue($1, forKey: $0) }
    }
    
}
