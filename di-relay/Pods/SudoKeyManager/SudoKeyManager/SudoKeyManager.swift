//
// Copyright © 2022 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// List of possible errors thrown by `SudoKeyManager`.
///
/// - duplicateKey: Indicates that during an *add* operation the key withthe name already existed.
/// - keyAttributeNotMutable: Indicates that the specified key attribute is not modifiable.
/// - keyAttributeNotSearchable: Indicates that the specified key attribute is not searchable.
/// - keyNotFound: Indicates the specified key was not found.
/// - invalidKey: Indicates the input key was invalid.
/// - invalidKeyName: Indicates the specified key name was invalid, e.g. empty string.
/// - invalidKeyType: Indicates the specified key type was invalid.
/// - invalidSearchParam: Indicates key search parameters were invalid.
/// - invalidCipherText: Indicates the input ciphertext was invalid.
/// - invalidEncryptedData: Indicates the input encrypted data was invalid.
/// - invalidInitializationVector: Indicates that the initialization vector is of an invalid size.
/// - unhandledUnderlyingSecAPIError: Indicates an unexpected error was returned by Apple's Security API. The encapsulated `code` indicates the underlying Apple Security API error code.
/// - fatalError: Indicates that a fatal error occurred. This could be due to coding error, out-of-memory condition or other conditions that is beyond control of `SudoKeyManager` implementation.
/// - uuidGenerationLimitExceeded: Indicates that the the UUID generation limit has been hit and cannot be handled.
/// - notImplemented: Indicates that the invoked API is not implemented.
public enum SudoKeyManagerError: Error, Equatable {
    case duplicateKey
    case keyAttributeNotMutable
    case keyAttributeNotSearchable
    case keyNotFound
    case invalidKey
    case invalidKeyName
    case invalidKeyType
    case invalidSearchParam
    case invalidCipherText
    case invalidEncryptedData
    case invalidInitializationVector
    case unhandledUnderlyingSecAPIError(code: Int32)
    case fatalError
    case uuidGenerationLimitExceeded
    case notImplemented
}

@available(*, deprecated, renamed: "PublicKeyEncryptionAlgorithm")
public typealias PublicKeyEncryptionlgorithm = PublicKeyEncryptionAlgorithm

/// Supported public key cryptography algorithms.
public enum PublicKeyEncryptionAlgorithm: Int {
    case rsaEncryptionPKCS1
    case rsaEncryptionOAEPSHA1
}

/// Protocol encapsulating a set of methods for securely storing keys and performing cryptographic operations.
public protocol SudoKeyManager {

    /// Namespace to use for the key name. If a namespace is specified then unique identifier for each key will be`"<namespace>.<keyName>"`.
    var namespace: String { get }

    /// Adds a password or other generic data to the secure store.
    ///
    /// - Parameters:
    ///   - password: Password or other generic data to store securely.
    ///   - name: Name of the secure data to be stored.
    /// - Throws: `SudoKeyManagerError`.
    func addPassword(_ password: Data, name: String) throws

    /// Adds a password or other generic data to the secure store.
    ///
    /// - Parameters:
    ///   - password: Password or other generic data to store securely.
    ///   - name: Name of the secure data to be stored.
    ///   - isSynchronizable: Indicates whether or not the password is synchronizable between multiple devices.
    ///   - isExportable: Indicates whether or not the password is exportable.
    /// - Throws: `SudoKeyManagerError`.
    func addPassword(_ password: Data, name: String, isSynchronizable: Bool, isExportable: Bool) throws

    ///  Retrieves a password or other generic data from the secure store.
    ///
    /// - Parameter name: Name of the secure data to be retrieved.
    /// - Throws: `SudoKeyManagerError`.
    func getPassword(_ name: String) throws -> Data?

    /// Deletes a password or other generic data from the secure store.
    ///
    /// - Parameter name: Name of the secure data to be deleted.
    /// - Throws: `SudoKeyManagerError`.
    func deletePassword(_ name: String) throws

    /// Updates a password or other generic data stored in the secure store.
    ///
    /// - Parameters:
    ///   - password: New password.
    ///   - name: Name of the secure data to be updated.
    /// - Throws: `SudoKeyManagerError`.
    func updatePassword(_ password: Data, name: String) throws

    /// Returns an existing key's attributes.
    ///
    /// - Parameters:
    ///   - name: Key name.
    ///   - type: Key type.
    /// - Throws: `SudoKeyManagerError`.
    func getKeyAttributes(_ name: String, type: KeyType) throws -> KeyAttributeSet?

    /// Updates an existing key's attributes.
    ///
    /// - Parameters:
    ///   - attributes: Key attributes to update.
    ///   - name: Name of the key to be updated.
    ///   - type: Key type.
    /// - Throws: `SudoKeyManagerError`.
    func updateKeyAttributes(_ attributes: KeyAttributeSet, name: String, type: KeyType) throws

    /// Generates and securely stores a symmetric key.
    ///
    /// - Parameter name: Name of the symmetric key to be generated.
    /// - Throws: `SudoKeyManagerError`.
    func generateSymmetricKey(_ name: String) throws

    /// Generates and securely stores a symmetric key.
    ///
    /// - Parameters:
    ///   - name: Name of the symmetric key to be generated.
    ///   - isExportable: indicates whether or not the password is exportable.
    /// - Throws: `SudoKeyManagerError`.
    func generateSymmetricKey(_ name: String, isExportable: Bool) throws

    /// Adds a symmetric key to the secure store.
    ///
    /// - Parameters:
    ///   - key: Symmetric key to store securely.
    ///   - name: Name of the symmetric key to be stored.
    /// - Throws: `SudoKeyManagerError.`
    func addSymmetricKey(_ key: Data, name: String) throws

    /// Adds a symmetric key to the secure store.
    ///
    /// - Parameters:
    ///   - key: Symmetric key to store securely.
    ///   - name: Name of the symmetric key to be stored.
    ///   - isExportable: indicates whether or not the password is exportable.
    /// - Throws: `SudoKeyManagerError`.
    func addSymmetricKey(_ key: Data, name: String, isExportable: Bool) throws

    /// Retrieves a symmetric key from the secure store.
    ///
    /// - Parameter name: Name of the symmetric key to be retrieved.
    /// - Throws: `SudoKeyManagerError`.
    func getSymmetricKey(_ name: String) throws -> Data?

    /// Deletes a symmetric key from the secure store.
    ///
    /// - Parameter name: Name of the symmetric key to be deleted.
    /// - Throws: `SudoKeyManagerError`.
    func deleteSymmetricKey(_ name: String) throws

    /// Encrypts the given data with the specified symmetric key stored in the secure store.
    ///
    /// - Parameters:
    ///   - name: Name of the symmetric key to use to encrypt.
    ///   - data: Data to encrypt.
    /// - Throws: `SudoKeyManagerError`.
    func encryptWithSymmetricKey(_ name: String, data: Data) throws -> Data

    /// Encrypts the given data with the specified symmetric key stored in the secure store.
    ///
    /// - Parameters:
    ///   - name: Name of the symmetric key to use to encrypt.
    ///   - data: Data to encrypt.
    ///   - iv: Initialization vector. Must be 128 bit in size.
    /// - Throws: `SudoKeyManagerError`.
    func encryptWithSymmetricKey(_ name: String, data: Data, iv: Data) throws -> Data

    /// Encrypts the given data with the given symmetric key.
    ///
    /// - Parameters:
    ///   - key: Key data.
    ///   - data: Data to encrypt.
    /// - Throws: `SudoKeyManagerError`.
    func encryptWithSymmetricKey(_ key: Data, data: Data) throws -> Data

    /// Encrypts the given data with the given symmetric key.
    ///
    /// - Parameters:
    ///   - key: Key data.
    ///   - data: Data to encrypt.
    ///   - iv: Initialization vector. Must be 128 bit in size.
    /// - Throws: `SudoKeyManagerError`.
    func encryptWithSymmetricKey(_ key: Data, data: Data, iv: Data) throws -> Data

    /// Decrypts the given data with the specified symmetric key stored in the secure store.
    ///
    /// - Parameters:
    ///   - name: Name of the symmetric key to use to encrypt.
    ///   - data: Data to encrypt.
    /// - Throws: `SudoKeyManagerError`.
    func decryptWithSymmetricKey(_ name: String, data: Data) throws -> Data
    
    /// Decrypts the given data with the specified symmetric key stored in the secure store.
    ///
    /// - Parameters:
    ///   - name: Name of the symmetric key to use to encrypt.
    ///   - data: Data to encrypt.
    ///   - iv: Initialization vector. Must be 128 bit in size.
    /// - Throws: `SudoKeyManagerError`.
    func decryptWithSymmetricKey(_ name: String, data: Data, iv: Data) throws -> Data

    /// Decrypts the given data with the given symmetric key.
    ///
    /// - Parameters:
    ///   - key: Key data.
    ///   - data: Data to encrypt.
    /// - Throws: `SudoKeyManagerError`.
    func decryptWithSymmetricKey(_ key: Data, data: Data) throws -> Data
    
    /// Decrypts the given data with the given symmetric key.
    ///
    /// - Parameters:
    ///   - key: Key data.
    ///   - data: Data to encrypt.
    ///   - iv: Initialization vector. Must be 128 bit in size.
    ///
    /// - Returns: Encrypted data.
    ///
    /// - Throws:
    ///     `SudoKeyManagerError.invalidInitializationVector`,
    ///     `SudoKeyManagerError.unhandledUnderlyingSecAPIError`,
    ///     `SudoKeyManagerError.fatalError`
    func decryptWithSymmetricKey(_ key: Data, data: Data, iv: Data) throws -> Data

    /// Creates a symmetric key from the specified password.
    ///
    /// - Parameter password: Password.
    ///
    /// - Returns:A tuple containing the following
    ///     - key: Key data.
    ///     - salt: Salt used for generating the key.
    ///     - rounds: Number of rounds of the pseudo random algorithm to used.
    ///
    /// - Throws:
    ///     `SudoKeyManagerError.fatalError`
    func createSymmetricKeyFromPassword(_ password: String) throws -> (key: Data, salt: Data, rounds: UInt32)
    
    /// Creates a symmetric key from the specified password.
    ///
    /// - Parameters:
    ///   - password: Password as String. Password will be UTF-8 encoded to Data before applying key derivation function.
    ///   - salt: Salt to use for generating the key.
    ///   - rounds: Number of rounds of the pseudo random algorithm to use.
    ///
    /// - Returns: Key data.
    /// - Throws:
    ///     `SudoKeyManagerError.fatalError`
    func createSymmetricKeyFromPassword(_ password: String, salt: Data, rounds: UInt32) throws -> Data

    /// Creates a symmetric key from the specified password.
    ///
    /// - Parameters:
    ///   - password: Password as Data.
    ///   - salt: Salt to use for generating the key.
    ///   - rounds: Number of rounds of the pseudo random algorithm to use.
    ///
    /// - Returns: Key data.
    /// - Throws:
    ///     `SudoKeyManagerError.fatalError`
    func createSymmetricKeyFromPassword(_ password: Data, salt: Data, rounds: UInt32) throws -> Data
    
    /// Creates a SHA256 hash of the specified data.
    ///
    /// - Parameter data: Data to hash.
    ///
    /// - Returns: Hash of the specified data.
    ///
    /// - Throws:
    ///     `SudoKeyManagerError.fatalError`
    func generateHash(_ data: Data) throws -> Data

    /// Generates and securely stores a key pair for public key cryptography.
    ///
    /// - Parameter name: Name of the key pair to be generated.
    ///
    /// - Throws:
    ///     `SudoKeyManagerError.duplicateKey`,
    ///     `SudoKeyManagerError.unhandledUnderlyingSecAPIError`,
    ///     `SudoKeyManagerError.fatalError`
    func generateKeyPair(_ name: String) throws
    
    /// Generates and securely stores a key pair for public key cryptography.
    ///
    /// - Parameters:
    ///   - name: Name of the key pair to be generated.
    ///   - isExportable: Indicates whether or not the password is exportable.
    ///
    /// - Throws:
    ///     `SudoKeyManagerError.duplicateKey`,
    ///     `SudoKeyManagerError.unhandledUnderlyingSecAPIError`,
    ///     `SudoKeyManagerError.fatalError`
    func generateKeyPair(_ name: String, isExportable: Bool) throws
    
    /// Generates a unique key id that does not collide with any existing key ids.
    ///
    /// - Throws:
    ///     `SudoKeyManagerError.uuidGenerationLimitExceeded`
    func generateKeyId() throws -> String
    
    /// Adds a private key to the secure store.
    ///
    /// - Parameters:
    ///   - key: Private key to store securely.
    ///   - name: Name of the private key to be stored.
    ///
    /// - Throws:
    ///     `SudoKeyManagerError.duplicateKey`,
    ///     `SudoKeyManagerError.unhandledUnderlyingSecAPIError`,
    ///     `SudoKeyManagerError.fatalError`
    func addPrivateKey(_ key: Data, name: String) throws
    
    /// Adds a private key to the secure store.
    ///
    /// - Parameters:
    ///   - key: Private key to store securely.
    ///   - name: Name of the private key to be stored.
    ///   - isExportable: Indicates whether or not the password is exportable.
    ///
    /// - Throws:
    ///     `SudoKeyManagerError.duplicateKey`,
    ///     `SudoKeyManagerError.unhandledUnderlyingSecAPIError`,
    ///     `SudoKeyManagerError.fatalError`
    func addPrivateKey(_ key: Data, name: String, isExportable: Bool) throws
    
    /// Retrieves a private key from the secure store.
    ///
    /// - Parameter name: Name of the private key to be retrieved.
    ///
    /// - Returns: Requested private key or nil if the key was not found.
    ///
    /// - Throws:
    ///     `SudoKeyManagerError.unhandledUnderlyingSecAPIError`,
    ///     `SudoKeyManagerError.fatalError`
    func getPrivateKey(_ name: String) throws -> Data?
    
    /// Deletes a private key from the secure store.
    ///
    /// - Parameter name: Name of the private key to be deleted.
    ///
    /// - Throws:
    ///     `SudoKeyManagerError.unhandledUnderlyingSecAPIError`,
    ///     `SudoKeyManagerError.fatalError`
    func deletePrivateKey(_ name: String) throws

    /// Adds a public key to the secure store.
    ///
    /// - Parameters:
    ///   - key: Public key to store securely.
    ///   - name: Name of the public key to be stored.
    ///
    /// - Throws:
    ///     `SudoKeyManagerError.duplicateKey`,
    ///     `SudoKeyManagerError.unhandledUnderlyingSecAPIError`,
    ///     `SudoKeyManagerError.fatalError`
    func addPublicKey(_ key: Data, name: String) throws
    
    /// Adds a PEM encoded public key to the secure store.
    ///
    /// - Parameters:
    ///   - key: Public key to store securely.
    ///   - name: Name of the public key to be stored.
    ///
    /// - Throws:
    ///     `SudoKeyManagerError.duplicateKey`,
    ///     `SudoKeyManagerError.invalidKey`,
    ///     `SudoKeyManagerError.unhandledUnderlyingSecAPIError`,
    ///     `SudoKeyManagerError.fatalError`
    func addPublicKeyFromPEM(_ key: String, name: String) throws
    
    /// Adds a public key to the secure store.
    ///
    /// - Parameters:
    ///   - key: Public key to store securely.
    ///   - name: Name of the public key to be stored.
    ///   - isExportable: Indicates whether or not the password is exportable.
    ///
    /// - Throws:
    ///     `SudoKeyManagerError.duplicateKey`,
    ///     `SudoKeyManagerError.unhandledUnderlyingSecAPIError`,
    ///     `SudoKeyManagerError.fatalError`
    func addPublicKey(_ key: Data, name: String, isExportable: Bool) throws
    
    /// Adds a PEM encoded public key to the secure store.
    ///
    /// - Parameters:
    ///   - key: Public key to store securely.
    ///   - name: Name of the public key to be stored.
    ///   - isExportable: Indicates whether or not the password is exportable.
    ///
    /// - Throws:
    ///     `SudoKeyManagerError.duplicateKey`,
    ///     `SudoKeyManagerError.invalidKey`,
    ///     `SudoKeyManagerError.unhandledUnderlyingSecAPIError`,
    ///     `SudoKeyManagerError.fatalError`
    func addPublicKeyFromPEM(_ key: String, name: String, isExportable: Bool) throws

    /// Retrieves a public key from the secure store.
    ///
    /// - Parameter name: Name of the public key to be retrieved.
    ///
    /// - Returns: Requested public key or nil if the key was not found.
    ///
    /// - Throws:
    ///     `SudoKeyManagerError.unhandledUnderlyingSecAPIError`,
    ///     `SudoKeyManagerError.fatalError`
    func getPublicKey(_ name: String) throws -> Data?
    
    /// Retrieves a public key from the secure store as PEM encoded string.
    ///
    /// - Parameter name: Name of the public key to be retrieved.
    ///
    /// - Returns: Requested public key or nil if the key was not found.
    ///
    /// - Throws:
    ///     `SudoKeyManagerError.unhandledUnderlyingSecAPIError`,
    ///     `SudoKeyManagerError.fatalError`
    func getPublicKeyAsPEM(_ name: String) throws -> String?
    
    /// Deletes a public key from the secure store.
    ///
    /// - Parameter name: Name of the public key to be deleted.
    ///
    /// - Throws:
    ///     `SudoKeyManagerError.unhandledUnderlyingSecAPIError`,
    ///     `SudoKeyManagerError.fatalError`
    func deletePublicKey(_ name: String) throws
    
    /// Deletes a key pair from the secure store.
    ///
    /// - Parameter name: Name of the key pair to be deleted.
    ///
    /// - Throws:
    ///     `SudoKeyManagerError.unhandledUnderlyingSecAPIError`,
    ///     `SudoKeyManagerError.fatalError`
    func deleteKeyPair(_ name: String) throws

    /// Generates a signature for the given data with the specified
    /// private key.
    /// - Parameters:
    ///   - name: Name of the private key to use for signing.
    ///   - data: Data to sign.
    ///
    /// - Returns: Generated signature.
    ///
    /// - Throws:
    ///     `SudoKeyManagerError.keyNotFound`,
    ///     `SudoKeyManagerError.unhandledUnderlyingSecAPIError`,
    ///     `SudoKeyManagerError.fatalError`
    func generateSignatureWithPrivateKey(_ name: String, data: Data) throws -> Data
    
    /// Verifies the given signature for the given data with the specified
    /// public key.
    ///
    /// - Parameters:
    ///   - name: Name of the public key to use for verifying the signature.
    ///   - data: Data associated with the signature.
    ///   - signature: Signature to verify.
    ///
    /// - Returns: `true` if the signature is valid.
    ///
    /// - Throws:
    ///     `SudoKeyManagerError.keyNotFound`,
    ///     `SudoKeyManagerError.unhandledUnderlyingSecAPIError`,
    ///     `SudoKeyManagerError.fatalError`
    func verifySignatureWithPublicKey(_ name: String, data: Data, signature: Data) throws -> Bool

    /// Encrypts the given data with the specified public key.
    ///
    /// - Parameters:
    ///   - name: Name of the public key to use for encryption.
    ///   - data: Data encrypt.
    ///   - algorithm: Encryption algorithm to use.
    ///
    /// - Returns: encrypted data.
    ///
    /// - Throws:
    ///     `SudoKeyManagerError.keyNotFound`,
    ///     `SudoKeyManagerError.unhandledUnderlyingSecAPIError`,
    ///     `SudoKeyManagerError.fatalError`
    func encryptWithPublicKey(_ name: String, data: Data, algorithm: PublicKeyEncryptionAlgorithm) throws -> Data
    
    /// Decrypts the given data with the specified private key.
    ///
    /// - Parameters:
    ///   - name: Name of the private key to use for decryption.
    ///   - data: Data decrypt.
    ///   - algorithm: Decryption algorithm to use.
    ///
    /// - Throws:
    ///     `SudoKeyManagerError.keyNotFound`,
    ///     `SudoKeyManagerError.invalidCipherText`,
    ///     `SudoKeyManagerError.unhandledUnderlyingSecAPIError`,
    ///     `SudoKeyManagerError.fatalError`
    func decryptWithPrivateKey(_ name: String, data: Data, algorithm: PublicKeyEncryptionAlgorithm) throws -> Data
    
    /// Creates random data. Used mainly for generating symmetric keys.
    ///
    /// - Parameter size: Size (in bytes) of the random data to create.
    ///
    /// - Throws:
    ///     `SudoKeyManagerError.unhandledUnderlyingSecAPIError`,
    ///     `SudoKeyManagerError.fatalError`
    func createRandomData(_ size: Int) throws -> Data
    
    /// Remove all keys associated with this `SudoKeyManager`.
    ///
    /// - Throws:
    ///     `SudoKeyManagerError.unhandledUnderlyingSecAPIError`,
    ///     `SudoKeyManagerError.fatalError`
    func removeAllKeys() throws

    /// Export all keys associated with this `SudoKeyManager`.
    ///
    /// - Returns: Keys exported as an array of key attributes and key data.
    ///
    /// - Throws:
    ///     `SudoKeyManagerError.unhandledUnderlyingSecAPIError`,
    ///     `SudoKeyManagerError.fatalError`
    func exportKeys() throws -> [[KeyAttributeName: AnyObject]]
    
    /// Import keys into the secure store. It's recommended to remove all
    /// keys before calling this method in order to avoid key conflicts.
    ///
    /// - Parameter keys: keys to be imported. The value of this parameter is
    ///     expected to have been initially generated by `exportKeys`
    ///     method.
    ///
    /// - Throws:
    ///     `SudoKeyManagerError.duplicateKey`,
    ///     `SudoKeyManagerError.unhandledUnderlyingSecAPIError`,
    ///     `SudoKeyManagerError.fatalError`
    func importKeys(_ keys: [[KeyAttributeName: AnyObject]]) throws
    
    /// Returns the fully qualified key ID based on the key name and type
    /// specified. This ID uniquely identifies a key within the secure store
    /// and its format will dependent on the implementation of `SudoKeyManager`.
    ///
    /// - Parameters:
    ///   - name: Key name.
    ///   - type: Key type.
    ///
    /// - Throws:
    ///     `SudoKeyManagerError.invalidKeyName`
    func getKeyId(_ name: String, type: KeyType) throws -> String

    /// Retrieves attributes of keys matching the specified search parameters.
    ///
    /// - Parameter searchAttributes: Search attributes. If empty then all keys
    ///     managed by this `SudoKeyManager` will be returned.
    ///
    /// - Throws:
    ///     `SudoKeyManagerError.invalidSearchParam`,
    ///     `SudoKeyManagerError.unhandledUnderlyingSecAPIError`,
    ///     `SudoKeyManagerError.fatalError`
    func getAttributesForKeys(_ searchAttributes: KeyAttributeSet) throws -> [KeyAttributeSet]
    
    /// Creates initialization vector for symmetric encryption.
    ///
    /// - Returns: Initialization vector.
    ///
    /// - Throws:
    ///     `SudoKeyManagerError.unhandledUnderlyingSecAPIError`,
    ///     `SudoKeyManagerError.fatalError`
    func createIV() throws -> Data
    
}

public extension SudoKeyManager {
    
    func encryptWithPublicKey(_ name: String, data: Data) throws -> Data {
        return try encryptWithPublicKey(name, data: data, algorithm: .rsaEncryptionPKCS1)
    }
    
    func decryptWithPrivateKey(_ name: String, data: Data) throws -> Data {
        return try decryptWithPrivateKey(name, data: data, algorithm: .rsaEncryptionPKCS1)
    }

    func createSymmetricKeyFromPassword(_ password: String, salt: Data, rounds: UInt32) throws -> Data {
        guard let passwordData = password.data(using: String.Encoding.utf8) else {
            throw SudoKeyManagerError.fatalError
        }

        return try createSymmetricKeyFromPassword(passwordData, salt: salt, rounds: rounds)
    }
    
}
