//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// List of possible errors thrown by `SecureKeyArchive` implementation.
///
/// - duplicateKey: Indicates that duplicate keys were found while saving the
///     keys to the secure store.
/// - archiveEmpty: Indicates that unarchive or archive operation was requested
///     but the archive was empty.
/// - invalidPassword: Indicates the password invalid, e.g. empty string.
/// - invalidKeyAttribute: Indicates the archive contained invalid key attribute.
/// - versionMismatch: Indicates the archive being unarchived is not a support
///     version.
/// - fatalError: Indicates that a fatal error occurred. This could be due to
///     coding error, out-of-memory condition or other conditions that is
///     beyond control of `SecureKeyArchive` implementation.
public enum SecureKeyArchiveError : Error {
    case duplicateKey
    case archiveEmpty
    case invalidPassword
    case invalidKeyAttribute
    case invalidArchiveData
    case malformedKeySetData
    case versionMismatch
    case fatalError
}

/// List of key archive attributes.
public enum SecureKeyArchiveAttribute: String {
    case version = "Version"
    case keys = "Keys"
    case salt = "Salt"
    case rounds = "Rounds"
    case iv = "IV"
    case metaInfo = "MetaInfo"
}

/// Protocol encapsulating a set of methods required for creating and
/// processing an encrypt archive for a set of cryptographic keys and
/// passwords.
public protocol SecureKeyArchive {
    
    /// Intializes a new `SecureKeyArchive` instance.
    ///
    /// - Parameter keyManager: `SudoKeyManager` instance for accessing keys.
    init(keyManager: SudoKeyManager)
    
    /// Intializes a new `SecureKeyArchive` instance with encrypted
    /// archive data.
    ///
    /// - Parameters:
    ///   - archiveData: encrypted key archive data.
    ///   - keyManager: `SudoKeyManager` instance.
    init?(archiveData: Data, keyManager: SudoKeyManager)
    
    /// Loads keys from the secure store into the archive.
    ///
    /// - Throws:
    ///     `SecureKeyArchiveError.fatalError`
    func loadKeys() throws

    /// Saves the keys in this archive to the secure store.
    /// - Throws:
    ///     `SecureKeyArchiveError.duplicateKey`
    ///     `SecureKeyArchiveError.archiveEmpty`
    ///     `SecureKeyArchiveError.fatalError`
    func saveKeys() throws
    
    /// Archives and encrypts the keys loaded into this archive.
    ///
    /// - Parameter password: Password to use to encrypt the archive.
    ///
    /// - Throws:
    ///     `SecureKeyArchiveError.invalidPassword`
    ///     `SecureKeyArchiveError.archiveEmpty`
    ///     `SecureKeyArchiveError.fatalError`
    func archive(_ password: String) throws -> Data
    
    /// Decrypts and unarchives the keys in this archive.
    ///
    /// - Parameter password: Password to use to decrypt the archive.
    ///
    /// - Throws:
    ///     `SecureKeyArchiveError.invalidPassword`
    ///     `SecureKeyArchiveError.archiveEmpty`
    ///     `SecureKeyArchiveError.invalidArchiveData`
    ///     `SecureKeyArchiveError.fatalError`
    func unarchive(_ password: String) throws
    
    /// Resets the archive by clearing loaded keys and archive data.
    func reset()

    /// Determines whether or not the archive contains the key with the
    /// specified name and type. The archive must be unarchived before the
    /// key can be searched.
    ///
    /// - Parameters:
    ///   - name: Key name.
    ///   - type: Key type.
    ///
    /// - Returns: `true` if the specified key exists in the archive.
    func containsKey(_ name: String, type: KeyType) -> Bool
    
    /// Retrieves the specified key data from the archive. The archive must
    /// be unarchived before the key data can be retrieved.
    ///
    /// - Parameters:
    ///   - name: Key name.
    ///   - type: Key type.
    func getKeyData(_ name: String, type: KeyType) -> Data?
    
    /// Key manager used for managing keys and performing cryptographic operations.
    var keyManager: SudoKeyManager { get set }
    
    /// List of key names to exclude from the archive.
    var excludedKeys: [String] { get set }
    
    /// Meta-information associated with this archive.
    var metaInfo: [String: String] { get set }
    
    /// Archive version.
    var version: Int { get }
    
    /// List of key name spaces associated with this archive.
    var namespaces: [String] { get }
    
}

/// Default implementation of `SecureKeyArchive` which loads and
/// saves keys to and from Apple's keychain. The keys are encrypted
/// using AES.
public class SecureKeyArchiveImpl {

    /// List of contants used by this class.
    fileprivate struct Constants {
        
        static let version = 2
        
    }
    
    public fileprivate(set) var iv: Data?
    
    public var excludedKeys: [String] = []
    
    public var metaInfo: [String: String] = [:]
    
    public fileprivate(set) var namespaces: [String] = []

    /// Keys associated with this archive.
    public fileprivate(set) var keys: [[KeyAttributeName: AnyObject]] = []

    /// Archive version.
    public fileprivate(set) var version = Constants.version
    
    public var keyManager: SudoKeyManager

    /// Encrypted archive data.
    fileprivate var archiveData: Data?
    
    /// Dictionary representing the deserialized content of an archive.
    fileprivate var archiveDictionary: [SecureKeyArchiveAttribute: AnyObject] = [:]

    /// Logger.
    fileprivate let logger = Logger.sharedInstance
    
    public required init(keyManager: SudoKeyManager) {
        self.keyManager = keyManager
    }

    public required init?(archiveData: Data, keyManager: SudoKeyManager) {
        self.keyManager = keyManager
        self.archiveData = archiveData
       
        guard let archiveDictionary = archiveData.toJSONObject() as? [String: AnyObject] else {
            return nil;
        }
        
        // Convert String keys to Enum keys.
        for (k, v) in archiveDictionary {
            guard let enumKey = SecureKeyArchiveAttribute(rawValue: k) else {
                continue
            }
            
            self.archiveDictionary[enumKey] = v
        }
        
        // Meta info might be needed before the archive is unarchived.
        if let metaInfo = self.archiveDictionary[.metaInfo] as? [String: String] {
            self.metaInfo = metaInfo
        }
    }
    
}

// MARK: SecureKeyArchive

extension SecureKeyArchiveImpl: SecureKeyArchive {
    
    public func loadKeys() throws {
        do {
            let keys = try self.keyManager.exportKeys()
            
            for key in keys {
                if let name = key[.name] as? String, !self.excludedKeys.contains(name) {
                    if let namespace = key[.namespace] as? String, !namespace.isEmpty, !namespaces.contains(namespace) {
                        namespaces.append(namespace)
                    }
                    self.keys.append(key)
                }
            }
        } catch let error {
            self.logger.log(.error, message: "Failed to export keys from the secure store: \(error)")
            throw SecureKeyArchiveError.fatalError
        }
    }
    
    public func saveKeys() throws {
        guard self.keys.count > 0 else {
            throw SecureKeyArchiveError.archiveEmpty
        }
        
        // Remove all keys first otherwise we will get key conflicts.
        try self.keyManager.removeAllKeys()
        
        do {
            var keys: [[KeyAttributeName: AnyObject]] = []
            
            for key in self.keys {
                if let name = key[.name] as? String, !self.excludedKeys.contains(name) {
                    keys.append(key)
                }
            }
            
            try self.keyManager.importKeys(keys)
        } catch SudoKeyManagerError.duplicateKey {
            throw SecureKeyArchiveError.duplicateKey
        } catch {
            self.logger.log(.error, message: "Failed to import keys into the secure store: \(error)")
            throw SecureKeyArchiveError.fatalError
        }
    }
    
    public func archive(_ password: String) throws -> Data {
        return try self.archive(password, iv: nil)
    }
    
    public func archive(_ password: String, iv: Data?) throws -> Data {
        guard self.keys.count > 0 else {
            throw SecureKeyArchiveError.archiveEmpty
        }
        
        guard !password.isEmpty else {
            throw SecureKeyArchiveError.invalidPassword
        }

        self.archiveDictionary = [.version: self.version as AnyObject, .metaInfo: self.metaInfo as AnyObject]
        
        // Convert Enum keys to String keys satisfy the requirements for JSON serializer.
        var keys: [[String: AnyObject]] = []
        for dictionary in self.keys {
            keys.append(Dictionary(dictionary.map { (k, v) in (k.rawValue, v) }))
        }
        
        guard let data = keys.toJSONData() else {
            throw SecureKeyArchiveError.fatalError
        }
        
        do {
            let (key, salt, rounds) = try self.keyManager.createSymmetricKeyFromPassword(password)
            self.archiveDictionary[.salt] = salt.base64EncodedString() as AnyObject
            self.archiveDictionary[.rounds] = NSNumber(value: rounds as UInt32)
            
            var ivData: Data!
            if iv == nil {
                ivData = try self.keyManager.createIV()
                self.archiveDictionary[.iv] = ivData.base64EncodedString() as AnyObject
            } else {
                ivData = iv
            }
            
            let encryptedData = try self.keyManager.encryptWithSymmetricKey(key, data: data, iv: ivData)
            
            self.archiveDictionary[.keys] = encryptedData.base64EncodedString() as AnyObject
        } catch {
            self.logger.log(.error, message: "Failed to encrypted the key archive: \(error)")
            throw SecureKeyArchiveError.fatalError
        }
        
        // Convert Enum keys to String keys satisfy the requirements for JSON serializer.
        guard let archiveData = Dictionary(self.archiveDictionary.map { (k, v) in (k.rawValue, v) }).toJSONData() else {
            throw SecureKeyArchiveError.fatalError
        }
        
        return archiveData
    }
    
    public func unarchive(_ password: String) throws {
        guard !password.isEmpty else {
            throw SecureKeyArchiveError.invalidPassword
        }
        
        guard let version = self.archiveDictionary[.version] as? Int,
            let saltStr = self.archiveDictionary[.salt] as? String,
            let salt = Data(base64Encoded: saltStr),
            let rounds = self.archiveDictionary[.rounds] as? NSNumber,
            let keysStr = self.archiveDictionary[.keys] as? String,
            let keysData = Data(base64Encoded: keysStr) else {
            throw SecureKeyArchiveError.invalidArchiveData
        }
        
        guard version == Constants.version else {
            throw SecureKeyArchiveError.versionMismatch
        }
        
        self.version = version
        
        var data: Data?
        do {
            let key = try self.keyManager.createSymmetricKeyFromPassword(password, salt: salt, rounds: UInt32(rounds.uintValue))
            
            // This for backward compatibility as older versions of archive do not have IV.
            var iv = Data(count: 16)
            if let ivStr = archiveDictionary[.iv] as? String,
                let ivData = Data(base64Encoded: ivStr) {
                iv = ivData
            }
            
            self.iv = iv
            
            data = try self.keyManager.decryptWithSymmetricKey(key, data: keysData, iv: iv)
            
            // This is workaround for an iOS API issue that seems to creating non zeroed byte array despite of
            // being asked to do so. Only happens on some devices.
            if data?.toJSONObject() == nil {
                self.logger.log(.error, message: "Decrypted key set invalid. IV: \(iv.toHexString())")
                
                iv = Data(count: 16)
                iv[0] = 0x10
                iv[4] = 0x01
                self.iv = iv
                data = try self.keyManager.decryptWithSymmetricKey(key, data: keysData, iv: iv)
            }
        } catch {
            self.logger.log(.error, message: "Failed to decrypt the key archive: \(error)")
            throw SecureKeyArchiveError.fatalError
        }
        
        guard let array = data?.toJSONObject() as? [[String: AnyObject]] else {
            throw SecureKeyArchiveError.malformedKeySetData
        }
        
        self.keys.removeAll()
        
        // Convert all String keys to Enum keys. We can't use simple mapping here
        // since a String key may fail to convert to Enum key.
        for element in array {
            var dictionary: [KeyAttributeName: AnyObject] = [:]
            for key in element.keys {
                guard let newKey = KeyAttributeName(rawValue: key) else {
                    throw SecureKeyArchiveError.invalidKeyAttribute
                }
                
                dictionary[newKey] = element[key]
            }
            
            if let namespace = dictionary[.namespace] as? String, !namespace.isEmpty, !self.namespaces.contains(namespace) {
                self.namespaces.append(namespace)
            }
            
            self.keys.append(dictionary)
        }
    }
    
    public func reset() {
        self.keys.removeAll()
        self.archiveData = nil
    }
    
    public func containsKey(_ name: String, type: KeyType) -> Bool {
        return getKeyData(name, type: type) != nil
    }
    
    public func getKeyData(_ name: String, type: KeyType) -> Data? {
        var keyData: Data?
        
        for key in self.keys {
            if let namespace = key[.namespace] as? String, namespace == self.keyManager.namespace,
                let keyName = key[.name] as? String, keyName == name,
                let keyType = key[.type] as? String, keyType == type.rawValue,
                let encodedData = key[.data] as? String,
                let data = Data(base64Encoded: encodedData) {
                keyData = data
                break
            }
        }
        
        return keyData
    }
    
}
   
