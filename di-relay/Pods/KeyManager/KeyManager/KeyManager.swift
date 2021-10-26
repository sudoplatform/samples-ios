//
//  KeyManager.swift
//  KeyManager
//
//  Created by cchoi on 11/07/2016.
//  Copyright © 2015 Anonyome Labs, Inc. All rights reserved.
//

import Foundation
import Security
import CommonCrypto

/// Enum of possible errors thrown by `KeyManager`.
///
/// - duplicateKey: Indicates that during an *add* operation the key withthe name already existed.
/// - keyAttributeNotMutable: Indicates that the specified key attribute is not modifiable.
/// - keyAttributeNotSearchable: Indicates that the specified key attribute is not searchable.
/// - keyNotFound: Indicates the specified key was not found.
/// - invalidKeyName: Indicates the specified key name was invalid, e.g. empty string.
/// - invalidKeyType: Indicates the specified key type was invalid.
/// - invalidSearchParam: Indicates key search parameters were invalid.
/// - invalidCipherText: Indicates the input ciphertext was invalid.
/// - invalidInitializationVector: Indicates that the initialization vector is of an invalid size.
/// - unhandledUnderlyingSecAPIError: Indicates an unexpected error was returned by Apple's Security API. The encapsulated `code` indicates the underlying Apple Security API error code.
/// - fatalError: Indicates that a fatal error occurred. This could be due to coding error, out-of-memory condition or other conditions that is beyond control of `KeyManager` implementation.
/// - uuidGenerationLimitExceeded: Indicates that the the UUID generation limit has been hit and cannot be handled.
/// - memoryBindError: Indicates that an error has occurred while attempting to bind unsafe buffer memory to an unsafe pointer.
public enum KeyManagerError: Error, Equatable {
    case duplicateKey
    case keyAttributeNotMutable
    case keyAttributeNotSearchable
    case keyNotFound
    case invalidKeyName
    case invalidKeyType
    case invalidSearchParam
    case invalidCipherText
    case invalidInitializationVector
    case unhandledUnderlyingSecAPIError(code: Int32)
    case fatalError
    case uuidGenerationLimitExceeded
}

@available(*, deprecated, renamed: "PublicKeyEncryptionAlgorithm")
public typealias PublicKeyEncryptionlgorithm = PublicKeyEncryptionAlgorithm

/// Supported public key cryptography algorithms.
public enum PublicKeyEncryptionAlgorithm: Int {
    case rsaEncryptionPKCS1
    case rsaEncryptionOAEPSHA1
}

/// Protocol encapsulating a set of methods for securely storing keys and performing cryptographic operations.
public protocol KeyManager {

    /// Namespace to use for the key name. If a namespace is specified then unique identifier for each key will be`"<namespace>.<keyName>"`.
    var namespace: String { get }

    /// Adds a password or other generic data to the secure store.
    ///
    /// - Parameters:
    ///   - password: Password or other generic data to store securely.
    ///   - name: Name of the secure data to be stored.
    /// - Throws: `KeyManagerError`.
    func addPassword(_ password: Data, name: String) throws

    /// Adds a password or other generic data to the secure store.
    ///
    /// - Parameters:
    ///   - password: Password or other generic data to store securely.
    ///   - name: Name of the secure data to be stored.
    ///   - isSynchronizable: Indicates whether or not the password is synchronizable between multiple devices.
    ///   - isExportable: Indicates whether or not the password is exportable.
    /// - Throws: `KeyManagerError`.
    func addPassword(_ password: Data, name: String, isSynchronizable: Bool, isExportable: Bool) throws

    ///  Retrieves a password or other generic data from the secure store.
    ///
    /// - Parameter name: Name of the secure data to be retrieved.
    /// - Throws: `KeyManagerError`.
    func getPassword(_ name: String) throws -> Data?

    /// Deletes a password or other generic data from the secure store.
    ///
    /// - Parameter name: Name of the secure data to be deleted.
    /// - Throws: `KeyManagerError`.
    func deletePassword(_ name: String) throws

    /// Updates a password or other generic data stored in the secure store.
    ///
    /// - Parameters:
    ///   - password: New password.
    ///   - name: Name of the secure data to be updated.
    /// - Throws: `KeyManagerError`.
    func updatePassword(_ password: Data, name: String) throws

    /// Returns an existing key's attributes.
    ///
    /// - Parameters:
    ///   - name: Key name.
    ///   - type: Key type.
    /// - Throws: `KeyManagerError`.
    func getKeyAttributes(_ name: String, type: KeyType) throws -> KeyAttributeSet?

    /// Updates an existing key's attributes.
    ///
    /// - Parameters:
    ///   - attributes: Key attributes to update.
    ///   - name: Name of the key to be updated.
    ///   - type: Key type.
    /// - Throws: `KeyManagerError`.
    func updateKeyAttributes(_ attributes: KeyAttributeSet, name: String, type: KeyType) throws

    /// Generates and securely stores a symmetric key.
    ///
    /// - Parameter name: Name of the symmetric key to be generated.
    /// - Throws: `KeyManagerError`.
    func generateSymmetricKey(_ name: String) throws

    /// Generates and securely stores a symmetric key.
    ///
    /// - Parameters:
    ///   - name: Name of the symmetric key to be generated.
    ///   - isExportable: indicates whether or not the password is exportable.
    /// - Throws: `KeyManagerError`.
    func generateSymmetricKey(_ name: String, isExportable: Bool) throws

    /// Adds a symmetric key to the secure store.
    ///
    /// - Parameters:
    ///   - key: Symmetric key to store securely.
    ///   - name: Name of the symmetric key to be stored.
    /// - Throws: `KeyManagerError.`
    func addSymmetricKey(_ key: Data, name: String) throws

    /// Adds a symmetric key to the secure store.
    ///
    /// - Parameters:
    ///   - key: Symmetric key to store securely.
    ///   - name: Name of the symmetric key to be stored.
    ///   - isExportable: indicates whether or not the password is exportable.
    /// - Throws: `KeyManagerError`.
    func addSymmetricKey(_ key: Data, name: String, isExportable: Bool) throws

    /// Retrieves a symmetric key from the secure store.
    ///
    /// - Parameter name: Name of the symmetric key to be retrieved.
    /// - Throws: `KeyManagerError`.
    func getSymmetricKey(_ name: String) throws -> Data?

    /// Deletes a symmetric key from the secure store.
    ///
    /// - Parameter name: Name of the symmetric key to be deleted.
    /// - Throws: `KeyManagerError`.
    func deleteSymmetricKey(_ name: String) throws

    /// Encrypts the given data with the specified symmetric key stored in the secure store.
    ///
    /// - Parameters:
    ///   - name: Name of the symmetric key to use to encrypt.
    ///   - data: Data to encrypt.
    /// - Throws: `KeyManagerError`.
    func encryptWithSymmetricKey(_ name: String, data: Data) throws -> Data

    /// Encrypts the given data with the specified symmetric key stored in the secure store.
    ///
    /// - Parameters:
    ///   - name: Name of the symmetric key to use to encrypt.
    ///   - data: Data to encrypt.
    ///   - iv: Initialization vector. Must be 128 bit in size.
    /// - Throws: `KeyManagerError`.
    func encryptWithSymmetricKey(_ name: String, data: Data, iv: Data) throws -> Data

    /// Encrypts the given data with the given symmetric key.
    ///
    /// - Parameters:
    ///   - key: Key data.
    ///   - data: Data to encrypt.
    /// - Throws: `KeyManagerError`.
    func encryptWithSymmetricKey(_ key: Data, data: Data) throws -> Data

    /// Encrypts the given data with the given symmetric key.
    ///
    /// - Parameters:
    ///   - key: Key data.
    ///   - data: Data to encrypt.
    ///   - iv: Initialization vector. Must be 128 bit in size.
    /// - Throws: `KeyManagerError`.
    func encryptWithSymmetricKey(_ key: Data, data: Data, iv: Data) throws -> Data

    /// Decrypts the given data with the specified symmetric key stored in the secure store.
    ///
    /// - Parameters:
    ///   - name: Name of the symmetric key to use to encrypt.
    ///   - data: Data to encrypt.
    /// - Throws: `KeyManagerError`.
    func decryptWithSymmetricKey(_ name: String, data: Data) throws -> Data
    
    /// Decrypts the given data with the specified symmetric key stored in the secure store.
    ///
    /// - Parameters:
    ///   - name: Name of the symmetric key to use to encrypt.
    ///   - data: Data to encrypt.
    ///   - iv: Initialization vector. Must be 128 bit in size.
    /// - Throws: `KeyManagerError`.
    func decryptWithSymmetricKey(_ name: String, data: Data, iv: Data) throws -> Data

    /// Decrypts the given data with the given symmetric key.
    ///
    /// - Parameters:
    ///   - key: Key data.
    ///   - data: Data to encrypt.
    /// - Throws: `KeyManagerError`.
    func decryptWithSymmetricKey(_ key: Data, data: Data) throws -> Data
    
    /**
        Decrypts the given data with the given symmetric key.
     
        - Parameters:
            - name: Key data.
            - data: Data to encrypt.
            - iv: Initialization vector. Must be 128 bit in size.
     
        - Returns: Encrypted data.
     
        - Throws:
            `KeyManagerError.InvalidInitializationVector`,
            `KeyManagerError.UnhandledUnderlyingSecAPIError`,
            `KeyManagerError.FatalError`
     */
    func decryptWithSymmetricKey(_ key: Data, data: Data, iv: Data) throws -> Data
    
    /**
        Creates a symmetric key from the specified password.
     
        - Parameters:
            - password: Password.
     
        - Returns: A tuple containing the following
            - key: Key data.
            - salt: Salt used for generating the key.
            - rounds: Number of rounds of the pseudo random algorithm to used.
     
        - Throws:
            `KeyManagerError.FatalError`
     */
    func createSymmetricKeyFromPassword(_ password: String) throws -> (key: Data, salt: Data, rounds: UInt32)
    
    /**
        Creates a symmetric key from the specified password.
     
        - Parameters:
            - password: Password.
            - salt: Salt to use for generating the key.
            - rounds: Number of rounds of the pseudo random algorithm to use.
     
        - Returns: Key data.
     
        - Throws:
            `KeyManagerError.FatalError`
     */
    func createSymmetricKeyFromPassword(_ password: String, salt: Data, rounds: UInt32) throws -> Data
    
    /**
        Creates a SHA256 hash of the specified data.
     
        - Parameters:
            - data: Data to hash.
     
        - Returns: Hash of the specified data.
     
        - Throws:
            `KeyManagerError.FatalError`
     */
    func generateHash(_ data: Data) throws -> Data
    
    /**
        Generates and securely stores a key pair for public key cryptography.
     
        - Parameters:
            - name: Name of the key pair to be generated.
     
        - Throws:
            `KeyManagerError.DuplicateKey`,
            `KeyManagerError.UnhandledUnderlyingSecAPIError`,
            `KeyManagerError.FatalError`
     */
    func generateKeyPair(_ name: String) throws
    
    /**
        Generates and securely stores a key pair for public key cryptography.
     
        - Parameters:
            - name: Name of the key pair to be generated.
            - isExportable: indicates whether or not the password is exportable.
     
        - Throws:
            `KeyManagerError.DuplicateKey`,
            `KeyManagerError.UnhandledUnderlyingSecAPIError`,
            `KeyManagerError.FatalError`
     */
    func generateKeyPair(_ name: String, isExportable: Bool) throws
    
    /**
     Generates a unique key id that does not collide with any existing key ids.
     
     - Throws:
         `KeyManagerError.uuidGenerationLimitExceeded`
     */
    func generateKeyId() throws -> String
    
    /**
        Adds a private key to the secure store.
     
        - Parameters:
            - key: Private key to store securely.
            - name: Name of the private key to be stored.
     
        - Throws:
            `KeyManagerError.DuplicateKey`,
            `KeyManagerError.UnhandledUnderlyingSecAPIError`,
            `KeyManagerError.FatalError`
     */
    func addPrivateKey(_ key: Data, name: String) throws
    
    /**
        Adds a private key to the secure store.
     
        - Parameters:
            - key: Private key to store securely.
            - name: Name of the private key to be stored.
            - isExportable: indicates whether or not the password is exportable.
     
        - Throws:
            `KeyManagerError.DuplicateKey`,
            `KeyManagerError.UnhandledUnderlyingSecAPIError`,
            `KeyManagerError.FatalError`
     */
    func addPrivateKey(_ key: Data, name: String, isExportable: Bool) throws
    
    /**
        Retrieves a private key from the secure store.
     
        - Parameters:
            - name: Name of the private key to be retrieved.
     
        - Returns: Requested private key or nil if the key was not found.
     
        - Throws:
            `KeyManagerError.UnhandledUnderlyingSecAPIError`,
            `KeyManagerError.FatalError`
     */
    func getPrivateKey(_ name: String) throws -> Data?
    
    
    /**
        Adds a public key to the secure store.
     
        - Parameters:
            - key: Public key to store securely.
            - name: Name of the public key to be stored.
     
        - Throws:
            `KeyManagerError.DuplicateKey`,
            `KeyManagerError.UnhandledUnderlyingSecAPIError`,
            `KeyManagerError.FatalError`
     */
    func addPublicKey(_ key: Data, name: String) throws
    
    /**
        Adds a public key to the secure store.
     
        - Parameters:
            - key: Public key to store securely.
            - name: Name of the public key to be stored.
            - isExportable: indicates whether or not the password is exportable.
     
        - Throws:
            `KeyManagerError.DuplicateKey`,
            `KeyManagerError.UnhandledUnderlyingSecAPIError`,
            `KeyManagerError.FatalError`
     */
    func addPublicKey(_ key: Data, name: String, isExportable: Bool) throws
    
    /**
        Retrieves a public key from the secure store.
     
        - Parameters:
            - name: Name of the public key to be retrieved.
     
        - Returns: Requested public key or nil if the key was not found.
     
        - Throws:
            `KeyManagerError.UnhandledUnderlyingSecAPIError`,
            `KeyManagerError.FatalError`
     */
    func getPublicKey(_ name: String) throws -> Data?
    
    /**
        Deletes a key pair from the secure store.
     
        - Parameters:
            - name: Name of the key pair to be deleted.
     
        - Throws:
            `KeyManagerError.UnhandledUnderlyingSecAPIError`,
            `KeyManagerError.FatalError`
     */
    func deleteKeyPair(_ name: String) throws

    /**
        Generates a signature for the given data with the specified
        private key.
 
        - Parameters:
            - name: Name of the private key to use for signing.
            - data: Data to sign.
     
        - Returns: Generated signature.
     
        - Throws:
            `KeyManagerError.KeyNotFound`,
            `KeyManagerError.UnhandledUnderlyingSecAPIError`,
            `KeyManagerError.FatalError`
     */
    func generateSignatureWithPrivateKey(_ name: String, data: Data) throws -> Data
    
    /**
        Verifies the given signature for the given data with the specified 
        public key.
     
        - Parameters:
            - name: Name of the public key to use for verifying the signature.
            - data: Data associated with the signature.
            - signature: Signature to verify.
     
        - Returns: `true` if the signature is valid.
     
        - Throws:
            `KeyManagerError.KeyNotFound`,
            `KeyManagerError.UnhandledUnderlyingSecAPIError`,
            `KeyManagerError.FatalError`
     */
    func verifySignatureWithPublicKey(_ name: String, data: Data, signature: Data) throws -> Bool
    
    /**
        Encrypts the given data with the specified public key.
     
        - Parameters:
            - data: Data encrypt.
            - name: Name of the public key to use for encryption.
     
        - Returns: encrypted data.
     
        - Throws:
            `KeyManagerError.KeyNotFound`,
            `KeyManagerError.UnhandledUnderlyingSecAPIError`,
            `KeyManagerError.FatalError`
     */
    func encryptWithPublicKey(_ name: String, data: Data, algorithm: PublicKeyEncryptionAlgorithm) throws -> Data
    
    /**
        Decrypts the given data with the specified private key.
     
        - Parameters:
            - data: Data decrypt.
            - name: Name of the private key to use for decryption.
     
        - Returns: plaintext data.
     
        - Throws:
            `KeyManagerError.KeyNotFound`,
            `KeyManagerError.InvalidCipherText`,
            `KeyManagerError.UnhandledUnderlyingSecAPIError`,
            `KeyManagerError.FatalError`
     */
    func decryptWithPrivateKey(_ name: String, data: Data, algorithm: PublicKeyEncryptionAlgorithm) throws -> Data
    
    /**
        Creates random data. Used mainly for generating symmetric keys.
     
        - Parameters:
            - size: Size (in bytes) of the random data to create.
     
        - Throws:
            `KeyManagerError.UnhandledUnderlyingSecAPIError`,
            `KeyManagerError.FatalError`
    */
    func createRandomData(_ size: Int) throws -> Data
    
    /**
        Remove all keys associated with this `KeyManager`.
     
        - Throws:
            `KeyManagerError.UnhandledUnderlyingSecAPIError`,
            `KeyManagerError.FatalError`
     */
    func removeAllKeys() throws
 
    /**
        Export all keys associated with this `KeyManager`.
     
        - Returns: Keys exported as an array of key attributes and key data.
     
        - Throws:
            `KeyManagerError.UnhandledUnderlyingSecAPIError`,
            `KeyManagerError.FatalError`
     */
    func exportKeys() throws -> [[KeyAttributeName: AnyObject]]
    
    /**
        Import keys into the secure store. It's recommended to remove all
        keys before calling this method in order to avoid key conflicts.
     
        - Parameters:
            - keys: keys to be imported. The value of this parameter is
                expected to have been initially generated by `exportKeys`
                method.

        - Throws:
            `KeyManagerError.DuplicateKey`,
            `KeyManagerError.UnhandledUnderlyingSecAPIError`,
            `KeyManagerError.FatalError`
     */
    func importKeys(_ keys: [[KeyAttributeName: AnyObject]]) throws
    
    /**
        Returns the fully qualified key ID based on the key name and type
        specified. This ID uniquely identifies a key within the secure store
        and its format will dependent on the implementation of `KeyManager`.
     
        - Parameters:
            - name: Key name.
            - type: Key type.
        
        - Returns: Key ID.
     
        - Throws:
            `KeyManagerError.InvalidKeyName`,
     */
    func getKeyId(_ name: String, type: KeyType) throws -> String
    
    /**
        Retrieves attributes of keys matching the specified search parameters.
     
        - Parameters:
            - searchAttributes: Search attributes. If empty then all keys
                managed by this `KeyManager` will be returned.
     
        - Return: attributes of keys matching the specified search parameters.
     
        - Throws:
            `KeyManagerError.InvalidSearchParam`,
            `KeyManagerError.UnhandledUnderlyingSecAPIError`,
            `KeyManagerError.FatalError`
     */
    func getAttributesForKeys(_ searchAttributes: KeyAttributeSet) throws -> [KeyAttributeSet]
    
    /**
        Creates initialization vector for symmetric encryption.
     
        - Return: Initialization vector.
     
        - Throws:
            `KeyManagerError.UnhandledUnderlyingSecAPIError`,
            `KeyManagerError.FatalError`
     */
    func createIV() throws -> Data
    
}

public extension KeyManager {
    
    func encryptWithPublicKey(_ name: String, data: Data) throws -> Data {
        return try encryptWithPublicKey(name, data: data, algorithm: .rsaEncryptionPKCS1)
    }
    
    func decryptWithPrivateKey(_ name: String, data: Data) throws -> Data {
        return try decryptWithPrivateKey(name, data: data, algorithm: .rsaEncryptionPKCS1)
    }
    
}

/**
    Class encapsulating the default implementation of `KeyManager` protocol
    that uses Apple's Keychain and Common Crypto API.
 */
final public class KeyManagerImpl {
    
    /**
        Determines how the key will be returned by `KeyManager` API.
     
        - Reference: A reference to the key will be returned.
        - Data: Actual key data will be returned.
        - Attributes: Metadata associated with the key will be returned.
     */
    fileprivate enum ReturnDataType {
        case reference
        case data
        case attributes
    }
    
    /**
        List of contants used by this class.
    */
    public struct Constants {
        static let keyVersion = 1
        
        static let uuidGenerationLimit = 100
        
        public static let defaultKeySizeAES = kCCKeySizeAES256 << 3
        public static let defaultBlockSizeAES = kCCBlockSizeAES128
        public static let defaultKeySizeRSA = 2048
        
        static let keyNamePrefixPrivateKey = "privatekey"
        static let keyNamePrefixPublicKey = "publickey"
        
        static let keyLabelExportable = "Exp"
        static let keyLabelNotExportable = "NoExp"

        // Key attribute names.
        static let secClass = kSecClass as String
        static let secAttrKeyClass = kSecAttrKeyClass as String
        static let secAttrGeneric = kSecAttrGeneric as String
        static let secAttrAccount = kSecAttrAccount as String
        static let secAttrService = kSecAttrService as String
        static let secAttrApplicationTag = kSecAttrApplicationTag as String
        static let secValueData = kSecValueData as String
        static let secMatchLimit = kSecMatchLimit as String
        static let secReturnAttributes = kSecReturnAttributes as String
        static let secReturnRef = kSecReturnRef as String
        static let secReturnData = kSecReturnData as String
        static let secAttrSynchronizable = kSecAttrSynchronizable as String
        static let secAttrIsPermanent = kSecAttrIsPermanent as String
        static let secAttrAccessible = kSecAttrAccessible as String
        static let secAttrKeyType = kSecAttrKeyType as String
        static let secAttrCanEncrypt = kSecAttrCanEncrypt as String
        static let secAttrCanDecrypt = kSecAttrCanDecrypt as String
        static let secAttrCanDerive = kSecAttrCanDerive as String
        static let secAttrCanSign = kSecAttrCanSign as String
        static let secAttrCanVerify = kSecAttrCanVerify as String
        static let secAttrCanWrap = kSecAttrCanWrap as String
        static let secAttrCanUnwrap = kSecAttrCanUnwrap as String
        static let secAttrKeySizeInBits = kSecAttrKeySizeInBits as String
        static let secAttrEffectiveKeySize = kSecAttrEffectiveKeySize as String
        static let secPrivateKeyAttrs = kSecPrivateKeyAttrs as String
        static let secPublicKeyAttrs = kSecPublicKeyAttrs as String
        static let secAttrLabel = kSecAttrLabel as String
        
        // Key attribute values.
        static let secClassKey = kSecClassKey as String
        static let secClassGenericPassword = kSecClassGenericPassword as String
        static let secClassInternetPassword = kSecClassInternetPassword as String
        static let secClassCertificate = kSecClassCertificate as String
        static let secClassIdentity = kSecClassIdentity as String
        static let secAttrKeyClassPrivate = kSecAttrKeyClassPrivate as String
        static let secAttrKeyClassPublic = kSecAttrKeyClassPublic as String
        static let secAttrKeyClassSymmetric = kSecAttrKeyClassSymmetric as String
        static let secAttrKeyTypeRSA = kSecAttrKeyTypeRSA as String
        
        // For some reason the constants for various symmetric encryption
        // algorithms are only defined in Mac OS. Defining them manually
        // since keychain API doesn't seem to care and it's helpful to
        // record what type of key it is when adding a symmetric key to
        // the keychain. The constant values being defined here is actually
        // the correct value used in Mac OS. These can be removed once
        // Apple makes Common Crypto API consistent between iOS and Mac OS.
        #if os(iOS)
        
        static let secAttrKeyTypeAES = "2147483649"
        
        #else
        
        static let secAttrKeyTypeAES = kSecAttrKeyTypeAES as String
        
        #endif
        
        static let secMatchLimitOne = kSecMatchLimitOne as String
        static let secMatchLimitAll = kSecMatchLimitAll as String
        static let secAttrSynchronizableAny = kSecAttrSynchronizableAny as String
        static let secAttrAccessibleAfterFirstUnlock = kSecAttrAccessibleAfterFirstUnlock as String
    }
    
    /**
        The service name (`KSecAttrService`) to associate with passwords. It is used
        to specify the owning service of `kSecClassGenericPassword` keychain items
        and is a part of the primary key used to look up `kSecClassGenericPassword`
        keychain items.
     */
    fileprivate var serviceName: String
    
    /**
        A tag to be added to crytographic keys so that a `KeyManager` instance can
        distinguish the keys that it created from others. This tag is added to
        `kSecAttrApplicationTag` attribute of `kSecClassKey` keychain items along
        with the key name. The tag is essentially an alternative to using the service
        name since `KSecAttrService` is not available for `kSecClassKey` keychain
        items.
     */
    fileprivate var keyTag: String

    public fileprivate(set) var namespace: String = ""
    
    /**
        AES key size in bits.
     */
    fileprivate var keySizeAES: Int = Constants.defaultKeySizeAES

    /**
        AES block size in bits.
     */
    fileprivate var blockSizeAES: Int = Constants.defaultBlockSizeAES

    /**
        RSA key size in bits.
     */
    fileprivate var keySizeRSA: Int = Constants.defaultKeySizeRSA
    
    /**
        Default initialization vector used for symmetric crypto.
     */
    fileprivate let defaultIV: Data
    
    /**
        Intializes a new `KeyManagerImpl` instance with the specified service name, namespace and key sizes.
     
        - Parameters:
            - serviceName: Service name to be associated with keys created by this `KeyManager`.
            - namespace: Namespace to use for the key name. If a namespace is specified then unique
                identifier for each key will be`"<namespace>.<keyName>"`. Namespace cannot be an
                empty string.
            - keySizeAES: AES key size. Default is 256 bits.
            - keySizeRSA: RSA key size. Default is 2048 bits.
     
        - Returns: A new initialized `KeyManagerImpl` instance.
     */
    public init(serviceName: String, keyTag: String, namespace: String, keySizeAES: Int = Constants.defaultKeySizeAES, blockSizeAES: Int = Constants.defaultBlockSizeAES, keySizeRSA: Int = Constants.defaultKeySizeRSA) {
        self.namespace = namespace
        self.serviceName = serviceName
        self.keySizeAES = keySizeAES
        self.blockSizeAES = blockSizeAES
        self.keySizeRSA = keySizeRSA
        self.keyTag = keyTag
        self.defaultIV = Data(count: self.blockSizeAES)
    }
    
    fileprivate func getKeyTypeFromSecAttributes(_ keyAttributes: [String: AnyObject]) -> KeyType {
        var type: KeyType = .unknown
        
        if let secClass = keyAttributes[Constants.secClass] as? String {
            if secClass == Constants.secClassGenericPassword {
                type = .password
            } else if secClass == Constants.secClassKey, let keyClass = keyAttributes[Constants.secAttrKeyClass] as? Int {
                if String(keyClass) == Constants.secAttrKeyClassPrivate {
                    type = .privateKey
                } else if String(keyClass) == Constants.secAttrKeyClassPublic {
                    type = .publicKey
                } else if String(keyClass) == Constants.secAttrKeyClassSymmetric {
                    type = .symmetricKey
                }
            }
        }
        
        return type
    }
    
    fileprivate func getKeyIdFromSecAttributes(_ keyAttributes: [String: AnyObject], type: KeyType = .unknown) -> String? {
        var keyId: String?
        
        var type = type
        if type == .unknown {
            // If type was not specified then try to determine the type from the
            // key attributes.
            type = getKeyTypeFromSecAttributes(keyAttributes)
        }
        
        switch type {
        case .password:
            // For passwords, the unique key ID is stored in "account" attribute.
            if let account = keyAttributes[Constants.secAttrAccount] as? Data {
                keyId = String(data: account, encoding: String.Encoding.utf8)
            }
        case .privateKey, .publicKey, .symmetricKey:
            // For cryptographic keys, the unique key ID is stored as a tag.
            if let tag = keyAttributes[Constants.secAttrApplicationTag] as? Data {
                keyId = String(data: tag, encoding: String.Encoding.utf8)
            }
        default:
            break
        }
        
        return keyId
    }
    
    fileprivate func getKeyNameFromAttributes(_ keyAttributes: [String: AnyObject], type: KeyType = .unknown) -> String? {
        guard let keyId = getKeyIdFromSecAttributes(keyAttributes, type: type) else {
            return nil
        }
        
        var name: String?
        
        var type = type
        if type == .unknown {
            // If type was not specified then try to determine the type from the
            // key attributes.
            type = getKeyTypeFromSecAttributes(keyAttributes)
        }
        
        // Strip any namespace or key tag related prefix from the key ID to obtain
        // the key name.
        let prefix = createKeyIdPrefix(type)
        if prefix.isEmpty {
            name = keyId
        } else {
            if keyId.hasPrefix(prefix) {
                name = String(keyId["\(prefix).".endIndex...])
            }
        }
        
        return name
    }

    fileprivate func isExportable(_ keyAttributes: [String: AnyObject]) -> Bool {
        var isExportable = true
        if let label = keyAttributes[Constants.secAttrLabel] as? String {
            let tags = label.split{$0 == ","}.map(String.init)
            if tags.contains(Constants.keyLabelNotExportable) {
                isExportable = false
            }
        }
        return isExportable
    }
    
    fileprivate func createKeyIdPrefix(_ type: KeyType) -> String {
        var prefix = self.namespace;
        
        switch type {
        case .privateKey:
            prefix = "\(Constants.keyNamePrefixPrivateKey)\(prefix.isEmpty ? "" : ".")\(prefix)"
        case .publicKey:
            prefix = "\(Constants.keyNamePrefixPublicKey)\(prefix.isEmpty ? "" : ".")\(prefix)"
        default:
            break
        }
        
        if !self.keyTag.isEmpty && type != .password {
            prefix = "\(self.keyTag)\(prefix.isEmpty ? "" : ".")\(prefix)"
        }
        
        return prefix
    }
    
    fileprivate func createKeyId(_ name: String, type: KeyType) throws -> Data {
        guard !name.isEmpty else {
            throw KeyManagerError.invalidKeyName
        }
        
        let keyId = "\(createKeyIdPrefix(type)).\(name)"
        
        // Any String can be encoded into UTF-8 so it's safe to force unwrap here.
        let data = keyId.data(using: String.Encoding.utf8)!
        
        return data
    }
    
    fileprivate func createKeySearchDictionary(_ keyId: Data, type: KeyType, returnDataType: ReturnDataType = .data) throws -> [String: AnyObject]  {
        var dictionary: [String: AnyObject] = [Constants.secAttrSynchronizable: Constants.secAttrSynchronizableAny as AnyObject]
        
        switch type {
        case .password:
            dictionary[Constants.secClass] = Constants.secClassGenericPassword as AnyObject?
            dictionary[Constants.secAttrGeneric] = keyId as AnyObject?
            dictionary[Constants.secAttrAccount] = keyId as AnyObject?
            dictionary[Constants.secAttrService] = self.serviceName as AnyObject?
        case .privateKey:
            dictionary[Constants.secClass] = Constants.secClassKey as AnyObject?
            dictionary[Constants.secAttrApplicationTag] = keyId as AnyObject?
            dictionary[Constants.secAttrKeyType] = Constants.secAttrKeyTypeRSA as AnyObject?
            dictionary[Constants.secAttrKeyClass] = Constants.secAttrKeyClassPrivate as AnyObject?
        case .publicKey:
            dictionary[Constants.secClass] = Constants.secClassKey as AnyObject?
            dictionary[Constants.secAttrApplicationTag] = keyId as AnyObject?
            dictionary[Constants.secAttrKeyType] = Constants.secAttrKeyTypeRSA as AnyObject?
            dictionary[Constants.secAttrKeyClass] = Constants.secAttrKeyClassPublic as AnyObject?
        case .symmetricKey:
            dictionary[Constants.secClass] = Constants.secClassKey as AnyObject?
            dictionary[Constants.secAttrApplicationTag] = keyId as AnyObject?
            dictionary[Constants.secAttrKeyClass] = Constants.secAttrKeyClassSymmetric as AnyObject?
        default:
            throw KeyManagerError.invalidKeyType
        }
        
        switch returnDataType {
        case .attributes:
            dictionary[Constants.secReturnAttributes] = true as AnyObject?
        case .reference:
            dictionary[Constants.secReturnRef] = true as AnyObject?
        case .data:
            dictionary[Constants.secReturnData] = true as AnyObject?
        }
        
        return dictionary
    }
    
    fileprivate func createKeySearchDictionary(_ name: String, type: KeyType, returnDataType: ReturnDataType = .data) throws -> [String: AnyObject]  {
        let keyId = try createKeyId(name, type: type)
        return try createKeySearchDictionary(keyId, type: type, returnDataType: returnDataType)
    }
    
    fileprivate func secAttributesToKeyManagerAttributes(_ secAttributes: [String: AnyObject]) -> KeyAttributeSet? {
        let type = getKeyTypeFromSecAttributes(secAttributes)
        
        guard let keyId = getKeyIdFromSecAttributes(secAttributes, type: type), let keyName = getKeyNameFromAttributes(secAttributes, type: type) else {
            return nil
        }

        var attributes = KeyAttributeSet()
        attributes.addAttribute(.version, value: .intValue(Constants.keyVersion))
        attributes.addAttribute(.namespace, value: .stringValue(self.namespace))
        attributes.addAttribute(.type, value: .keyTypeValue(type))
        attributes.addAttribute(.id, value: .stringValue(keyId))
        attributes.addAttribute(.name, value: .stringValue(keyName))
        
        if let synchronizable = secAttributes[Constants.secAttrSynchronizable] as? Bool {
            attributes.addAttribute(.synchronizable, value: .boolValue(synchronizable))
        } else {
            attributes.addAttribute(.synchronizable, value: .boolValue(false))
        }
        
        attributes.addAttribute(.exportable, value: .boolValue(isExportable(secAttributes)))
        
        return attributes
    }
    
    fileprivate func getSecAttributesForAllKeys() throws -> [[String: AnyObject]] {
        var attributesArray: [[String: AnyObject]] = []
        
        let secItemClasses = [Constants.secClassGenericPassword, Constants.secClassKey]
        var searchDictionary: [String: AnyObject] = [Constants.secReturnAttributes: true as AnyObject, Constants.secMatchLimit: Constants.secMatchLimitAll as AnyObject, Constants.secAttrSynchronizable: Constants.secAttrSynchronizableAny as AnyObject]
        for secItemClass in secItemClasses {
            searchDictionary[Constants.secClass] = secItemClass as AnyObject?
            
            if secItemClass == Constants.secClassGenericPassword && !self.serviceName.isEmpty {
                // Only include the keys that were created by this KeyManager. Passwords should
                // have the service name set in kSecAttrService attribute.
                searchDictionary[Constants.secAttrService] = self.serviceName as AnyObject?
            } else {
                searchDictionary.removeValue(forKey: Constants.secAttrService)
            }
            
            var result: AnyObject?
            let status = SecItemCopyMatching(searchDictionary as CFDictionary, &result)
            
            switch status {
            case errSecSuccess:
                if let array = result as? [[String: AnyObject]] {
                    for var element in array {
                        element[Constants.secClass] = secItemClass as AnyObject?
                        let type = getKeyTypeFromSecAttributes(element)
                        switch type {
                        case .privateKey, .publicKey, .symmetricKey:
                            // Only include the keys that were created by this KeyManager. Keys should have
                            // a tag that has the configured key tag + namespace as prefix.
                            if let data = element[Constants.secAttrApplicationTag] as? Data, let tag = String(data: data, encoding: .utf8) {
                                let prefix = createKeyIdPrefix(type)
                                if !prefix.isEmpty && tag.hasPrefix("\(prefix).") {
                                    attributesArray.append(element)
                                }
                            }
                        case .password:
                            // Only include the passwords that were created by this KeyManager. Passwords should
                            // have an account attribute that has the configured namespace as prefix.
                            if let data = element[Constants.secAttrAccount] as? Data, let account = String(data: data, encoding: .utf8) {
                                let prefix = createKeyIdPrefix(type)
                                if !prefix.isEmpty && account.hasPrefix("\(prefix).") {
                                    attributesArray.append(element)
                                }
                            }
                        default:
                            break
                        }
                    }
                }
            case errSecItemNotFound:
                // Safe to ignore this status since it indicates that no keychain item matched the search criteria.
                break
            default:
                throw KeyManagerError.unhandledUnderlyingSecAPIError(code: status)
            }
        }
        
        return attributesArray
    }
    
    fileprivate func getKeyData(_ searchDictionary: [String: AnyObject]) throws -> Data? {
        var keyData: Data?
        
        // This creates a mutable copy while retaining the parameter name.
        var searchDictionary = searchDictionary
        searchDictionary[Constants.secMatchLimit] = Constants.secMatchLimitOne as AnyObject?
        
        var result: AnyObject?
        let status = SecItemCopyMatching(searchDictionary as CFDictionary, &result)
        
        switch status {
        case errSecSuccess:
            keyData = result as? Data
        case errSecItemNotFound:
            break
        default:
            throw KeyManagerError.unhandledUnderlyingSecAPIError(code: status)
        }
        
        return keyData
    }
 
    fileprivate func deleteKeys(_ searchDictionary: [String: AnyObject]) throws {
        let status = SecItemDelete(searchDictionary as CFDictionary)
        switch status {
        case errSecSuccess, errSecItemNotFound:
            break
        default:
            throw KeyManagerError.unhandledUnderlyingSecAPIError(code: status)
        }
    }

    /**
        Resets the secure store holding the keys. This removes every key regardless
        of whether or not the key was created by `KeyManager` so it should only
        be used for debugging.
     
        - Throws:
            `KeyManagerError.UnhandledUnderlyingSecAPIError`,
     */
    public func resetSecureKeyStore() throws {
        // Only enabling the following code for iOS because on MacOS it will remove
        // all user accessible keys including those keys created by other apps.
        #if os(iOS)
            
        let secItemClasses = [Constants.secClassGenericPassword,
                              Constants.secClassKey,
                              Constants.secClassInternetPassword,
                              Constants.secClassIdentity,
                              Constants.secClassCertificate,]
        var searchDictionary: [String: AnyObject] = [Constants.secAttrSynchronizable: Constants.secAttrSynchronizableAny as AnyObject]
        for secItemClass in secItemClasses {
            searchDictionary[Constants.secClass] = secItemClass as AnyObject?
            
            let status = SecItemDelete(searchDictionary as CFDictionary)
            
            switch status {
            case errSecSuccess, errSecItemNotFound:
                break
            default:
                throw KeyManagerError.unhandledUnderlyingSecAPIError(code: status)
            }
        }
            
        #endif
    }
    
}

// MARK: KeyManager

extension KeyManagerImpl: KeyManager {
    
    public func addPassword(_ password: Data, name: String) throws {
        try addPassword(password, name: name, isSynchronizable: false, isExportable: true)
    }
    
    public func addPassword(_ password: Data, name: String, isSynchronizable: Bool, isExportable: Bool) throws {
        var dictionary = try createKeySearchDictionary(name, type: .password)
        dictionary[Constants.secAttrLabel] = isExportable ? Constants.keyLabelExportable as AnyObject : Constants.keyLabelNotExportable as AnyObject
        
        // The key needs to be accessible even if the device is locked in order to support
        // background operations. kSecAttrAccessibleAfterFirstUnlock allows access to the key
        // all the time as long as the device has been unlocked at least once. This is as
        // per Apple recommendation since kSecAttrAccessibleAlways is now deprecated.
        dictionary[Constants.secAttrAccessible] = Constants.secAttrAccessibleAfterFirstUnlock as AnyObject?
        
        dictionary[Constants.secValueData] = password as AnyObject?
        
        if isSynchronizable {
            dictionary[Constants.secAttrSynchronizable] = true as AnyObject?
        }
        
        let status = SecItemAdd(dictionary as CFDictionary, nil)
        switch status {
        case errSecSuccess:
            break
        case errSecDuplicateItem:
            throw KeyManagerError.duplicateKey
        default:
            throw KeyManagerError.unhandledUnderlyingSecAPIError(code: status)
        }
    }
    
    public func getPassword(_ name: String) throws -> Data? {
        return try getKeyData(createKeySearchDictionary(name, type: .password))
    }
    
    public func deletePassword(_ name: String) throws {
        let dictionary = try createKeySearchDictionary(name, type: .password)
        try deleteKeys(dictionary)
    }
    
    public func updatePassword(_ password: Data, name: String) throws {
        var searchDictionary = try createKeySearchDictionary(name, type: .password)
        // Keychain API does not like the return data attribute in the search
        // dictionary when updating a key. More often we will need the return
        // data specified in the dictionary so we will keep the default search
        // dictionary as it is but if we find that more functions are requiring
        // it to be omitted then we can revisit.
        searchDictionary.removeValue(forKey: Constants.secReturnData)
        let updateDictionary = [Constants.secValueData: password]
        let status = SecItemUpdate(searchDictionary as CFDictionary, updateDictionary as CFDictionary)
        switch status {
        case errSecSuccess:
            break
        case errSecItemNotFound:
            throw KeyManagerError.keyNotFound
        default:
            throw KeyManagerError.unhandledUnderlyingSecAPIError(code: status)
        }
    }
    
    public func getKeyAttributes(_ name: String, type: KeyType) throws -> KeyAttributeSet? {
        var searchDictionary = try createKeySearchDictionary(name, type: type, returnDataType: .attributes)
        searchDictionary[Constants.secMatchLimit] = Constants.secMatchLimitOne as AnyObject?
        
        var result: AnyObject?
        let status = SecItemCopyMatching(searchDictionary as CFDictionary, &result)
        
        switch status {
        case errSecSuccess:
            break
        case errSecItemNotFound:
            return nil
        default:
            throw KeyManagerError.unhandledUnderlyingSecAPIError(code: status)
        }
        
        guard var dictionary = result as? [String: AnyObject] else {
            // If the result is not a dictionary of key attributes despite of success
            // status then there's something seriously wrong.
            throw KeyManagerError.fatalError
        }

        // Apple's keychain API does not return the key class in the result set so we
        // need to set it manually.
        dictionary[Constants.secClass] = searchDictionary[Constants.secClass]
        return secAttributesToKeyManagerAttributes(dictionary)
    }
    
    public func updateKeyAttributes(_ attributes: KeyAttributeSet, name: String, type: KeyType) throws
    {
        guard attributes.count > 0 else {
            return
        }
        
        guard attributes.isMutable() else {
            throw KeyManagerError.keyAttributeNotMutable
        }
        
        var searchDictionary = try createKeySearchDictionary(name, type: type)
        // Keychain API does not like the return data attribute in the search
        // dictionary when updating a key. More often we will need the return
        // data specified in the dictionary so we will keep the default search
        // dictionary as it is but if we find that more functions are requiring
        // it to be omitted then we can revisit.
        searchDictionary.removeValue(forKey: Constants.secReturnData)
        
        var updateDictionary: [String: AnyObject] = [:]
        for attribute in attributes.attributes {
            switch attribute.name {
            case .synchronizable:
                switch attribute.value {
                case .boolValue(let value):
                    updateDictionary[Constants.secAttrSynchronizable] = value as AnyObject?
                default:
                    break
                }
            case .exportable:
                switch attribute.value {
                case .boolValue(let value):
                    updateDictionary[Constants.secAttrLabel] = value ? Constants.keyLabelExportable as AnyObject : Constants.keyLabelNotExportable as AnyObject
                default:
                    break
                }
            case .id:
                switch attribute.value {
                case .stringValue(let value):
                    if let data = value.data(using: String.Encoding.utf8) {
                        switch type {
                        case .password:
                            updateDictionary[Constants.secAttrGeneric] = data as AnyObject?
                            updateDictionary[Constants.secAttrAccount] = data as AnyObject?
                        case .privateKey, .publicKey, .symmetricKey:
                            updateDictionary[Constants.secAttrApplicationTag] = data as AnyObject?
                        default:
                            break
                        }
                    }
                default:
                    break
                }
            default:
                throw KeyManagerError.keyAttributeNotMutable
            }
        }
        
        let status = SecItemUpdate(searchDictionary as CFDictionary, updateDictionary as CFDictionary)
        switch status {
        case errSecSuccess:
            break
        case errSecItemNotFound:
            throw KeyManagerError.keyNotFound
        default:
            throw KeyManagerError.unhandledUnderlyingSecAPIError(code: status)
        }
    }
    
    public func generateSymmetricKey(_ name: String) throws {
        try generateSymmetricKey(name, isExportable: true)
    }
    
    public func generateSymmetricKey(_ name: String, isExportable: Bool) throws {
        let keyData = try createRandomData(self.keySizeAES >> 3)
        try addSymmetricKey(keyData, name: name, isExportable: isExportable)
    }
    
    public func addSymmetricKey(_ key: Data, name: String) throws {
        try addSymmetricKey(key, name: name, isExportable: true)
    }
    
    public func addSymmetricKey(_ key: Data, name: String, isExportable: Bool) throws {
        var dictionary = try createKeySearchDictionary(name, type: .symmetricKey)
        dictionary[Constants.secAttrLabel] = isExportable ? Constants.keyLabelExportable as AnyObject : Constants.keyLabelNotExportable as AnyObject
        
        // The key needs to be accessible even if the device is locked in order to support
        // background operations. kSecAttrAccessibleAfterFirstUnlock allows access to the key
        // all the time as long as the device has been unlocked at least once. This is as
        // per Apple recommendation since kSecAttrAccessibleAlways is now deprecated.
        dictionary[Constants.secAttrAccessible] = Constants.secAttrAccessibleAfterFirstUnlock as AnyObject?
        
        dictionary[Constants.secValueData] = key as AnyObject?
        dictionary[Constants.secAttrKeyType] = Constants.secAttrKeyTypeAES as AnyObject?
        dictionary[Constants.secAttrCanEncrypt] = true as AnyObject?
        dictionary[Constants.secAttrCanDecrypt] = true as AnyObject?
        dictionary[Constants.secAttrCanDerive] = false as AnyObject?
        dictionary[Constants.secAttrCanSign] = false as AnyObject?
        dictionary[Constants.secAttrCanVerify] = false as AnyObject?
        dictionary[Constants.secAttrCanWrap] = false as AnyObject?
        dictionary[Constants.secAttrCanUnwrap] = false as AnyObject?
        dictionary[Constants.secAttrKeySizeInBits] = self.keySizeAES as AnyObject?
        dictionary[Constants.secAttrEffectiveKeySize] = self.keySizeAES as AnyObject?
        dictionary[Constants.secAttrIsPermanent] = true as AnyObject?
        
        let status = SecItemAdd(dictionary as CFDictionary, nil)
        switch status {
        case errSecSuccess:
            break
        case errSecDuplicateItem:
            throw KeyManagerError.duplicateKey
        default:
            throw KeyManagerError.unhandledUnderlyingSecAPIError(code: status)
        }
    }
    
    public func getSymmetricKey(_ name: String) throws -> Data? {
        return try getKeyData(createKeySearchDictionary(name, type: .symmetricKey))
    }
    
    public func deleteSymmetricKey(_ name: String) throws {
        let dictionary = try createKeySearchDictionary(name, type: .symmetricKey)
        try deleteKeys(dictionary)
    }
    
    public func encryptWithSymmetricKey(_ name: String, data: Data) throws -> Data {
        return try encryptWithSymmetricKey(name, data: data, iv: self.defaultIV)
    }
    
    public func encryptWithSymmetricKey(_ name: String, data: Data, iv: Data) throws -> Data {
        var encryptedData: Data
        
        if let keyData = try getSymmetricKey(name) {
            encryptedData = try encryptWithSymmetricKey(keyData, data: data, iv: iv)
        } else {
            throw KeyManagerError.keyNotFound
        }
        
        return encryptedData
    }
    
    public func encryptWithSymmetricKey(_ key: Data, data: Data) throws -> Data {
        return try encryptWithSymmetricKey(key, data: data, iv: self.defaultIV)
    }
    
    public func encryptWithSymmetricKey(_ key: Data, data: Data, iv: Data) throws -> Data {
        guard iv.count == kCCBlockSizeAES128 else {
            throw KeyManagerError.invalidInitializationVector
        }
        
        var buffer = [UInt8](repeating: 0,  count: Int(data.count) + kCCBlockSizeAES128)
        var movedBytes: size_t = 0

        let status: CCCryptorStatus = try key.withUnsafeBytes {
            guard let keyBytes = $0.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                throw KeyManagerError.fatalError
            }
            return try iv.withUnsafeBytes {
                guard let ivBytes = $0.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                    throw KeyManagerError.fatalError
                }
                return try data.withUnsafeBytes {
                    guard let dataBytes = $0.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                        throw KeyManagerError.fatalError
                    }

                    return CCCrypt(CCOperation(kCCEncrypt),
                            CCAlgorithm(kCCAlgorithmAES),
                            CCOptions(kCCOptionPKCS7Padding),
                            keyBytes,
                            key.count,
                            ivBytes,
                            dataBytes,
                            data.count,
                            &buffer,
                            buffer.count,
                            &movedBytes
                    )
                }
            }
        }

        if status != Int32(kCCSuccess) {
            throw KeyManagerError.unhandledUnderlyingSecAPIError(code: status)
        }
        
        return Data(bytes: buffer, count: movedBytes)
    }
    
    public func decryptWithSymmetricKey(_ name: String, data: Data) throws -> Data {
        return try decryptWithSymmetricKey(name, data: data, iv: self.defaultIV)
    }
    
    public func decryptWithSymmetricKey(_ name: String, data: Data, iv: Data) throws -> Data {
        var decryptedData: Data
        
        if let keyData = try getSymmetricKey(name) {
            try decryptedData = decryptWithSymmetricKey(keyData, data: data, iv: iv)
        } else {
            throw KeyManagerError.keyNotFound
        }
        
        return decryptedData
    }
    
    public func decryptWithSymmetricKey(_ key: Data, data: Data) throws -> Data {
        return try decryptWithSymmetricKey(key, data: data, iv: self.defaultIV)
    }
    
    public func decryptWithSymmetricKey(_ key: Data, data: Data, iv: Data) throws -> Data {
        guard iv.count == kCCBlockSizeAES128 else {
            throw KeyManagerError.invalidInitializationVector
        }
        
        var buffer = [UInt8](repeating: 0,  count: Int(data.count) + kCCBlockSizeAES128)
        var movedBytes: size_t = 0

        let status: CCCryptorStatus = try key.withUnsafeBytes {
            guard let keyBytes = $0.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                throw KeyManagerError.fatalError
            }
            return try iv.withUnsafeBytes {
                guard let ivBytes = $0.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                    throw KeyManagerError.fatalError
                }
                return try data.withUnsafeBytes {
                    guard let dataBytes = $0.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                        throw KeyManagerError.fatalError
                    }

                    return CCCrypt(CCOperation(kCCDecrypt),
                                   CCAlgorithm(kCCAlgorithmAES),
                                   CCOptions(kCCOptionPKCS7Padding),
                                   keyBytes,
                                   key.count,
                                   ivBytes,
                                   dataBytes,
                                   data.count,
                                   &buffer,
                                   buffer.count,
                                   &movedBytes
                    )
                }
            }
        }

        
        if status != Int32(kCCSuccess) {
            throw KeyManagerError.unhandledUnderlyingSecAPIError(code: status)
        }
        
        return Data(bytes: buffer, count: movedBytes)
    }
    
    public func createSymmetricKeyFromPassword(_ password: String) throws -> (key: Data, salt: Data, rounds: UInt32) {
        guard let passwordData = password.data(using: String.Encoding.utf8) else {
            throw KeyManagerError.fatalError
        }
        
        let salt = try createRandomData(self.keySizeAES >> 3)
        
        // Determine the number of PRF rounds that can be used within 100 ms in the
        // current platform.
        let rounds = CCCalibratePBKDF(CCPBKDFAlgorithm(kCCPBKDF2), passwordData.count, salt.count, CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256), self.keySizeAES >> 3, UInt32(100))
        
        let keyData = try createSymmetricKeyFromPassword(password, salt: salt, rounds: rounds)
        
        return (keyData, salt, rounds)
    }
    
    public func createSymmetricKeyFromPassword(_ password: String, salt: Data, rounds: UInt32) throws -> Data {
        guard let passwordData = password.data(using: String.Encoding.utf8) else {
            throw KeyManagerError.fatalError
        }
        
        var data = [UInt8](repeating: 0,  count: self.keySizeAES >> 3)
        // Derive a cryptographic key from the password, salt and required rounds of pseudo random function applied.
        let status: CCCryptorStatus = try passwordData.withUnsafeBytes {
            guard let passwordBytes = $0.baseAddress?.assumingMemoryBound(to: Int8.self) else {
                throw KeyManagerError.fatalError
            }
            return try salt.withUnsafeBytes {
                guard let saltBytes = $0.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                    throw KeyManagerError.fatalError
                }

                return CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2),
                                     passwordBytes,
                                     passwordData.count,
                                     saltBytes,
                                     salt.count,
                                     CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                                     rounds,
                                     &data,
                                     data.count
                )
            }
        }

        if status != Int32(kCCSuccess) {
            throw KeyManagerError.unhandledUnderlyingSecAPIError(code: status)
        }

        return Data(data)
    }
    
    public func createRandomData(_ size: Int) throws -> Data {
        var data = [UInt8](repeating: 0,  count: Int(size))
        
        let status = SecRandomCopyBytes(kSecRandomDefault, data.count, &data)
        
        if status != noErr {
            throw KeyManagerError.unhandledUnderlyingSecAPIError(code: status)
        }
        
        return Data(data)
    }
    
    public func generateHash(_ data: Data) throws -> Data {
        var buffer = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
        try data.withUnsafeBytes {
            guard let bytes = $0.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                throw KeyManagerError.fatalError
            }

            _ = CC_SHA256(bytes, CC_LONG(data.count), &buffer)
        }
        
        return Data(buffer)
    }
    
    public func generateKeyPair(_ name: String) throws {
        try generateKeyPair(name, isExportable: true)
    }
    
    public func generateKeyPair(_ name: String, isExportable: Bool) throws {
        var keyPairAttributes: [String: AnyObject] = [Constants.secAttrKeyType: Constants.secAttrKeyTypeRSA as AnyObject,
                                                      Constants.secAttrKeySizeInBits: self.keySizeRSA as AnyObject,
                                                      Constants.secAttrIsPermanent: true as AnyObject]
        
        // The key needs to be accessible even if the device is locked in order to support
        // background operations. kSecAttrAccessibleAfterFirstUnlock allows access to the key
        // all the time as long as the device has been unlocked at least once. This is as
        // per Apple recommendation since kSecAttrAccessibleAlways is now deprecated.
        keyPairAttributes[Constants.secAttrAccessible] = Constants.secAttrAccessibleAfterFirstUnlock as AnyObject?
        
        var privateKeyAttributes = try createKeySearchDictionary(name, type: .privateKey, returnDataType: .reference)
        privateKeyAttributes[Constants.secAttrLabel] = isExportable ? Constants.keyLabelExportable as AnyObject : Constants.keyLabelNotExportable as AnyObject
        keyPairAttributes[Constants.secPrivateKeyAttrs] = privateKeyAttributes as AnyObject?
            
        var publicKeyAttributes = try createKeySearchDictionary(name, type: .publicKey, returnDataType: .reference)
        publicKeyAttributes[Constants.secAttrLabel] = isExportable ? Constants.keyLabelExportable as AnyObject : Constants.keyLabelNotExportable as AnyObject
        keyPairAttributes[Constants.secPublicKeyAttrs] = publicKeyAttributes as AnyObject?
        
        var publicKey: SecKey?
        var privateKey: SecKey?
        let status = SecKeyGeneratePair(keyPairAttributes as CFDictionary, &publicKey, &privateKey)
        
        switch status {
        case errSecSuccess:
            break
        case errSecDuplicateItem:
            throw KeyManagerError.duplicateKey
        default:
            throw KeyManagerError.unhandledUnderlyingSecAPIError(code: status)
        }
    }
    
    public func generateKeyId() throws -> String {
        var keyId: String
        var attempts = 0
        
        repeat {
            keyId = UUID().uuidString
            
            if try getPrivateKey(keyId) == nil {
                break
            }
            
            attempts += 1
        } while attempts < Constants.uuidGenerationLimit
        
        guard attempts < Constants.uuidGenerationLimit else {
            throw KeyManagerError.uuidGenerationLimitExceeded
        }
        
        return keyId
    }
    
    public func addPrivateKey(_ key: Data, name: String) throws {
        try addPrivateKey(key, name: name, isExportable: true)
    }
    
    public func addPrivateKey(_ key: Data, name: String, isExportable: Bool) throws {
        var dictionary = try createKeySearchDictionary(name, type: .privateKey)
        dictionary[Constants.secAttrLabel] = isExportable ? Constants.keyLabelExportable as AnyObject : Constants.keyLabelNotExportable as AnyObject
        
        // The key needs to be accessible even if the device is locked in order to support
        // background operations. kSecAttrAccessibleAfterFirstUnlock allows access to the key
        // all the time as long as the device has been unlocked at least once. This is as
        // per Apple recommendation since kSecAttrAccessibleAlways is now deprecated.
        dictionary[Constants.secAttrAccessible] = Constants.secAttrAccessibleAfterFirstUnlock as AnyObject?
        
        dictionary[Constants.secValueData] = key as AnyObject?
        dictionary[Constants.secAttrKeyType] = Constants.secAttrKeyTypeRSA as AnyObject?
        dictionary[Constants.secAttrCanEncrypt] = true as AnyObject?
        dictionary[Constants.secAttrCanDecrypt] = true as AnyObject?
        dictionary[Constants.secAttrCanDerive] = false as AnyObject?
        dictionary[Constants.secAttrCanSign] = true as AnyObject?
        dictionary[Constants.secAttrCanVerify] = true as AnyObject?
        dictionary[Constants.secAttrCanWrap] = true as AnyObject?
        dictionary[Constants.secAttrCanUnwrap] = false as AnyObject?
        dictionary[Constants.secAttrKeySizeInBits] = self.keySizeRSA as AnyObject?
        dictionary[Constants.secAttrEffectiveKeySize] = self.keySizeRSA as AnyObject?
        dictionary[Constants.secAttrIsPermanent] = true as AnyObject?
        
        let status = SecItemAdd(dictionary as CFDictionary, nil)
        switch status {
        case errSecSuccess:
            break
        case errSecDuplicateItem:
            throw KeyManagerError.duplicateKey
        default:
            throw KeyManagerError.unhandledUnderlyingSecAPIError(code: status)
        }
    }
    
    public func getPrivateKey(_ name: String) throws -> Data? {
        return try getKeyData(createKeySearchDictionary(name, type: .privateKey))
    }
    
    public func addPublicKey(_ key: Data, name: String) throws {
        try self.addPublicKey(key, name: name, isExportable: true)
    }
    
    public func addPublicKey(_ key: Data, name: String, isExportable: Bool) throws {
        var dictionary = try createKeySearchDictionary(name, type: .publicKey)
        dictionary[Constants.secAttrLabel] = isExportable ? Constants.keyLabelExportable as AnyObject : Constants.keyLabelNotExportable as AnyObject
        
        // The key needs to be accessible even if the device is locked in order to support
        // background operations. kSecAttrAccessibleAfterFirstUnlock allows access to the key
        // all the time as long as the device has been unlocked at least once. This is as
        // per Apple recommendation since kSecAttrAccessibleAlways is now deprecated.
        dictionary[Constants.secAttrAccessible] = Constants.secAttrAccessibleAfterFirstUnlock as AnyObject?
        
        dictionary[Constants.secValueData] = key as AnyObject?
        dictionary[Constants.secAttrKeyType] = Constants.secAttrKeyTypeRSA as AnyObject?
        dictionary[Constants.secAttrCanEncrypt] = true as AnyObject?
        dictionary[Constants.secAttrCanDecrypt] = false as AnyObject?
        dictionary[Constants.secAttrCanDerive] = false as AnyObject?
        dictionary[Constants.secAttrCanSign] = false as AnyObject?
        dictionary[Constants.secAttrCanVerify] = true as AnyObject?
        dictionary[Constants.secAttrCanWrap] = true as AnyObject?
        dictionary[Constants.secAttrCanUnwrap] = false as AnyObject?
        dictionary[Constants.secAttrKeySizeInBits] = self.keySizeRSA as AnyObject?
        dictionary[Constants.secAttrEffectiveKeySize] = self.keySizeRSA as AnyObject?
        dictionary[Constants.secAttrIsPermanent] = true as AnyObject?
        
        let status = SecItemAdd(dictionary as CFDictionary, nil)
        switch status {
        case errSecSuccess:
            break
        case errSecDuplicateItem:
            throw KeyManagerError.duplicateKey
        default:
            throw KeyManagerError.unhandledUnderlyingSecAPIError(code: status)
        }
    }
    
    public func getPublicKey(_ name: String) throws -> Data? {
        return try getKeyData(createKeySearchDictionary(name, type: .publicKey))
    }
    
    public func deleteKeyPair(_ name: String) throws {
        var dictionary = try createKeySearchDictionary(name, type: .privateKey)
        try deleteKeys(dictionary)

        dictionary = try createKeySearchDictionary(name, type: .publicKey)
        try deleteKeys(dictionary)
    }
    
    public func generateSignatureWithPrivateKey(_ name: String, data: Data) throws -> Data {
        var signature: Data
        
        let searchDictionary = try createKeySearchDictionary(name, type: .privateKey, returnDataType: .reference)
        
        var result: AnyObject?
        var status = SecItemCopyMatching(searchDictionary as CFDictionary, &result)
        
        switch status {
        case errSecSuccess:
            // Conditional downcast to SecKey will always succeed as it is
            // CF type. It is safe to force downcasting and it is only
            // way to make the compiler happy.
            let key = result as! SecKey
            let hash = try generateHash(data)
            
            var buffer = [UInt8](repeating: 0,  count: SecKeyGetBlockSize(key))
            var bytesWritten = buffer.count
            
            #if os(iOS)

            status = try hash.withUnsafeBytes {
                guard let bytes = $0.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                    throw KeyManagerError.fatalError
                }

                return SecKeyRawSign(key,
                              SecPadding.PKCS1SHA256,
                              bytes,
                              hash.count,
                              &buffer,
                              &bytesWritten
                )
            }
                
            #else
                
                //TODO: Use MacOS specific API here since SecKeyRawSign
                // is not available on Mac OS.
                
            #endif

            if status == noErr {
                signature = Data(bytes: buffer, count: bytesWritten)
            } else {
                throw KeyManagerError.unhandledUnderlyingSecAPIError(code: status)
            }
        case errSecItemNotFound:
            throw KeyManagerError.keyNotFound
        default:
            throw KeyManagerError.unhandledUnderlyingSecAPIError(code: status)
        }
        
        return signature
    }
    
    public func verifySignatureWithPublicKey(_ name: String, data: Data, signature: Data) throws -> Bool {
        var valid = false
        
        let searchDictionary = try createKeySearchDictionary(name, type: .publicKey, returnDataType: .reference)
        
        var result: AnyObject?
        var status = SecItemCopyMatching(searchDictionary as CFDictionary, &result)
        
        switch status {
        case errSecSuccess:
            // Conditional downcast to SecKey will always succeed as it is
            // CF type. It is safe to force downcasting and it is only
            // way to make the compiler happy.
            let key = result as! SecKey
            let hash = try generateHash(data)
            
            #if os(iOS)

            status = try hash.withUnsafeBytes {
                guard let hashBytes = $0.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                    throw KeyManagerError.fatalError
                }
                return try signature.withUnsafeBytes {
                    guard let signatureBytes = $0.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                        throw KeyManagerError.fatalError
                    }

                    return SecKeyRawVerify(key,
                                    SecPadding.PKCS1SHA256,
                                    hashBytes,
                                    hash.count,
                                    signatureBytes,
                                    signature.count
                    )
                }
            }
                
            #else
                
                //TODO: Use MacOS specific API here since SecKeyRawVerify
                // is not available on Mac OS.
                
            #endif
            
            if status == noErr {
                valid = true
            }
        case errSecItemNotFound:
            throw KeyManagerError.keyNotFound
        default:
            throw KeyManagerError.unhandledUnderlyingSecAPIError(code: status)
        }
        
        return valid
    }
    
    public func encryptWithPublicKey(_ name: String, data: Data, algorithm: PublicKeyEncryptionAlgorithm) throws -> Data {
        var encryptedData = Data()

        let searchDictionary = try createKeySearchDictionary(name, type: .publicKey, returnDataType: .reference)
        
        var result: AnyObject?
        var status = SecItemCopyMatching(searchDictionary as CFDictionary, &result)


        
        switch status {
        case errSecSuccess:
            // Conditional downcast to SecKey will always succeed as it is
            // CF type. It is safe to force downcasting and it is only
            // way to make the compiler happy.
            let key = result as! SecKey

            
            // Determine the block size which is proportional to the key size.
            let blockSize = SecKeyGetBlockSize(key)

            var buffer = [UInt8](repeating: 0,  count: blockSize)
            
            // When padding is used the encrypted data will be 11 bytes longer than the input
            // so the maximum length of data that can be encrypted is 11 bytes less than
            // the block size associated with the given key.
            let maxPlainTextLen = blockSize - 11
            
            // Total bytes encrypted.
            var bytesEncrypted = 0

            try data.withUnsafeBytes { [unowned key] in
                guard let bytes = $0.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                    throw KeyManagerError.fatalError
                }

                // Encrypt the data one block at a time.
                while bytesEncrypted < data.count {
                    let cursor = bytes.advanced(by: bytesEncrypted)
                    let bytesToEncrypt = maxPlainTextLen > data.count - bytesEncrypted ? data.count - bytesEncrypted : maxPlainTextLen
                    var bytesWritten = buffer.count
                    
                    #if os(iOS)
                        
                        let padding: SecPadding
                        switch algorithm {
                        case .rsaEncryptionOAEPSHA1:
                            padding = .OAEP
                        case .rsaEncryptionPKCS1:
                            padding = .PKCS1
                        }
                        
                        status = SecKeyEncrypt(key,
                                               padding,
                                               cursor,
                                               bytesToEncrypt,
                                               &buffer,
                                               &bytesWritten)
                        
                    #else
                        
                        //TODO: Use MacOS specific API here since SecKeyEncrypt
                        // is not available on Mac OS.
                        
                    #endif
                    
                    if status == noErr {
                        bytesEncrypted += bytesToEncrypt
                        encryptedData.append(buffer, count: bytesWritten)
                    } else {
                        throw KeyManagerError.unhandledUnderlyingSecAPIError(code: status)
                    }
                }
            }
        case errSecItemNotFound:
            throw KeyManagerError.keyNotFound
        default:
            throw KeyManagerError.unhandledUnderlyingSecAPIError(code: status)
        }
        
        return encryptedData as Data
    }
    
    public func decryptWithPrivateKey(_ name: String, data: Data, algorithm: PublicKeyEncryptionAlgorithm) throws -> Data {
        var decryptedData = Data()
        
        let searchDictionary = try createKeySearchDictionary(name, type: .privateKey, returnDataType: .reference)
        
        var result: AnyObject?
        var status = SecItemCopyMatching(searchDictionary as CFDictionary, &result)
        
        switch status {
        case errSecSuccess:
            // Conditional downcast to SecKey will always succeed as it is
            // CF type. It is safe to force downcasting and it is only
            // way to make the compiler happy.
            let key = result as! SecKey
            
            // Determine the block size which is proportional to the key size.
            let blockSize = SecKeyGetBlockSize(key)
            
            // The encrypted data length must be divisible by the block size.
            guard data.count % blockSize == 0 else {
                throw KeyManagerError.invalidCipherText
            }
            
            // When padding is used the encrypted data will be 11 bytes longer than the input
            // so the plaintext buffer can be 11 bytes less.
            var buffer = [UInt8](repeating: 0,  count: blockSize - 11)
            
            // Total bytes decrypted.
            var bytesDecrypted = 0
            
            try data.withUnsafeBytes {
                guard let bytes = $0.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                    throw KeyManagerError.fatalError
                }
                // Decrypt the data one block at a time.
                while bytesDecrypted < data.count {
                    let cursor = bytes.advanced(by: bytesDecrypted)
                    var bytesWritten = buffer.count
                    
                    #if os(iOS)
                        
                        let padding: SecPadding
                        switch algorithm {
                        case .rsaEncryptionOAEPSHA1:
                            padding = .OAEP
                        case .rsaEncryptionPKCS1:
                            padding = .PKCS1
                        }
                        
                        status = SecKeyDecrypt(key,
                                               padding,
                                               cursor,
                                               blockSize,
                                               &buffer,
                                               &bytesWritten)
                        
                    #else
                        
                        //TODO: Use MacOS specific API here since SecKeyEncrypt
                        // is not available on Mac OS.
                        
                    #endif
                    
                    if status == noErr {
                        bytesDecrypted += blockSize
                        decryptedData.append(buffer, count: bytesWritten)
                    } else {
                        throw KeyManagerError.unhandledUnderlyingSecAPIError(code: status)
                    }
                }
            }
        case errSecItemNotFound:
            throw KeyManagerError.keyNotFound
        default:
            throw KeyManagerError.unhandledUnderlyingSecAPIError(code: status)
        }
        
        return decryptedData
    }
    
    public func removeAllKeys() throws {
        let attributesArray = try getSecAttributesForAllKeys()
        for element in attributesArray {
            // Not all key attributes are allowed when deleting the key
            // so create a new search dictionary with only the relevant
            // attributes.
            var searchDictionary: [String: AnyObject] = [:]
            
            if let value = element[Constants.secClass] {
                searchDictionary[Constants.secClass] = value
            }
            
            if let value = element[Constants.secAttrApplicationTag] {
                searchDictionary[Constants.secAttrApplicationTag] = value
            }
            
            if let value = element[Constants.secAttrAccount] {
                searchDictionary[Constants.secAttrAccount] = value
            }
            
            if let value = element[Constants.secAttrService] {
                searchDictionary[Constants.secAttrService] = value
            }
            
            if let value = element[Constants.secAttrGeneric] {
                searchDictionary[Constants.secAttrGeneric] = value
            }
            
            if let value = element[Constants.secAttrAccessible] {
                searchDictionary[Constants.secAttrAccessible] = value
            }
            
            if let value = element[Constants.secAttrSynchronizable] {
                searchDictionary[Constants.secAttrSynchronizable] = value
            }
            
            try deleteKeys(searchDictionary)
        }
    }
    
    public func exportKeys() throws -> [[KeyAttributeName: AnyObject]] {
        var keys: [[KeyAttributeName: AnyObject]] = []
        
        let attributesArray = try getSecAttributesForAllKeys()
        for attributes in attributesArray {
            guard isExportable(attributes) else {
                continue
            }
            
            if let keyName = getKeyNameFromAttributes(attributes) {
                var key: [KeyAttributeName: AnyObject] = [.name: keyName as AnyObject, .version: Constants.keyVersion as AnyObject, .namespace: self.namespace as AnyObject]
                
                if let isSynchronizable = attributes[Constants.secAttrSynchronizable] as? Bool, isSynchronizable {
                    key[.synchronizable] = true as AnyObject?
                } else {
                    key[.synchronizable] = false as AnyObject?
                }
                
                let type = getKeyTypeFromSecAttributes(attributes)
                switch type {
                case .password:
                    guard let keyData = try getPassword(keyName) else {
                        throw KeyManagerError.fatalError
                    }
                    
                    key[.data] = keyData.base64EncodedString() as AnyObject?
                    key[.type] = KeyType.password.rawValue as AnyObject?
                case .privateKey:
                    guard let keyData = try getPrivateKey(keyName) else {
                        throw KeyManagerError.fatalError
                    }
                    
                    key[.data] = keyData.base64EncodedString() as AnyObject?
                    key[.type] = KeyType.privateKey.rawValue as AnyObject?
                case .publicKey:
                    guard let keyData = try getPublicKey(keyName) else {
                        throw KeyManagerError.fatalError
                    }
                    
                    key[.data] = keyData.base64EncodedString() as AnyObject?
                    key[.type] = KeyType.publicKey.rawValue as AnyObject?
                case .symmetricKey:
                    guard let keyData = try getSymmetricKey(keyName) else {
                        throw KeyManagerError.fatalError
                    }
                    
                    key[.data] = keyData.base64EncodedString() as AnyObject?
                    key[.type] = KeyType.symmetricKey.rawValue as AnyObject?
                default:
                    break
                }
                
                if type != .unknown {
                    keys.append(key)
                }
            }
        }
    
        return keys
    }

    public func importKeys(_ keys: [[KeyAttributeName: AnyObject]]) throws {
        for key in keys {
            guard let namespace = key[.namespace] as? String, namespace == self.namespace,
                let name = key[.name] as? String,
                let type = key[.type] as? String,
                let encodedData = key[.data] as? String,
                let data = Data(base64Encoded: encodedData) else {
                continue
            }
            
            if let keyType = KeyType(rawValue: type) {
                switch keyType {
                case .password:
                    if let isSynchronizable = key[.synchronizable] as? Bool, isSynchronizable {
                        try addPassword(data, name: name, isSynchronizable: isSynchronizable, isExportable: true)
                    }
                    try addPassword(data, name: name)
                case .symmetricKey:
                    try addSymmetricKey(data, name: name)
                case .privateKey:
                    try addPrivateKey(data, name: name)
                case .publicKey:
                    try addPublicKey(data, name: name)
                default:
                    break
                }
            }
        }
    }

    public func getKeyId(_ name: String, type: KeyType) throws -> String {
        guard let keyId = String(data: try createKeyId(name, type: type), encoding: String.Encoding.utf8) else {
            throw KeyManagerError.invalidKeyName
        }
        
        return keyId
    }
    
    public func getAttributesForKeys(_ searchAttributes: KeyAttributeSet) throws -> [KeyAttributeSet] {
        guard searchAttributes.isSearchable() else {
            throw KeyManagerError.keyAttributeNotSearchable
        }
        
        var attributesArray: [KeyAttributeSet] = []
        
        // By default, we search for all passwords and cryptographic keys. Other key types are currently
        // not supported.
        var secItemClasses = [Constants.secClassGenericPassword, Constants.secClassKey]
        var searchDictionary: [String: AnyObject] = [Constants.secReturnAttributes: true as AnyObject, Constants.secMatchLimit: Constants.secMatchLimitAll as AnyObject, Constants.secAttrSynchronizable: Constants.secAttrSynchronizableAny as AnyObject]
        
        // Process the search parameters.
        for attribute in searchAttributes.attributes {
            switch attribute.name {
            case .type:
                switch attribute.value {
                case .keyTypeValue(.privateKey):
                    secItemClasses = [Constants.secClassKey]
                    searchDictionary[Constants.secAttrKeyClass] = Constants.secAttrKeyClassPrivate as AnyObject?
                case .keyTypeValue(.publicKey):
                    secItemClasses = [Constants.secClassKey]
                    searchDictionary[Constants.secAttrKeyClass] = Constants.secAttrKeyClassPublic as AnyObject?
                case .keyTypeValue(.symmetricKey):
                    secItemClasses = [Constants.secClassKey]
                    searchDictionary[Constants.secAttrKeyClass] = Constants.secAttrKeyClassSymmetric as AnyObject?
                case .keyTypeValue(.password):
                    secItemClasses = [Constants.secClassGenericPassword]
                default:
                    break
                }
            case .synchronizable:
                switch attribute.value {
                case .boolValue(let value):
                    searchDictionary[Constants.secAttrSynchronizable] = value as AnyObject?
                default:
                    throw KeyManagerError.invalidSearchParam
                }
            case .exportable:
                switch attribute.value {
                case .boolValue(let value):
                    searchDictionary[Constants.secAttrLabel] = value ? Constants.keyLabelExportable as AnyObject : Constants.keyLabelNotExportable as AnyObject
                default:
                    throw KeyManagerError.invalidSearchParam
                }
            case .id:
                // If we searching by key ID then there must be a type specified.
                guard let type = searchAttributes.getAttribute(.type) else {
                    throw KeyManagerError.invalidSearchParam
                }
                
                switch attribute.value {
                case .stringValue(let keyId):
                    guard let keyId = keyId.data(using: String.Encoding.utf8) else {
                        throw KeyManagerError.invalidSearchParam
                    }
                    
                    switch type.value {
                    case .keyTypeValue(let type):
                        let dictionary = try createKeySearchDictionary(keyId, type: type, returnDataType: .attributes)
                        searchDictionary.addDictionary(dictionary)
                    default:
                        throw KeyManagerError.invalidSearchParam
                    }
                default:
                    throw KeyManagerError.invalidSearchParam
                }
            default:
                throw KeyManagerError.keyAttributeNotSearchable
            }
        }
        
        for secItemClass in secItemClasses {
            searchDictionary[Constants.secClass] = secItemClass as AnyObject?
            
            var result: AnyObject?
            let status = SecItemCopyMatching(searchDictionary as CFDictionary, &result)
            
            switch status {
            case errSecSuccess:
                if let array = result as? [[String: AnyObject]] {
                    for var element in array {
                        // Apple's keychain API does not return the key class in the result set so we
                        // need to set it manually.
                        element[Constants.secClass] = searchDictionary[Constants.secClass]
                        
                        if let attributes = secAttributesToKeyManagerAttributes(element) {
                            attributesArray.append(attributes)
                        }
                    }
                }
            case errSecItemNotFound:
                // Safe to ignore this status since it indicates that no keychain item matched the search criteria.
                break
            default:
                throw KeyManagerError.unhandledUnderlyingSecAPIError(code: status)
            }
        }
        
        return attributesArray
    }
    
    public func createIV() throws -> Data {
        return try createRandomData(self.blockSizeAES)
    }
    
}
