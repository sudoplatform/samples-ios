//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Security
import CryptoKit
import CommonCrypto

/// Class encapsulating the default implementation of `SudoKeyManager` protocol
/// that uses Apple's Keychain, CryptoKit and CommonCrypto APIs. Symmetric key
/// cryptography uses AES-GCM with 256 bit key and public key cryptography uses
/// RSA with OAEP padding, SHA1 digest and 4096 bit key. Symmetric key encryption
/// produces a payload that concatenates IV, ciphertext and authentication tag:
/// [iv][ciphertext][tag]
/// The corresponding decryption expects the encrypted payload to be in the same
/// format.
final public class DefaultSudoKeyManager {
    
    /// Determines how the key will be returned by `SudoKeyManager` API.
    ///
    /// - Reference: A reference to the key will be returned.
    /// - Data: Actual key data will be returned.
    /// - Attributes: Metadata associated with the key will be returned.
    fileprivate enum ReturnDataType {
        case reference
        case data
        case attributes
    }
    
    /// List of contants used by this class.
    public struct Constants {
        static let keyVersion = 1
        
        static let uuidGenerationLimit = 100
        
        public static let defaultKeySizeAES = kCCKeySizeAES256 << 3
        public static let defaultBlockSizeAES = kCCBlockSizeAES128
        public static let defaultIVSize = 12
        public static let defaultTagSize = 16
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
        static let secAttrKeyTypeAES = "2147483649"
        
        static let secMatchLimitOne = kSecMatchLimitOne as String
        static let secMatchLimitAll = kSecMatchLimitAll as String
        static let secAttrSynchronizableAny = kSecAttrSynchronizableAny as String
        static let secAttrAccessibleAfterFirstUnlock = kSecAttrAccessibleAfterFirstUnlock as String
        
        static let rsaPublicKeyPEMHeader = "-----BEGIN RSA PUBLIC KEY-----"
        static let rsaPublicKeyPEMFooter = "-----END RSA PUBLIC KEY-----"
    }
    
    /// The service name (`KSecAttrService`) to associate with passwords. It is used
    /// to specify the owning service of `kSecClassGenericPassword` keychain items
    /// and is a part of the primary key used to look up `kSecClassGenericPassword`
    /// keychain items.
    fileprivate var serviceName: String
    
    /// A tag to be added to crytographic keys so that a `SudoKeyManager` instance can
    /// distinguish the keys that it created from others. This tag is added to
    /// `kSecAttrApplicationTag` attribute of `kSecClassKey` keychain items along
    /// with the key name. The tag is essentially an alternative to using the service
    /// name since `KSecAttrService` is not available for `kSecClassKey` keychain
    /// items.
    fileprivate var keyTag: String

    public fileprivate(set) var namespace: String = ""
    
    /// AES key size in bits.
    fileprivate var keySizeAES: Int = Constants.defaultKeySizeAES

    /// AES block size in bits.
    fileprivate var blockSizeAES: Int = Constants.defaultBlockSizeAES
    
    /// AES IV size in bytes.
    fileprivate var defaultIVSize: Int = Constants.defaultIVSize

    /// RSA key size in bits.
    fileprivate var keySizeRSA: Int = Constants.defaultKeySizeRSA
    
    /// Intializes a new `DefaultSudoKeyManager` instance with the specified service name, namespace and key sizes.
    ///
    /// - Parameters:
    ///   - serviceName: Service name to be associated with keys created by this `SudoKeyManager`.
    ///   - keyTag: A tag to be added to crytographic keys to uniquely identify a set of keys managed.
    ///   - namespace: Namespace to use for the key name. If a namespace is specified then unique
    ///         identifier for each key will be`"<namespace>.<keyName>"`. Namespace cannot be an
    ///         empty string.
    ///   - keySizeAES: AES key size. Default is 256 bits.
    ///   - blockSizeAES: AES block size. Default is 128 bits.
    ///   - keySizeRSA: RSA key size. Default is 2048 bits.
    public init(serviceName: String, keyTag: String, namespace: String, keySizeAES: Int = Constants.defaultKeySizeAES, blockSizeAES: Int = Constants.defaultBlockSizeAES, keySizeRSA: Int = Constants.defaultKeySizeRSA) {
        self.namespace = namespace
        self.serviceName = serviceName
        self.keySizeAES = keySizeAES
        self.blockSizeAES = blockSizeAES
        self.keySizeRSA = keySizeRSA
        self.keyTag = keyTag
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
            throw SudoKeyManagerError.invalidKeyName
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
            throw SudoKeyManagerError.invalidKeyType
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
    
    fileprivate func secAttributesToSudoKeyManagerAttributes(_ secAttributes: [String: AnyObject]) -> KeyAttributeSet? {
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
                // Only include the keys that were created by this SudoKeyManager. Passwords should
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
                            // Only include the keys that were created by this SudoKeyManager. Keys should have
                            // a tag that has the configured key tag + namespace as prefix.
                            if let data = element[Constants.secAttrApplicationTag] as? Data, let tag = String(data: data, encoding: .utf8) {
                                let prefix = createKeyIdPrefix(type)
                                if !prefix.isEmpty && tag.hasPrefix("\(prefix).") {
                                    attributesArray.append(element)
                                }
                            }
                        case .password:
                            // Only include the passwords that were created by this SudoKeyManager. Passwords should
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
                throw SudoKeyManagerError.unhandledUnderlyingSecAPIError(code: status)
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
            throw SudoKeyManagerError.unhandledUnderlyingSecAPIError(code: status)
        }
        
        return keyData
    }
 
    fileprivate func deleteKeys(_ searchDictionary: [String: AnyObject]) throws {
        let status = SecItemDelete(searchDictionary as CFDictionary)
        switch status {
        case errSecSuccess, errSecItemNotFound:
            break
        default:
            throw SudoKeyManagerError.unhandledUnderlyingSecAPIError(code: status)
        }
    }

    /// Resets the secure store holding the keys. This removes every key regardless
    /// of whether or not the key was created by `SudoKeyManager` so it should only
    ///  be used for debugging.
    ///
    /// - Throws:
    ///     `SudoKeyManagerError.unhandledUnderlyingSecAPIError`
    public func resetSecureKeyStore() throws {
            
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
                throw SudoKeyManagerError.unhandledUnderlyingSecAPIError(code: status)
            }
        }
    }
    
}

// MARK: SudoKeyManager

extension DefaultSudoKeyManager: SudoKeyManager {
    
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
            throw SudoKeyManagerError.duplicateKey
        default:
            throw SudoKeyManagerError.unhandledUnderlyingSecAPIError(code: status)
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
            throw SudoKeyManagerError.keyNotFound
        default:
            throw SudoKeyManagerError.unhandledUnderlyingSecAPIError(code: status)
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
            throw SudoKeyManagerError.unhandledUnderlyingSecAPIError(code: status)
        }
        
        guard var dictionary = result as? [String: AnyObject] else {
            // If the result is not a dictionary of key attributes despite of success
            // status then there's something seriously wrong.
            throw SudoKeyManagerError.fatalError
        }

        // Apple's keychain API does not return the key class in the result set so we
        // need to set it manually.
        dictionary[Constants.secClass] = searchDictionary[Constants.secClass]
        return secAttributesToSudoKeyManagerAttributes(dictionary)
    }
    
    public func updateKeyAttributes(_ attributes: KeyAttributeSet, name: String, type: KeyType) throws
    {
        guard attributes.count > 0 else {
            return
        }
        
        guard attributes.isMutable() else {
            throw SudoKeyManagerError.keyAttributeNotMutable
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
                throw SudoKeyManagerError.keyAttributeNotMutable
            }
        }
        
        let status = SecItemUpdate(searchDictionary as CFDictionary, updateDictionary as CFDictionary)
        switch status {
        case errSecSuccess:
            break
        case errSecItemNotFound:
            throw SudoKeyManagerError.keyNotFound
        default:
            throw SudoKeyManagerError.unhandledUnderlyingSecAPIError(code: status)
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
            throw SudoKeyManagerError.duplicateKey
        default:
            throw SudoKeyManagerError.unhandledUnderlyingSecAPIError(code: status)
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
        let iv = try self.createIV()
        return try encryptWithSymmetricKey(name, data: data, iv: iv)
    }
    
    public func encryptWithSymmetricKey(_ name: String, data: Data, iv: Data) throws -> Data {
        var encryptedData: Data
        
        if let keyData = try getSymmetricKey(name) {
            encryptedData = try encryptWithSymmetricKey(keyData, data: data, iv: iv)
        } else {
            throw SudoKeyManagerError.keyNotFound
        }
        
        return encryptedData
    }
    
    public func encryptWithSymmetricKey(_ key: Data, data: Data) throws -> Data {
        let iv = try self.createIV()
        return try encryptWithSymmetricKey(key, data: data, iv: iv)
    }
    
    public func encryptWithSymmetricKey(_ key: Data, data: Data, iv: Data) throws -> Data {
        let symmetricKey = SymmetricKey(data: key)
        let sealedData = try AES.GCM.seal(data, using: symmetricKey, nonce: AES.GCM.Nonce(data: iv))
        // combined = iv + ciphertext + authentication tag.
        guard let combined = sealedData.combined else {
            throw SudoKeyManagerError.fatalError
        }
        
        return combined
    }
    
    public func decryptWithSymmetricKey(_ name: String, data: Data) throws -> Data {
        var decryptedData: Data
        
        if let keyData = try getSymmetricKey(name) {
            try decryptedData = decryptWithSymmetricKey(keyData, data: data)
        } else {
            throw SudoKeyManagerError.keyNotFound
        }
        
        return decryptedData
    }
    
    public func decryptWithSymmetricKey(_ name: String, data: Data, iv: Data) throws -> Data {
        throw SudoKeyManagerError.notImplemented
    }
    
    public func decryptWithSymmetricKey(_ key: Data, data: Data) throws -> Data {
        guard data.count > (Constants.defaultIVSize + Constants.defaultTagSize) else {
            throw SudoKeyManagerError.invalidEncryptedData
        }
        
        let symmetricKey = SymmetricKey(data: key)
        
        let iv = data[0..<Constants.defaultIVSize]
        let ciphertext = data[Constants.defaultIVSize..<data.count - 16]
        let tag = data[data.count - 16..<data.count]
        
        let sealedBox = try AES.GCM.SealedBox(nonce: AES.GCM.Nonce(data: iv),
                                               ciphertext: ciphertext,
                                               tag: tag)

        let decrypted = try AES.GCM.open(sealedBox, using: symmetricKey)
        return decrypted
    }
    
    public func decryptWithSymmetricKey(_ key: Data, data: Data, iv: Data) throws -> Data {
        throw SudoKeyManagerError.notImplemented
    }
    
    public func createSymmetricKeyFromPassword(_ password: String) throws -> (key: Data, salt: Data, rounds: UInt32) {
        guard let passwordData = password.data(using: String.Encoding.utf8) else {
            throw SudoKeyManagerError.fatalError
        }
        
        let salt = try createRandomData(self.keySizeAES >> 3)
        
        // Determine the number of PRF rounds that can be used within 100 ms in the
        // current platform.
        let rounds = CCCalibratePBKDF(CCPBKDFAlgorithm(kCCPBKDF2), passwordData.count, salt.count, CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256), self.keySizeAES >> 3, UInt32(100))
        
        let keyData = try createSymmetricKeyFromPassword(password, salt: salt, rounds: rounds)
        
        return (keyData, salt, rounds)
    }
    
    public func createSymmetricKeyFromPassword(_ password: Data, salt: Data, rounds: UInt32) throws -> Data {
        var data = [UInt8](repeating: 0,  count: self.keySizeAES >> 3)
        // Derive a cryptographic key from the password, salt and required rounds of pseudo random function applied.
        let status: CCCryptorStatus = try password.withUnsafeBytes {
            guard let passwordBytes = $0.baseAddress?.assumingMemoryBound(to: Int8.self) else {
                throw SudoKeyManagerError.fatalError
            }
            return try salt.withUnsafeBytes {
                guard let saltBytes = $0.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                    throw SudoKeyManagerError.fatalError
                }

                return CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2),
                                     passwordBytes,
                                     password.count,
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
            throw SudoKeyManagerError.unhandledUnderlyingSecAPIError(code: status)
        }

        return Data(data)
    }
    
    public func createRandomData(_ size: Int) throws -> Data {
        var data = [UInt8](repeating: 0,  count: Int(size))
        
        let status = SecRandomCopyBytes(kSecRandomDefault, data.count, &data)
        
        if status != noErr {
            throw SudoKeyManagerError.unhandledUnderlyingSecAPIError(code: status)
        }
        
        return Data(data)
    }
    
    public func generateHash(_ data: Data) throws -> Data {
        return  Data(SHA256.hash(data: data))
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
            throw SudoKeyManagerError.duplicateKey
        default:
            throw SudoKeyManagerError.unhandledUnderlyingSecAPIError(code: status)
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
            throw SudoKeyManagerError.uuidGenerationLimitExceeded
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
            throw SudoKeyManagerError.duplicateKey
        default:
            throw SudoKeyManagerError.unhandledUnderlyingSecAPIError(code: status)
        }
    }
    
    public func getPrivateKey(_ name: String) throws -> Data? {
        return try getKeyData(createKeySearchDictionary(name, type: .privateKey))
    }
    
    public func deletePrivateKey(_ name: String) throws {
        let dictionary = try createKeySearchDictionary(name, type: .privateKey)
        try deleteKeys(dictionary)
    }

    public func addPublicKey(_ key: Data, name: String) throws {
        try self.addPublicKey(key, name: name, isExportable: true)
    }
    
    public func addPublicKeyFromPEM(_ key: String, name: String) throws {
        try self.addPublicKeyFromPEM(key, name: name, isExportable: true)
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
            throw SudoKeyManagerError.duplicateKey
        default:
            throw SudoKeyManagerError.unhandledUnderlyingSecAPIError(code: status)
        }
    }
    
    public func addPublicKeyFromPEM(_ key: String, name: String, isExportable: Bool) throws {
        var trimmed = key.replacingOccurrences(of: "\n", with: "")
        trimmed = trimmed.replacingOccurrences(of: Constants.rsaPublicKeyPEMHeader, with: "")
        trimmed = trimmed.replacingOccurrences(of: Constants.rsaPublicKeyPEMFooter, with: "")
        
        guard !trimmed.isEmpty, let keyData = Data(base64Encoded: trimmed) else {
            throw SudoKeyManagerError.invalidKey
        }
        
        try self.addPublicKey(keyData, name: name, isExportable: isExportable)
    }
    
    public func getPublicKey(_ name: String) throws -> Data? {
        return try getKeyData(createKeySearchDictionary(name, type: .publicKey))
    }
    
    
    public func getPublicKeyAsPEM(_ name: String) throws -> String? {
        guard let keyData = try self.getPublicKey(name) else {
            return nil
        }
        
        let chunks = keyData.base64EncodedString().chunk(length: 64)
        return Constants.rsaPublicKeyPEMHeader + "\n" + chunks.joined(separator: "\n") + "\n" + Constants.rsaPublicKeyPEMFooter
    }
    
    public func deletePublicKey(_ name: String) throws {
        let dictionary = try createKeySearchDictionary(name, type: .publicKey)
        try deleteKeys(dictionary)
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

            status = try hash.withUnsafeBytes {
                guard let bytes = $0.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                    throw SudoKeyManagerError.fatalError
                }

                return SecKeyRawSign(key,
                              SecPadding.PKCS1SHA256,
                              bytes,
                              hash.count,
                              &buffer,
                              &bytesWritten
                )
            }

            if status == noErr {
                signature = Data(bytes: buffer, count: bytesWritten)
            } else {
                throw SudoKeyManagerError.unhandledUnderlyingSecAPIError(code: status)
            }
        case errSecItemNotFound:
            throw SudoKeyManagerError.keyNotFound
        default:
            throw SudoKeyManagerError.unhandledUnderlyingSecAPIError(code: status)
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

            status = try hash.withUnsafeBytes {
                guard let hashBytes = $0.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                    throw SudoKeyManagerError.fatalError
                }
                return try signature.withUnsafeBytes {
                    guard let signatureBytes = $0.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                        throw SudoKeyManagerError.fatalError
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
            
            if status == noErr {
                valid = true
            }
        case errSecItemNotFound:
            throw SudoKeyManagerError.keyNotFound
        default:
            throw SudoKeyManagerError.unhandledUnderlyingSecAPIError(code: status)
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
                    throw SudoKeyManagerError.fatalError
                }

                // Encrypt the data one block at a time.
                while bytesEncrypted < data.count {
                    let cursor = bytes.advanced(by: bytesEncrypted)
                    let bytesToEncrypt = maxPlainTextLen > data.count - bytesEncrypted ? data.count - bytesEncrypted : maxPlainTextLen
                    var bytesWritten = buffer.count
                        
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
                    
                    if status == noErr {
                        bytesEncrypted += bytesToEncrypt
                        encryptedData.append(buffer, count: bytesWritten)
                    } else {
                        throw SudoKeyManagerError.unhandledUnderlyingSecAPIError(code: status)
                    }
                }
            }
        case errSecItemNotFound:
            throw SudoKeyManagerError.keyNotFound
        default:
            throw SudoKeyManagerError.unhandledUnderlyingSecAPIError(code: status)
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
                throw SudoKeyManagerError.invalidCipherText
            }
            
            // When padding is used the encrypted data will be 11 bytes longer than the input
            // so the plaintext buffer can be 11 bytes less.
            var buffer = [UInt8](repeating: 0,  count: blockSize - 11)
            
            // Total bytes decrypted.
            var bytesDecrypted = 0
            
            try data.withUnsafeBytes {
                guard let bytes = $0.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                    throw SudoKeyManagerError.fatalError
                }
                // Decrypt the data one block at a time.
                while bytesDecrypted < data.count {
                    let cursor = bytes.advanced(by: bytesDecrypted)
                    var bytesWritten = buffer.count
                        
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
                    
                    if status == noErr {
                        bytesDecrypted += blockSize
                        decryptedData.append(buffer, count: bytesWritten)
                    } else {
                        throw SudoKeyManagerError.unhandledUnderlyingSecAPIError(code: status)
                    }
                }
            }
        case errSecItemNotFound:
            throw SudoKeyManagerError.keyNotFound
        default:
            throw SudoKeyManagerError.unhandledUnderlyingSecAPIError(code: status)
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
                        throw SudoKeyManagerError.fatalError
                    }
                    
                    key[.data] = keyData.base64EncodedString() as AnyObject?
                    key[.type] = KeyType.password.rawValue as AnyObject?
                case .privateKey:
                    guard let keyData = try getPrivateKey(keyName) else {
                        throw SudoKeyManagerError.fatalError
                    }
                    
                    key[.data] = keyData.base64EncodedString() as AnyObject?
                    key[.type] = KeyType.privateKey.rawValue as AnyObject?
                case .publicKey:
                    guard let keyData = try getPublicKey(keyName) else {
                        throw SudoKeyManagerError.fatalError
                    }
                    
                    key[.data] = keyData.base64EncodedString() as AnyObject?
                    key[.type] = KeyType.publicKey.rawValue as AnyObject?
                case .symmetricKey:
                    guard let keyData = try getSymmetricKey(keyName) else {
                        throw SudoKeyManagerError.fatalError
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
            throw SudoKeyManagerError.invalidKeyName
        }
        
        return keyId
    }
    
    public func getAttributesForKeys(_ searchAttributes: KeyAttributeSet) throws -> [KeyAttributeSet] {
        guard searchAttributes.isSearchable() else {
            throw SudoKeyManagerError.keyAttributeNotSearchable
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
                    throw SudoKeyManagerError.invalidSearchParam
                }
            case .exportable:
                switch attribute.value {
                case .boolValue(let value):
                    searchDictionary[Constants.secAttrLabel] = value ? Constants.keyLabelExportable as AnyObject : Constants.keyLabelNotExportable as AnyObject
                default:
                    throw SudoKeyManagerError.invalidSearchParam
                }
            case .id:
                // If we searching by key ID then there must be a type specified.
                guard let type = searchAttributes.getAttribute(.type) else {
                    throw SudoKeyManagerError.invalidSearchParam
                }
                
                switch attribute.value {
                case .stringValue(let keyId):
                    guard let keyId = keyId.data(using: String.Encoding.utf8) else {
                        throw SudoKeyManagerError.invalidSearchParam
                    }
                    
                    switch type.value {
                    case .keyTypeValue(let type):
                        let dictionary = try createKeySearchDictionary(keyId, type: type, returnDataType: .attributes)
                        searchDictionary.addDictionary(dictionary)
                    default:
                        throw SudoKeyManagerError.invalidSearchParam
                    }
                default:
                    throw SudoKeyManagerError.invalidSearchParam
                }
            default:
                throw SudoKeyManagerError.keyAttributeNotSearchable
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
                        
                        if let attributes = secAttributesToSudoKeyManagerAttributes(element) {
                            attributesArray.append(attributes)
                        }
                    }
                }
            case errSecItemNotFound:
                // Safe to ignore this status since it indicates that no keychain item matched the search criteria.
                break
            default:
                throw SudoKeyManagerError.unhandledUnderlyingSecAPIError(code: status)
            }
        }
        
        return attributesArray
    }
    
    public func createIV() throws -> Data {
        return try createRandomData(self.defaultIVSize)
    }
    
}
