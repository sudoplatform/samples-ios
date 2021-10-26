//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCognitoIdentityProvider
import AWSS3

/// Result returned by API for retrieving identity ID. The API can fail with an
/// error or return the identity ID.
public enum GetIdentityIdResult {
    case success(identityId: String)
    case failure(cause: Error)
}

/// Interface common to credential providers. Mainly used for mocking AWS Cognito credentials provider.
public protocol CredentialsProvider: AnyObject {

    /// Retrieves and returns the identity ID associated with the temporary credential used for
    /// accessing certain backend resources, e.g. large blobs stored in AWS S3.
    ///
    /// - Parameter completion: The completion handler to invoke to pass the result.
    func getIdentityId(completion: @escaping(GetIdentityIdResult) -> Void) throws

    /// Returns the identity ID cached during sign in.
    ///
    /// - Returns: Identity ID.
    func getCachedIdentityId() -> String?

    /// Resets the internal state.
    func reset()

    /// Clear any cached credentials.
    func clearCredentials()

}

/// Credentials provider implementation that uses `AWSCognitoCredentialsProvider`.
class AWSCredentialsProvider: CredentialsProvider {

    /// Configuration parameter names.
    public struct Config {

        struct S3 {
            // Service client key for S3 client specific to Sudo platform.
            static let serviceClientKey = "com.sudoplatform.s3"
        }

    }

    /// `SudoUserClient` instance to use to obtain the authentication token.
    private var client: SudoUserClient

    /// Credentials provider required to access AWS resources such as S3.
    private var credentialsProvider: AWSCognitoCredentialsProvider

    /// AWS region type.
    private var regionType: AWSRegionType

    /// Initializes `AWSCredentialsProvider`.
    ///
    /// - Parameters:
    ///   - client: `SudoUserClient` instance to use to obtain the authentication token.
    ///   - regionType: AWS region type.
    ///   - userPoolId: AWS Cognito User Pool ID.
    ///   - identityPoolId: AWS Cognito Identity Pool ID.
    init(client: SudoUserClient, regionType: AWSRegionType, userPoolId: String, identityPoolId: String) {
        self.client = client
        self.regionType = regionType
        self.credentialsProvider = AWSCognitoCredentialsProvider(
            regionType: regionType,
            identityPoolId: identityPoolId,
            identityProviderManager: IdentityProviderManager(client: client,
                                                             region: AWSEndpoint.regionName(from: regionType),
                                                             poolId: userPoolId)
        )

        // Set up a S3 client that's configured to use `SudoUserClient` as the credentials provider to
        // exchange the ID token with AWS credentials. AWS credentail is required to access S3.
        guard let configuration = AWSServiceConfiguration(region: regionType, credentialsProvider: self.credentialsProvider) else {
            // This should never happen but we still need to unwrap the return value.
            return
        }

        AWSS3TransferUtility.register(with: configuration, forKey: Config.S3.serviceClientKey)
        AWSS3.register(with: configuration, forKey: Config.S3.serviceClientKey)
    }

    func getIdentityId(completion: @escaping (GetIdentityIdResult) -> Void) throws {
        self.credentialsProvider.getIdentityId().continueWith(block: { (task) -> AnyObject? in
            if let error = task.error {
                completion(.failure(cause: error))
            } else {
                if let identityId = task.result as String? {
                    completion(.success(identityId: identityId))
                } else {
                    completion(.failure(cause: SudoUserClientError.fatalError(description: "Identity ID missing from getIdentityId call.")))
                }
            }
            return task
        })
    }

    func getCachedIdentityId() -> String? {
        return self.credentialsProvider.identityId
    }

    func reset() {
        self.credentialsProvider.clearKeychain()
        self.credentialsProvider.invalidateCachedTemporaryCredentials()
    }

    func clearCredentials() {
        self.credentialsProvider.invalidateCachedTemporaryCredentials()
        self.credentialsProvider.clearCredentials()
    }

}
