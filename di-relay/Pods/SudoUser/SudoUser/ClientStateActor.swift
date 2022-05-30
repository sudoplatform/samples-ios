//
// Copyright © 2022 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoKeyManager

enum ExclusiveOperation {
    case refreshTokens
    case signIn
    case register
    case none
}

/// Actor to manage the internal state information of `DefaultSudoUserClient`
actor ClientStateActor {

    private struct Constants {
        struct KeyName {
            static let userId = "userId"
            static let userKeyId = "userKeyId"
            static let idToken = "idToken"
            static let accessToken = "accessToken"
            static let refreshToken = "refreshToken"
            static let tokenExpiry = "tokenExpiry"
            static let refreshTokenExpiry = "refreshTokenExpiry"
            static let identityId = "identityId"
        }
    }

    private var pendingExclusiveOperation: ExclusiveOperation = .none

    private let keyManager: SudoKeyManager

    private let credentialsProvider: CredentialsProvider

    private let authUI: AuthUI?

    /// Intializes `ClientStateActor`.
    /// - Parameters:
    ///   - keyManager: `SudoKeyManager` instance used to store sensitive data.
    ///   - credentialsProvider: Credentials provider required to access AWS resources such as S3.
    ///   - authUI: `AuthUI` instance used for FSSO.
    init(keyManager: SudoKeyManager, credentialsProvider: CredentialsProvider, authUI: AuthUI?) {
        self.keyManager = keyManager
        self.credentialsProvider = credentialsProvider
        self.authUI = authUI
    }

    /// Update the client state to indicate that an exclusive operation has started.
    ///
    /// - Parameter operation: Operation to start.
    func beginExclusiveOperation(operation: ExclusiveOperation) throws {
        switch self.pendingExclusiveOperation {
        case .refreshTokens:
            throw SudoUserClientError.refreshTokensOperationAlreadyInProgress
        case .signIn:
            throw SudoUserClientError.signInOperationAlreadyInProgress
        case .register:
            throw SudoUserClientError.registerOperationAlreadyInProgress
        case .none:
            break
        }

        self.pendingExclusiveOperation = operation
    }

    /// Update the client state to indicate that an exclusive operation has ended.
    ///
    /// - Parameter operation: Operation to end.
    func endExclusiveOperation(operation: ExclusiveOperation) throws {
        guard operation != .none else {
            return
        }

        guard operation == self.pendingExclusiveOperation else {
            throw SudoUserClientError.fatalError(
                description: "Attempting to end an invalid exclusive operation: pending=\(String(describing: pendingExclusiveOperation)), ending=\(String(describing: operation)))"
            )
        }

        self.pendingExclusiveOperation = .none
    }

    /// Indicates whether or not this client is registered with Sudo Platform
    /// backend.
    ///
    /// - Returns: `true` if the client is registered.
    func isRegistered() async throws -> Bool {
        var username: String?
        username = try self.getUserName()
        return username != nil
    }

    /// Indicates whether or not the client is signed in. The client is considered signed in if it currently caches
    /// valid ID and access tokens.
    ///
    /// - Returns: `true` if the client is signed in.
    func isSignedIn() throws -> Bool {
        guard
            try self.getIdToken() != nil,
            try self.getAccessToken() != nil,
            let expiry = try self.getRefreshTokenExpiry() else {
            return false
        }

        // Considered signed in up to 1 hour before the expiry of refresh token.
        return expiry > Date(timeIntervalSinceNow: 60 * 60)
    }

    /// Sets the user name associated with this client. Mainly used for testing.
    /// - Parameter name: user name.
    func setUserName(name: String) async throws {
        guard let data = name.data(using: .utf8) else {
            throw SudoUserClientError.fatalError(description: "Cannot serialize user name.")
        }

        // Delete the user name first so there won't be a conflict when adding the new one.
        try self.keyManager.deletePassword(Constants.KeyName.userId)

        try self.keyManager.addPassword(data, name: Constants.KeyName.userId)
    }

    /// Stores authentication tokens in the underlying secure store.
    /// - Parameter tokens: Authentication tokens.
    func storeTokens(tokens: AuthenticationTokens) async throws {
        guard
            let idTokenData = tokens.idToken.data(using: .utf8),
            let accessTokenData = tokens.accessToken.data(using: .utf8),
            let refreshTokenData = tokens.refreshToken.data(using: .utf8),
            let tokenExpiryData = "\(Date().timeIntervalSince1970 + Double(tokens.lifetime))".data(using: .utf8) else {
            throw SudoUserClientError.fatalError(description: "Tokens cannot be serialized.")
        }

        // Cache the tokens and token lifetime in the keychain.
        try self.keyManager.deletePassword(Constants.KeyName.idToken)
        try self.keyManager.addPassword(idTokenData, name: Constants.KeyName.idToken)

        try self.keyManager.deletePassword(Constants.KeyName.accessToken)
        try self.keyManager.addPassword(accessTokenData, name: Constants.KeyName.accessToken)

        try self.keyManager.deletePassword(Constants.KeyName.refreshToken)
        try self.keyManager.addPassword(refreshTokenData, name: Constants.KeyName.refreshToken)

        try self.keyManager.deletePassword(Constants.KeyName.tokenExpiry)
        try self.keyManager.addPassword(tokenExpiryData, name: Constants.KeyName.tokenExpiry)
    }

    /// Stores refresh token lifetime in the underlying secure store.
    /// - Parameter refreshTokenLifetime: Refresh token lifetime in days.
    func storeRefreshTokenLifetime(refreshTokenLifetime: Int) async throws {
        // If a new refresh token lifetime is specified then stored that in the keychain as well.
        if let refreshTokenExpiryData = "\(Date().timeIntervalSince1970 + Double(refreshTokenLifetime * 24 * 60 * 60))".data(using: .utf8) {
            try self.keyManager.deletePassword(Constants.KeyName.refreshTokenExpiry)
            try self.keyManager.addPassword(refreshTokenExpiryData, name: Constants.KeyName.refreshTokenExpiry)
        }
    }

    /// Generates and stores reigistration data.
    ///
    /// - Returns: Public key of the signing key to register with the backend.
    func generateRegistrationData() async throws -> PublicKey {
        // Generate a public/private key pair for this identity.
        let keyId = try self.keyManager.generateKeyId()
        try self.keyManager.deleteKeyPair(keyId)
        try self.keyManager.generateKeyPair(keyId)

        guard let publicKeyData = try self.keyManager.getPublicKey(keyId) else {
            throw SudoUserClientError.fatalError(description: "Public key not found.")
        }

        // Make sure the key ID that we are trying to add don't exist.
        try self.keyManager.deletePassword(Constants.KeyName.userKeyId)

        // Store the key ID for user key in the keychain.
        guard let keyIdData = keyId.data(using: .utf8) else {
            throw SudoUserClientError.fatalError(description: "Cannot convert key ID to data.")
        }

        try self.keyManager.addPassword(keyIdData, name: Constants.KeyName.userKeyId)

        let publicKey = PublicKey(publicKey: publicKeyData, keyId: keyId)
        return publicKey
    }

    /// Clears cached authentication tokens.
    func clearAuthTokens() throws {
        try self.keyManager.deletePassword(Constants.KeyName.idToken)
        try self.keyManager.deletePassword(Constants.KeyName.accessToken)
        try self.keyManager.deletePassword(Constants.KeyName.refreshToken)
        try self.keyManager.deletePassword(Constants.KeyName.tokenExpiry)
        self.credentialsProvider.clearCredentials()
        self.authUI?.reset()
    }

    /// Removes all keys associated with this client and invalidates any
    /// cached authentication credentials.
    func reset() async throws {
        try self.keyManager.removeAllKeys()
        self.credentialsProvider.reset()
    }

    private func getUserName() throws -> String? {
        guard let data = try self.keyManager.getPassword(Constants.KeyName.userId),
            let username = String(data: data, encoding: .utf8) else {
            return nil
        }

        return username
    }

    private func getIdToken() throws -> String? {
        guard let data = try self.keyManager.getPassword(Constants.KeyName.idToken),
            let idToken = String(data: data, encoding: .utf8) else {
                return nil
        }

        return idToken
    }

    private func getAccessToken() throws -> String? {
        guard let data = try self.keyManager.getPassword(Constants.KeyName.accessToken),
            let accessToken = String(data: data, encoding: .utf8) else {
                return nil
        }

        return accessToken
    }

    private func getTokenExpiry() throws -> Date? {
        guard let data = try self.keyManager.getPassword(Constants.KeyName.tokenExpiry),
            let string = String(data: data, encoding: .utf8),
            let tokenExpiry = Double(string) else {
                return nil
        }

        return Date(timeIntervalSince1970: tokenExpiry)
    }

    private func getRefreshToken() throws -> String? {
        guard let data = try self.keyManager.getPassword(Constants.KeyName.refreshToken),
            let refreshToken = String(data: data, encoding: .utf8) else {
                return nil
        }

        return refreshToken
    }

    private func getRefreshTokenExpiry() throws -> Date? {
        guard let data = try self.keyManager.getPassword(Constants.KeyName.refreshTokenExpiry),
            let string = String(data: data, encoding: .utf8),
            let refreshTokenExpiry = Double(string) else {
                return nil
        }

        return Date(timeIntervalSince1970: refreshTokenExpiry)
    }

}
