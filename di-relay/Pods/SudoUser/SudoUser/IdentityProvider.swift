//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// List of possible errors thrown by `IdentityProvider`.
///
/// - invalidConfig: Indicates the configuration dictionary passed to initialize
///     the provider was not valid.
/// - invalidInput: Indicates bad input was provided to the API call.
/// - identityNotConfirmed: identity is not confirmed hence cannot sign in yet.
/// - notAuthorized: Indicates the authentication failed. Likely due to incorrect private key, the identity
///     being removed from the backend or significant clock skew between the client and the backend.
/// - notSignedIn: Indicates the API failed because the user is not signed-in.
/// - authTokenMissing: Thrown when required authentication tokens were not returned by identity service.
/// - serviceError: Indicates that an internal server error occurred. Retrying at a later time may succeed.
/// - fatalError: Indicates that a fatal error occurred. This could be due to
///     coding error, out-of-memory condition or other conditions that is
///     beyond control of `IdentityProvider` implementation.
public enum IdentityProviderError: Error {
    case invalidConfig
    case invalidInput
    case identityNotConfirmed
    case notAuthorized
    case notSignedIn
    case authTokenMissing
    case alreadyRegistered
    case serviceError
    case fatalError(description: String)
}

/// Encapsulates interface requirements for an external identity provider to register and
/// authenticate an identity within Sudo platform ecosystem.
public protocol IdentityProvider: AnyObject {

    /// Registers a new identity (user) against the identity provider.
    ///
    /// - Parameters:
    ///   - uid: ID of the identity (user).
    ///   - parameters: The registration parameters.
    ///   - completion: The completion handler to invoke to pass the uid of newly registered user or error.
    func register(uid: String,
                  parameters: [String: String],
                  completion: @escaping (Result<String, Error>) -> Void) throws

    /// Deregisters an identity (user) from the identity provider.
    ///
    /// - Parameters:
    ///   - uid: ID of the identity (user).
    ///   - accessToken: Access token used to authenticate and authorize the request.
    ///   - completion: The completion handler to invoke to pass the uid of deregistered user or error.
    func deregister(uid: String,
                    accessToken: String,
                    completion: @escaping (Result<String, Error>) -> Void) throws

    /// Sign into the identity provider.
    ///
    /// - Parameters:
    ///   - uid: ID of the identity (user) to sign in.
    ///   - parameters: Sign in parameters.
    ///   - completion: The completion handler to invoke to pass the authentication tokens or error.
    func signIn(uid: String,
                parameters: [String: Any],
                completion: @escaping (Result<AuthenticationTokens, Error>) -> Void) throws

    /// Refresh the access and ID tokens using the refresh token.
    ///
    /// - Parameters:
    ///   - refreshToken: Refresh token.
    ///   - completion: The completion handler to invoke to pass the authentication tokens or error.
    func refreshTokens(refreshToken: String, completion: @escaping (Result<AuthenticationTokens, Error>) -> Void) throws

    /// Signs out the user from all devices.
    ///
    /// - Parameters:
    ///   - accessToken: Access token used to authorize the request.
    ///   - completion: The completion handler to invoke to pass the sign out result.
    func globalSignOut(accessToken: String, completion: @escaping(Result<Void, Error>) -> Void) throws

}
