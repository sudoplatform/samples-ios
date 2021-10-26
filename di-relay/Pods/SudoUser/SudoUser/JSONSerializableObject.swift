//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// The default implementation of SerializableObject protocol that
/// serializes the object's content into JSON.
public class JSONSerializableObject {

    /// Support change types for the object's properties.
    ///
    /// - Replace: Replace the property's value/s.
    /// - Delete: Delete the property.
    public enum ChangeType {
        case replace
        case delete
    }

    /// List of contants used by this class.
    private struct Constants {

        static let Version = 1

    }

    private(set) public var version = Constants.Version

    fileprivate(set) public var properties: [String: Any] = [:]

    /// List of changes that occurred to this object's properties since it's construction.
    private(set) public var changes: [String: (ChangeType, Any)] = [:]

    /// Intializes a new `JSONSerializableObject` instance.
    ///
    /// - Returns: A new initialized `SerializableObjectImpl` instance.
    public init() { }

    /// Intializes a new `JSONSerializableObject` instance but as a copy from another instance.
    ///
    /// - Parameter other: `JSONSerializableObject` to copy.
    ///
    /// - Returns: A new initialized `JSONSerializableObject` instance.
    public init(other: JSONSerializableObject) {
        // Properties is a struct so copied by value.
        self.properties = other.properties
    }

    /// Intializes a new `JSONSerializableObject` instance from the serialized object data.
    ///
    /// - Parameter data: Serialized object data.
    ///
    /// - Returns: A new initialized `JSONSerializableObject` instance.
    public convenience init?(data: Data) {
        self.init()
        do {
            try loadFromData(data)
        } catch {
            return nil
        }
    }

    /// Intializes a new `SerializableObjectImpl` instance from a dictionary
    /// encapsulating the object's properties.
    ///
    /// - Parameter properties: Dictionary of object's properties.
    ///
    /// - Return: A new initialized `SerializableObjectImpl` instance.
    public convenience init?(properties: [String: Any]) {
        self.init()
        guard JSONSerialization.isValidJSONObject(properties) else {
            return nil
        }
        self.properties = properties
    }

    /// Sets a String property.
    ///
    /// - Parameters:
    ///   - name: Property name.
    ///   - value: Property value.
    public func setProperty(_ name: String, value: String?) {
        guard let value = value else { removeProperty(name); return }
        self.properties[name] = value
        self.changes[name] = (.replace, value)
    }

    /// Sets an Integer property.
    ///
    /// - Parameters:
    ///   - name: Property name.
    ///   - value: Property value.
    public func setProperty(_ name: String, value: Int?) {
        guard let value = value else { removeProperty(name); return }
        self.properties[name] = value
        self.changes[name] = (.replace, value)
    }

    /// Sets a Double property.
    ///
    /// - Parameters:
    ///   - name: Property name.
    ///   - value: Property value.
    public func setProperty(_ name: String, value: Double?) {
        guard let value = value else { removeProperty(name); return }
        self.properties[name] = value
        self.changes[name] = (.replace, value)
    }

    /// Sets a Boolean property.
    ///
    /// - Parameters:
    ///   - name: Property name.
    ///   - value: Property value.
    public func setProperty(_ name: String, value: Bool) {
        self.properties[name] = value
        self.changes[name] = (.replace, value as Any)
    }

    /// Sets a Date property.
    ///
    /// - Parameters:
    ///   - name: Property name.
    ///   - value: Property value.
    public func setProperty(_ name: String, value: Date?) {
        guard let value = value else { removeProperty(name); return }
        self.properties[name] = value.toMillisecondsSinceEpoch()
        self.changes[name] = (.replace, value)
    }

    /// Sets a `SerializableObject` property.
    ///
    /// - Parameters:
    ///   - name: Property name.
    ///   - value: Property value.
    public func setProperty(_ name: String, value: JSONSerializableObject?) {
        guard let value = value else { removeProperty(name); return }
        self.properties[name] = value.properties
    }

    /// Sets a String array property.
    ///
    /// - Parameters:
    ///   - name: Property name.
    ///   - value: Property value.
    public func setProperty(_ name: String, value: [String]?) {
        guard let value = value else { removeProperty(name); return }
        self.properties[name] = value
        self.changes[name] = (.replace, value)
    }

    /// Sets an Integer array property.
    ///
    /// - Parameters:
    ///   - name: Property name.
    ///   - value: Property value.
    public func setProperty(_ name: String, value: [Int]?) {
        guard let value = value else { removeProperty(name); return }
        self.properties[name] = value
        self.changes[name] = (.replace, value)
    }

    /// Sets a Double array property.
    ///
    /// - Parameters:
    ///   - name: Property name.
    ///   - value: Property value.
    public func setProperty(_ name: String, value: [Double]?) {
        guard let value = value else { removeProperty(name); return }
        self.properties[name] = value
        self.changes[name] = (.replace, value)
    }

    /// Sets a Boolean array property.
    ///
    /// - Parameters:
    ///   - name: Property name.
    ///   - value: Property value.
    public func setProperty(_ name: String, value: [Bool]?) {
        guard let value = value else { removeProperty(name); return }
        self.properties[name] = value
        self.changes[name] = (.replace, value)
    }

    /// Sets a Date array property.
    ///
    /// - Parameters:
    ///   - name: Property name.
    ///   - value: Property value.
    public func setProperty(_ name: String, value: [Date]?) {
        guard let value = value else { removeProperty(name); return }

        var array: [NSNumber] = []

        for date in value {
            array.append(date.toMillisecondsSinceEpoch())
        }

        self.properties[name] = array
        self.changes[name] = (.replace, array)
    }

    /// Sets a `SerializableObject` array property.
    ///
    /// - Parameters:
    ///   - name: Property name.
    ///   - value: Property value.
    public func setProperty(_ name: String, value: [JSONSerializableObject]?) {
        guard let value = value else { removeProperty(name); return }

        var array: [[String: Any]] = []

        for element in value {
            array.append(element.properties)
        }

        self.properties[name] = array
    }

    /// Remmoves a property.
    ///
    /// - Parameter name: Property name.
    public func removeProperty(_ name: String) {
        if let value = self.properties.removeValue(forKey: name) {
            self.changes[name] = (.delete, value)
        }
    }

    /// Returns the value of the specified String property.
    ///
    /// - Parameter name: Property name.
    /// - Returns: Specified property's value or nil if the property does not exist.
    public func getPropertyAsString(_ name: String) -> String? {
        guard let value = self.properties[name] as? String else {
            return nil
        }

        return value
    }

    /// Returns the value of the specified Integer property.
    ///
    /// - Parameter name: Property name.
    /// - Returns: Specified property's value or nil if the property does not exist.
    public func getPropertyAsInt(_ name: String) -> Int? {
        guard let value = self.properties[name] as? Int else {
            return nil
        }

        return value
    }

    /// Returns the value of the specified Double property.
    ///
    /// - Parameter name: Property name.
    ///
    /// - Returns: Specified property's value or nil if the property does not exist.
    public func getPropertyAsDouble(_ name: String) -> Double? {
        guard let value = self.properties[name] as? Double else {
            return nil
        }

        return value
    }

    /// Returns the value of the specified Boolean property.
    ///
    /// - Parameter name: Property name.
    ///
    /// - Returns: Specified property's value or nil if the property does not exist.
    public func getPropertyAsBool(_ name: String) -> Bool {
        guard let value = self.properties[name] as? Bool else {
            return false
        }

        return value
    }

    /// Returns the value of the specified Date property.
    ///
    /// - Parameter name: Property name.
    ///
    /// - Returns: Specified property's value or nil if the property does not exists.
    public func getPropertyAsDate(_ name: String) -> Date? {
        guard let value = self.properties[name] as? NSNumber else {
            return nil
        }

        return value.toDateFromMillisecondsSinceEpoch() as Date
    }

    /// Returns the value of the specified `SerializableObject` property.
    ///
    /// - Parameter name: Property name.
    ///
    /// - Returns: Specified property's value or nil if the property does not exists.
    public func getPropertyAsSerializableObject(_ name: String) -> JSONSerializableObject? {
        guard let value = self.properties[name] as? [String: Any] else {
            return nil
        }

        return JSONSerializableObject(properties: value)
    }

    /// Returns the value of the specified string array property.
    ///
    /// - Parameter name: Property name.
    ///
    /// - Returns: Specified property's value or nil if the property does not exists.
    public func getPropertyAsStringArray(_ name: String) -> [String]? {
        guard let value = self.properties[name] as? [String] else {
            return nil
        }

        return value
    }

    /// Returns the value of the specified boolean array property.
    ///
    /// - Parameter name: Property name.
    ///
    /// - Returns: Specified property's value or nil if the property does not exists.
    public func getPropertyAsBoolArray(_ name: String) -> [Bool]? {
        guard let value = self.properties[name] as? [Bool] else {
            return nil
        }

        return value
    }

    /// Returns the value of the specified integer array property.
    ///
    /// - Parameter name: Property name.
    ///
    /// - Returns: Specified property's value or nil if the property does not exists.
    public func getPropertyAsIntArray(_ name: String) -> [Int]? {
        guard let value = self.properties[name] as? [Int] else {
            return nil
        }

        return value
    }

    /// Returns the value of the specified double array property.
    ///
    /// - Parameter name: Property name.
    /// - Returns: Specified property's value or nil if the property does not exists.
    public func getPropertyAsDoubleArray(_ name: String) -> [Double]? {
        guard let value = self.properties[name] as? [Double] else {
            return nil
        }

        return value
    }

    /// Returns the value of the specified date array property.
    ///
    /// - Parameter name: Property name.
    /// - Returns: Specified property's value or nil if the property does not exists.
    public func getPropertyAsDateArray(_ name: String) -> [Date]? {
        guard let value = self.properties[name] as? [NSNumber] else {
            return nil
        }

        return value.map({ ($0.toDateFromMillisecondsSinceEpoch() as Date) })
    }

    /// Returns the value of the specified serialiable object array property.
    ///
    /// - Parameter name: Property name.
    ///
    /// - Returns: Specified property's value or nil if the property does not exists.
    public func getPropertyAsSerializableObjectArray(_ name: String) -> [JSONSerializableObject]? {
        guard let value = self.properties[name] as? [[String: Any]] else {
            return nil
        }

        return value.map({ JSONSerializableObject(properties: $0) }).compactMap({ $0 })
    }

    /// Clears the change list associated with this object.
    public func clearChanges() {
        self.changes.removeAll()
    }

}

extension JSONSerializableObject: SerializableObject {

    public func toData() throws -> Data {
        guard let data = self.properties.toJSONData() else {
            throw SerializableObjectError.serializationError
        }

        return data as Data
    }

    public func loadFromData(_ data: Data) throws {
        guard let object = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) else {
            throw SerializableObjectError.serializationError
        }

        if let dictionary = object as? [String: Any] {
            self.properties = dictionary
        }
    }

}

extension JSONSerializableObject: Equatable {

    public static func == (lhs: JSONSerializableObject, rhs: JSONSerializableObject) -> Bool {
        // Apparently in Swift 3.0 we can just use `==` operator on [String: Any] but
        // in meantime we use NSDictionary to keep things simple.
        return NSDictionary(dictionary: lhs.properties).isEqual(to: rhs.properties)
    }

}

extension JSONSerializableObject: CustomStringConvertible {

    public var description: String {
        return self.properties.toJSONPrettyString() ?? self.description
    }

}
