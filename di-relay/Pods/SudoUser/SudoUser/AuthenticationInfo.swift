//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoKeyManager

/// List of possible errors thrown by `AuthenticationInfo` implementation.
/// - fatalError: Indicates that a fatal error occurred. This could be due to
///     coding error, out-of-memory condition or other conditions that is
///     beyond control of `AuthenticationInfo` implementation.
public enum AuthenticationInfoError: Error {
    case fatalError(description: String)
}

/// Credential information.
///
/// - ownerId: GUID of the owning resource.
/// - ownerType: Type of the owning resource.
/// - keyName: Name of the key associated with the credential.
public struct CredentialInfo {
    var ownerId: String
    var ownerType: String
    var keyName: String
}

/// Protocol encapsulating properties and methods related to credentials used
/// to authenticate to the backend.
public protocol AuthenticationInfo {

    /// Authentication type.
    static var type: String { get }

    /// Indicates whether or not the authentication information is valid, i.e. well-formed
    /// and has not expired.
    ///
    /// - Returns: `true` if the authentication information is valid.
    func isValid() -> Bool

    /// Returns the authentication information serialized to a String.
    ///
    /// - Returns: String representation of the authentication information.
    func toString() -> String

    /// Returns the username associated with this authentication information.
    /// - Returns: Username.
    func getUsername() -> String

}
