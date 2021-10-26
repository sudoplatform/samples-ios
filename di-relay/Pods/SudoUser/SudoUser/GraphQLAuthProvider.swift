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
/// - fatalError: Indicates that a fatal error occurred. This could be due to
///     coding error, out-of-memory condition or other conditions that is
///     beyond control of `GraphQLAuthProvider` implementation.
public enum GraphQLAuthProviderError: Error {
    case notSignedIn
    case fatalError(description: String)
}

/// `SudoUserClient` based authentication provider implementation to be used by
/// AWS AppSync client.
public class GraphQLAuthProvider: AWSCognitoUserPoolsAuthProviderAsync {

    unowned let client: SudoUserClient

    /// Initializes `GraphQLAuthProvider` with `SudoUserClient`.
    ///
    /// - Parameter client: 'SudoUserClient' instance for issueing authentication tokens.
    public init(client: SudoUserClient) {
        self.client = client
    }

    public func getLatestAuthToken(_ callback: @escaping (String?, Error?) -> Void) {
        do {
            guard let idToken = try self.client.getIdToken(),
                let refreshToken = try self.client.getRefreshToken(),
                let expiry = try self.client.getTokenExpiry() else {
                // If tokens are missing then it's likely due to the client not being signed in.
                return callback(nil, GraphQLAuthProviderError.notSignedIn)
            }

            if expiry > Date(timeIntervalSinceNow: 600) {
                callback(idToken, nil)
            } else {
                // Refresh the token if it has expired or will expire in 10 mins.
                try self.client.refreshTokens(refreshToken: refreshToken) { (result) in
                    switch result {
                    case let .success(tokens):
                        callback(tokens.idToken, nil)
                    case let .failure(cause):
                        callback(nil, cause)
                    }
                }
            }
        } catch let error {
            callback(nil, error)
        }
    }

}
