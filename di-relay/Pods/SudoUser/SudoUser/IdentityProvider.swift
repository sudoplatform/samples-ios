//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Encapsulates interface requirements for an external identity provider to register and
/// authenticate an identity within Sudo platform ecosystem.
public protocol IdentityProvider: AnyObject {

    /// Registers a new identity (user) against the identity provider.
    ///
    /// - Parameters:
    ///   - uid: ID of the identity (user).
    ///   - parameters: The registration parameters.
    ///
    /// - Returns:User ID of the newly registered user.
    func register(
        uid: String,
        parameters: [String: String]
    ) async throws -> String

    /// Deregisters an identity (user) from the identity provider.
    ///
    /// - Parameters:
    ///   - uid: ID of the identity (user).
    ///   - accessToken: Access token used to authenticate and authorize the request.
    ///
    /// - Returns:User ID of the deregistered user.
    func deregister(
        uid: String,
        accessToken: String
    ) async throws -> String

    /// Sign into the identity provider.
    ///
    /// - Parameters:
    ///   - uid: ID of the identity (user) to sign in.
    ///   - parameters: Sign in parameters.
    ///
    /// - Returns:Authentication tokens.
    func signIn(
        uid: String,
        parameters: [String: Any]
    ) async throws -> AuthenticationTokens

    /// Refresh the access and ID tokens using the refresh token.
    ///
    /// - Parameters:
    ///   - refreshToken: Refresh token.
    ///
    /// - Returns:Authentication tokens.
    func refreshTokens(
        refreshToken: String
    ) async throws -> AuthenticationTokens

    /// Signs out the user from this device only.
    ///
    func signOut(refreshToken: String) async throws

    /// Signs out the user from all devices.
    ///
    /// - Parameters:
    ///   - accessToken: Access token used to authorize the request.
    func globalSignOut(
        accessToken: String
    ) async throws

}
