//
// Copyright © 2022 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// List of possible errors thrown by `SudoUserClient` implementation.
///
/// - alreadyRegistered: Thrown when attempting to register but the client is already registered.
/// - registerOperationAlreadyInProgress: Thrown when duplicate register calls are made.
/// - refreshTokensOperationAlreadyInProgress: Thrown when duplicate refreshTokens calls are made.
/// - signInOperationAlreadyInProgress: Thrown when duplicate signIn calls are made.
/// - notRegistered: Indicates the client has not been registered to the
///     Sudo platform backend.
/// - notSignedIn: Indicates the API being called requires the client to sign in.
/// - keyNotFound: Required key was not found.
/// - invalidConfig: Indicates the configuration dictionary passed to initialize the client was not valid.
/// - identityServiceConfigNotFound: Indicates the configuration related to Identity Service is not found.
///     This may indicate that Identity Service is not deployed into your runtime instance or the config
///     file that you are using is invalid..
/// - authTokenMissing: Thrown when required authentication tokens were not return by identity service.
/// - notAuthorized: Indicates the authentication failed. Likely due to incorrect private key, the identity
///     being removed from the backend or significant clock skew between the client and the backend.
/// - invalidInput: Indicates the input to the API was invalid.
/// - signInCanceled: Indicates the sign in has been canceled by the user.
/// - identityNotConfirmed: Indicates that the identity is not confirmed hence cannot sign in yet.
/// - serviceError: Indicates that an internal server error occurred. Retrying at a later time may succeed.
/// - graphQLError: Indicates that an unexpected GraphQL error was returned by identity service.
/// - fatalError: Indicates that a fatal error occurred. This could be due to
///     coding error, out-of-memory condition or other conditions that is
///     beyond control of `SudoUserClient` implementation.
public enum SudoUserClientError: Error {
    case alreadyRegistered
    case registerOperationAlreadyInProgress
    case refreshTokensOperationAlreadyInProgress
    case signInOperationAlreadyInProgress
    case invalidRegistrationChallengeType
    case keyNotFound(keyName: String)
    case notRegistered
    case notSignedIn
    case noAuthenticationProvider
    case invalidConfig
    case identityServiceConfigNotFound
    case authTokenMissing
    case notAuthorized
    case invalidInput
    case signInCanceled
    case identityNotConfirmed
    case serviceError
    case graphQLError(cause: [Error])
    case fatalError(description: String)
}
