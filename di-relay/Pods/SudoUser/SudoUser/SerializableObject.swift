//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// List of possible errors thrown by `SerializableObject` implementation.
///
/// - serializationError: Indicates that the object serialization failed.
///     This could be due to the object containing properties that cannot
///     be serialized into a specific format or from attempting to load
///     the version of serialized object data that's incompatible with
///     the current version of the object's implementation.
/// - fatalError: Indicates that a fatal error occurred. This could be due to
///     coding error, out-of-memory condition or other conditions that is
///     beyond control of `SerializableObject` implementation.
public enum SerializableObjectError: Error {
    case serializationError
    case fatalError
}

/// Protocol encapsulating a set of methods and properties that are
/// needed to serialized and deserialize an object to and from
/// a byte array, e.g. Data.
public protocol SerializableObject {

    /// Object version.
    var version: Int { get }

    /// Dictionary containing the list of properties associated with
    /// this object.
    var properties: [String: Any] { get }

    /// Serializes this object to a byte array.
    ///
    /// - Returns: Serialized object data.
    ///
    /// - Throws:
    ///      `SerializableObjectError.serializationError`,
    ///      `SerializableObjectError.fatalError`

    func toData() throws -> Data

    /// Deserializes this object properties from a byte array.
    ///
    /// - Parameter data: Serialized object data.
    ///
    /// - Throws:
    ///     `SerializableObjectError.serializationError`,
    ///     `SerializableObjectError.fatalError`
    func loadFromData(_ data: Data) throws

}
