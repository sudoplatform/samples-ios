//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSAppSync

/// List of possible errors thrown by `GraphQLAuthProvider`.
///
/// - notSignedIn: Indicates the client is not signed-in so cannot provide authentication token to
///     the authentication provider.
/// - notAuthorized: Indicates the client is not authorized to obtain a valid ID token. This could be
///     due to the refresh token being revoked or expired.
/// - refreshTokensOperationAlreadyInProgress: Indicates the client attempted to refresh the
///     tokens while there's already one in progress.
/// - fatalError: Indicates that a fatal error occurred. This could be due to
///     coding error, out-of-memory condition or other conditions that is
///     beyond control of `GraphQLAuthProvider` implementation.
public enum GraphQLAuthProviderError: Error {
    case notSignedIn
    case notAuthorized
    case refreshTokensOperationAlreadyInProgress
    case fatalError(description: String)
}

public extension GraphQLAuthProviderError {
    static func fromSudoUserClientError(error: Error) -> GraphQLAuthProviderError {
        switch error {
        case SudoUserClientError.notAuthorized:
            return GraphQLAuthProviderError.notAuthorized
        case SudoUserClientError.notSignedIn:
            return GraphQLAuthProviderError.notSignedIn
        case SudoUserClientError.refreshTokensOperationAlreadyInProgress:
            return GraphQLAuthProviderError.refreshTokensOperationAlreadyInProgress
        default:
            return GraphQLAuthProviderError.fatalError(description: "Unexpected error occurred: \(error)")
        }
    }
}

/// `SudoUserClient` based authentication provider implementation to be used by
/// AWS AppSync client.
public class GraphQLAuthProvider: AWSCognitoUserPoolsAuthProviderAsync {

    unowned let client: SudoUserClient
    let autoRefreshTokens: Bool

    /// Initializes `GraphQLAuthProvider` with `SudoUserClient`.
    ///
    /// - Parameters:
    ///     - client: 'SudoUserClient' instance for issueing authentication tokens.
    ///     - authRefreshTokens: if 'true' ID token  will be refreshed automatically as long as
    ///         the refresh token has not expired.
    public init(client: SudoUserClient, autoRefreshTokens: Bool = true) {
        self.client = client
        self.autoRefreshTokens = autoRefreshTokens
    }

    public func getLatestAuthToken(_ callback: @escaping (String?, Error?) -> Void) {
        do {
            guard let idToken = try self.client.getIdToken(),
                let refreshToken = try self.client.getRefreshToken(),
                let expiry = try self.client.getTokenExpiry() else {
                // If tokens are missing then it's likely due to the client not being signed in.
                return callback(nil, GraphQLAuthProviderError.notSignedIn)
            }

            if expiry > Date(timeIntervalSinceNow: 60) {
                callback(idToken, nil)
            } else if autoRefreshTokens {
                // Refresh the token if it has expired or will expire in 1 min.
                Task.detached(priority: .medium) {
                    do {
                        let tokens = try await self.client.refreshTokens(refreshToken: refreshToken)
                        callback(tokens.idToken, nil)
                    } catch {
                        callback(nil, GraphQLAuthProviderError.fromSudoUserClientError(error: error))
                    }
                }
            } else {
                callback(nil, GraphQLAuthProviderError.notAuthorized)
            }
        } catch let error {
            callback(nil, GraphQLAuthProviderError.fromSudoUserClientError(error: error))
        }
    }

}
