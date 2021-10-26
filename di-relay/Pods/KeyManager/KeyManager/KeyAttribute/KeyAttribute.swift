//
//  KeyAttribute.swift
//  KeyManagerIOS
//
//  Created by Lachlan McCulloch on 10/6/19.
//  Copyright © 2019 Anonyome Labs, Inc. All rights reserved.
//

/// Struct representing a key attribute.
public struct KeyAttribute: Hashable {

    /// Key attribute name.
    public var name: KeyAttributeName

    /// Key attribute value.
    public var value: KeyAttributeValue

    /// Intializes a new `KeyAttribute` instance with the specified name and value.
    ///
    /// - Parameters:
    ///   - name: Name of the Key Attribute.
    ///   - value: Value of the Key Attribute.
    public init(name: KeyAttributeName, value: KeyAttributeValue) {
        self.name = name
        self.value = value
    }
}
