//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoKeyManager

/// List of possible errors thrown by `LocalAuthenticationProvider`.
///
/// - invalidKey: Invalid signing key was provided.
public enum LocalAuthenticationProviderError: Error, Hashable {
    case invalidKey
}

/// Authentication info consisting of a JWT signed using the locally stored private key..
public class LocalAuthenticationInfo: AuthenticationInfo {

    private let jwt: String
    private let username: String

    /// Initializes `LocalAuthenticationInfo` with a signed JWT.
    ///
    /// - Parameter jwt: signed JWT.
    public init(jwt: String, username: String) {
        self.jwt = jwt
        self.username = username
    }

    public static var type: String = "FSSO"

    public func isValid() -> Bool {
        return true
    }

    public func toString() -> String {
        return self.jwt
    }

    public func getUsername() -> String {
        return self.username
    }

}

/// Authentication provider for generating authentication info using a locally stored private key.
public class LocalAuthenticationProvider: AuthenticationProvider {

    public struct Constants {
        public static let audience = "identity-service"
    }

    private let name: String

    private let keyId: String

    private let username: String

    private let keyManager: SudoKeyManager

    private let customAttributes: [String: Any]

    /// Initializes a local authentication provider with a RSA private key.
    ///
    /// - Parameters:
    ///   - name: Provider name. This name will be used as the issuer of the authentication info.
    ///   - key: PEM encoded RSA private key.
    ///   - keyId: Key ID.
    ///   - username: Username be associated with the issued authentication info.
    ///   - keyManager: `KeyManager` instance to use for signing authentication info.
    ///   - customAttributes: Additional attributes to add to the authentication information.
    public init(name: String, key: String, keyId: String, username: String, keyManager: SudoKeyManager, customAttributes: [String: Any] = [:]) throws {
        self.name = name
        self.keyId = keyId
        self.username = username
        self.keyManager = keyManager
        self.customAttributes = customAttributes

        var key = key
        key = key.replacingOccurrences(of: "\n", with: "")
        key = key.replacingOccurrences(of: "-----BEGIN RSA PRIVATE KEY-----", with: "")
        key = key.replacingOccurrences(of: "-----END RSA PRIVATE KEY-----", with: "")

        guard let keyData = Data(base64Encoded: key) else {
            throw LocalAuthenticationProviderError.invalidKey
        }

        try self.keyManager.deleteKeyPair(self.keyId)
        try self.keyManager.addPrivateKey(keyData, name: self.keyId)
    }

    public func getAuthenticationInfo(completion: @escaping(Swift.Result<AuthenticationInfo, Error>) -> Void) {
        do {
            let jwt = JWT(issuer: self.name,
                          audience: Constants.audience,
                          subject: self.username,
                id: UUID().uuidString)
            jwt.payload = self.customAttributes
            let encoded = try jwt.signAndEncode(keyManager: self.keyManager, keyId: self.keyId)
            completion(.success(LocalAuthenticationInfo(jwt: encoded, username: self.username)))
        } catch {
            completion(.failure(error))
        }
    }

    public func reset() {
        try? self.keyManager.deleteKeyPair(self.keyId)
    }

}
