//
//  KeyAttributeSet.swift
//  KeyManagerIOS
//
//  Created by Lachlan McCulloch on 10/6/19.
//  Copyright © 2019 Anonyome Labs, Inc. All rights reserved.
//

@available(*, deprecated, renamed: "KeyAttributeSet")
public typealias KeyAttributes = KeyAttributeSet

/// Struct representing a set of key attributes. Used for ensuring that there are no duplicate attributes with same name while providing Set semantics for comparing two key attribute sets where member equality is based on both attribute name and value.
public struct KeyAttributeSet: Equatable {

    // MARK: - Supplementary

    /// List of modifiable key attributes.
    static let MutableAttributes: [KeyAttributeName] = [.synchronizable, .exportable, .id]

    /// List of key attributes that can be used as search parameters.
    static let SearchAttributes: [KeyAttributeName] = [.id, .type, .synchronizable, .exportable]

    // MARK: - Properties

    /// Key attributes.
    public fileprivate(set) var attributes = Set<KeyAttribute>()

    // MARK: - Calculated Properties

    /// Key attributes count.
    public var count: Int {
        return self.attributes.count
    }

    // MARK: - Initializers

    /// Intializes a new empty `KeyAttributeSet` instance.
    public init() {}

    /// Intializes a new `KeyAttributeSet` instance with the specified set of attributes.
    public init(attributes: Set<KeyAttribute>) {
        self.attributes = attributes
    }

    // MARK: - Methods

    /// Adds a new key attribute. Existing attribute with the same name will be replaced.
    ///
    /// - Parameters:
    ///   - name: Name of the attribute to be added.
    ///   - value: Value of the attribute to be added.
    public mutating func addAttribute(_ name: KeyAttributeName, value: KeyAttributeValue) {
        self.removeAttribute(name)
        self.attributes.insert(KeyAttribute(name: name, value: value))
    }

    /// Returns the key attribute with the specified name.
    ///
    /// - Parameter name: Name of attribute to be accessed.
    /// - Returns: The attribute assocaited with the input `name`. Nil will be returned if the attribute cannot be found in the set.
    public func getAttribute(_ name: KeyAttributeName) -> KeyAttribute? {
        return self.attributes.filter { $0.name == name }.first
    }

    /// Removes the key attribute with the specified name.
    ///
    /// - Parameter name: Name of attribute to be removed.
    public mutating func removeAttribute(_ name: KeyAttributeName) {
        self.attributes = Set(self.attributes.filter { $0.name != name })
    }

    /// Determines if this set of key attributes is a subset of another set of key attributes.
    ///
    /// - Parameter attributes: Set to use to determine if it is a subset of the current set.
    /// - Returns: true if the input `attributes` is a subset of this set.
    public func isSubsetOf(_ attributes: KeyAttributeSet) -> Bool {
        return self.attributes.isSubset(of: attributes.attributes)
    }

    /// Returns a new set of key attributes with the specified key attributes removed from this set of key attributes.
    ///
    /// - Parameter attributes: A set of attributes to subtract from the current set.
    /// - Returns: A new set of key attributes with the specified key attributes removed from this set of key attributes.
    @available(*, renamed: "subtracting(_:)")
    public func subtract(_ attributes: KeyAttributeSet) -> KeyAttributeSet {
        return self.subtracting(attributes)
    }

    public func subtracting(_ attributes: KeyAttributeSet) -> KeyAttributeSet {
        return KeyAttributeSet(attributes: self.attributes.subtracting(attributes.attributes))
    }


    ///  Determines whether or not all attributes contained in this `KeyAttributeSet` can be used for searching.
    ///
    /// - Returns: True if all attributes contained in this `KeyAttributeSet` are searchable.
    public func isSearchable() -> Bool {
        var isSearchable = true

        // TODO: Use pipeline
        for attribute in self.attributes {
            if !KeyAttributeSet.SearchAttributes.contains(attribute.name) {
                isSearchable = false
            }
        }

        return isSearchable
    }

    /**
     Determines whether or not all attributes contained in this `KeyAttributeSet` can be
     updated.

     - Returns: `true` all attributes contained in this `KeyAttributeSet` are mutable.
     */
    public func isMutable() -> Bool {
        var isMutable = true

        for attribute in self.attributes {
            if !KeyAttributeSet.MutableAttributes.contains(attribute.name) {
                isMutable = false
            }
        }

        return isMutable
    }

    // MARK: Conformance: Equatable

    public static func == (lhs: KeyAttributeSet, rhs: KeyAttributeSet) -> Bool {
        return lhs.attributes == rhs.attributes
    }

}
