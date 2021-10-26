//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCore

/// `SudoUserClient` based authentication identity provider manager implementation to be used by
/// AWS clients.
public class IdentityProviderManager: NSObject, AWSIdentityProviderManager {

    public struct Error {

        static let domain = "com.sudoplatform.identityprovidermanager"

        enum Code: Int {
            case notSignedIn = -1
        }

    }

    private unowned let client: SudoUserClient

    private let region: String

    private let poolId: String

    /// Initializes `IdentityProviderManager` with the AWS region and user pool ID.
    ///
    /// - Parameters:
    ///   - client: 'SudoUserClient' instance for issueing authentication tokens.
    ///   - region: AWS region.
    ///   - poolId: AWS Cognito User Pool ID.
    public init(client: SudoUserClient, region: String, poolId: String) {
        self.client = client
        self.region = region
        self.poolId = poolId
    }

    public func logins() -> AWSTask<NSDictionary> {
        do {
            guard let idToken = try self.client.getIdToken(),
                let refreshToken = try self.client.getRefreshToken(),
                let expiry = try self.client.getTokenExpiry() else {
                    // If tokens are missing then it's likely due to the client not being signed in.
                    return AWSTask(error: NSError(domain: Error.domain, code: Error.Code.notSignedIn.rawValue, userInfo: nil))
            }

            if expiry > Date(timeIntervalSinceNow: 600) {
                let logins: NSDictionary = ["cognito-idp.\(self.region).amazonaws.com/\(self.poolId)": idToken]
                return AWSTask(result: logins)
            } else {
                let completion = AWSTaskCompletionSource<NSDictionary>()

                // Refresh the token if it has expired or will expire in 10 mins.
                try self.client.refreshTokens(refreshToken: refreshToken) { (result) in
                    switch result {
                    case let .success(tokens):
                        let logins: NSDictionary = ["cognito-idp.\(self.region).amazonaws.com/\(self.poolId)": tokens.idToken]
                        completion.set(result: logins)
                    case let .failure(cause):
                        completion.set(error: cause)
                    }
                }

                return completion.task
            }
        } catch let error {
            return AWSTask(error: error)
        }
    }

}
