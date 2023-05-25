//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoKeyManager

/// Exported encryption key.
public struct EncryptionKey {

    /// Key ID.
    public let id: String

    /// Key namespace.
    public let namespace: String

    /// Base64 encoded key.
    public let key: String

    /// Cryptographic algorithm associated with the key.
    public let algorithm: String

    /// Key version.
    public let version: Int

    public init(id: String, namespace: String, algorithm: String, version: Int, key: String) {
        self.id = id
        self.namespace = namespace
        self.algorithm = algorithm
        self.version = version
        self.key = key
    }

}

/// List of supported symmetric key encryption algorithms.
public enum SymmetricKeyEncryptionAlgorithm: String {
    case aesCBCPKCS7Padding = "AES/CBC/PKCS7Padding"
}

/// Provides utility functions for cryptographic operations.
public protocol CryptoProvider: AnyObject {

    /// Encrypts the given data using the specified key and encryption algorithm.
    ///
    /// - Parameters:
    ///   - keyId: ID of the encryption key to use.
    ///   - algorithm: Encryption algorithm to use.
    ///   - data: Data to encrypt.
    ///
    /// - Returns: Encrypted data.
    func encrypt(keyId: String, algorithm: SymmetricKeyEncryptionAlgorithm, data: Data) throws -> Data

    /// Encrypts the given data using the specified key and encryption algorithm.
    ///
    /// - Parameters:
    ///   - keyId: ID of the encryption key to use.
    ///   - algorithm: Encryption algorithm to use.
    ///   - data: Data to decrypt.
    ///
    /// - Returns: Decrypted data.
    func decrypt(keyId: String, algorithm: SymmetricKeyEncryptionAlgorithm, data: Data) throws -> Data

    /// Generate an encryption key to use for encrypting Sudo claims. Any existing keys are not removed
    /// to be able to decrypt existing claims but new claims will be encrypted using the newly generated
    /// key.
    ///
    /// - Returns: Unique ID of the generated key.
    func generateEncryptionKey() throws -> String

    /// Get the current (most recently generated) symmetric key ID.
    ///
    /// - Returns: Symmetric Key ID.
    func getSymmetricKeyId() throws -> String?

    /// Import encyrption keys to use for encrypting and decrypting Sudo claims.
    ///
    /// - Parameters:
    ///     - keys: Keys to import.
    ///     - currentKeyId: ID of the key to use for encrypting new claims..
    func importEncryptionKeys(keys: [EncryptionKey], currentKeyId: String) throws

    /// Export encryption keys used for encrypting and decrypting Sudo claims.
    ///
    /// - Returns: Encryption keys.
    func exportEncryptionKeys() throws -> [EncryptionKey]

    /// Removes all keys associated with this provider.
    func reset() throws

}

/// Default `CryptoProvider` implementation.
public class DefaultCryptoProvider: CryptoProvider {

    private struct Constants {

        struct KeyName {
            static let symmetricKeyId = "symmetricKeyId"
        }

        struct Encryption {
            static let algorithmAES = "AES"
            static let defaultSymmetricKeyName = "symmetrickey"
        }

        struct KeyManager {
            static let defaultKeyManagerServiceName = "com.sudoplatform.appservicename"
            static let defaultKeyManagerKeyTag = "com.sudoplatform"
        }

    }

    /// KeyManager instance used for cryptographic operations.
    private var keyManager: SudoKeyManager

    public init(keyNamespace: String) {
        self.keyManager = LegacySudoKeyManager(serviceName: Constants.KeyManager.defaultKeyManagerServiceName,
                                             keyTag: Constants.KeyManager.defaultKeyManagerKeyTag,
                                             namespace: keyNamespace)
    }

    public func getSymmetricKeyId() throws -> String? {
        guard let symmKeyIdData = try self.keyManager.getPassword(Constants.KeyName.symmetricKeyId), let symmetricKeyId = String(data: symmKeyIdData, encoding: .utf8) else {
            return nil
        }

        return symmetricKeyId
    }

    public func encrypt(keyId: String, algorithm: SymmetricKeyEncryptionAlgorithm, data: Data) throws -> Data {
        let iv = try self.keyManager.createIV()
        let encryptedData = try self.keyManager.encryptWithSymmetricKey(keyId, data: data, iv: iv)
        return encryptedData + iv
    }

    public func decrypt(keyId: String, algorithm: SymmetricKeyEncryptionAlgorithm, data: Data) throws -> Data {
        guard data.count > LegacySudoKeyManager.Constants.defaultBlockSizeAES else {
            throw SudoProfilesClientError.invalidInput
        }

        let encryptedData = data[0..<data.count - 16]
        let iv = data[data.count - 16..<data.count]
        return try self.keyManager.decryptWithSymmetricKey(keyId, data: encryptedData, iv: iv)
    }

    public func generateEncryptionKey() throws -> String {
        // Generate symmetric key and store it under a unique key ID.
        let symmetricKeyId = try self.keyManager.generateKeyId()

        // Make sure symmetric key does not exists.
        try self.keyManager.deletePassword(Constants.KeyName.symmetricKeyId)
        try self.keyManager.deletePassword(symmetricKeyId)

        try self.keyManager.generateSymmetricKey(symmetricKeyId)

        guard let symmetricKeyIdData = symmetricKeyId.data(using: .utf8) else {
            throw SudoProfilesClientError.fatalError(description: "Cannot convert key ID to data.")
        }

        try self.keyManager.addPassword(symmetricKeyIdData, name: Constants.KeyName.symmetricKeyId)

        return symmetricKeyId
    }

    public func importEncryptionKeys(keys: [EncryptionKey], currentKeyId: String) throws {
        guard let symmetricKeyIdData = currentKeyId.data(using: .utf8) else {
            throw SudoProfilesClientError.fatalError(description: "Cannot convert key ID to data.")
        }

        try self.keyManager.removeAllKeys()
        try self.keyManager.importKeys(keys.compactMap {
            [
                KeyAttributeName.name: $0.id,
                KeyAttributeName.namespace: $0.namespace,
                KeyAttributeName.version: $0.version,
                KeyAttributeName.data: $0.key,
                KeyAttributeName.synchronizable: false,
                KeyAttributeName.type: KeyType.symmetricKey.rawValue
            ]
        } as [[KeyAttributeName: AnyObject]])

        try self.keyManager.deletePassword(Constants.KeyName.symmetricKeyId)
        try self.keyManager.addPassword(symmetricKeyIdData, name: Constants.KeyName.symmetricKeyId)
    }

    public func exportEncryptionKeys() throws -> [EncryptionKey] {
        let keys = try self.keyManager.exportKeys()
        return keys.compactMap {
            guard let name = $0[.name] as? String,
                  let type = $0[.type] as? String,
                  let namespace = $0[.namespace] as? String,
                  let version = $0[.version] as? Int,
                  let encoded = $0[.data] as? String,
                  type == KeyType.symmetricKey.rawValue else {
                return nil
            }

            return EncryptionKey(id: name, namespace: namespace, algorithm: Constants.Encryption.algorithmAES, version: version, key: encoded)
        }
    }

    public func reset() throws {
        try self.keyManager.removeAllKeys()
    }

}
