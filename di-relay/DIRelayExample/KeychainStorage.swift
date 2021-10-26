//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Security

class CodableKeychainStorage<T: Codable> {
    enum Errors: Error, LocalizedError {
        case failedToEncodeValue(Error)
        case failedToDecodeValue(Error)
        case failedToStoreInKeychain(OSStatus)
        case failedToRetrieveFromKeychain(OSStatus)

        var errorDescription: String? {
            switch self {
            case .failedToEncodeValue(let error):
                return "Failed to encode value: \(error.localizedDescription)"
            case .failedToDecodeValue(let error):
                return "Failed to decode value: \(error.localizedDescription)"
            case .failedToStoreInKeychain(let code):
                return "Failed to store in keychain: OSStatus code \(code)"
            case .failedToRetrieveFromKeychain(let code):
                return "Failed to retrieve from keychain: OSStatus code \(code)"
            }
        }
    }
    
    /// Attempt to store `value` against the key `key`.
    /// .
    /// - Parameters:
    ///   - value: Value of type `T` to store.
    ///   - key: Key to store the value against.
    /// - Throws: `Errors.FailedToEncodeValue`
    func setValue(_ value: T, forKey key: String) throws {
        let json: Data
        do {
            json = try JSONEncoder().encode(value)
        } catch let error {
            throw Errors.failedToEncodeValue(error)
        }

        let status = set(key: key, data: json)

        switch status {
        case noErr: break
        default:
            throw Errors.failedToStoreInKeychain(status)
        }
    }
    
    ///  Attempt to retrieve the value stored against the given `key`.
    ///
    /// - Parameter key: Key corresponding to retrieved value.
    /// - Throws: `Errors.FailedToDecodeValue`.
    /// - Returns: Value stored against key or nil.
    func value(forKey key: String) throws -> T? {
        guard let data = try load(key: key) else {
            return nil
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch let error {
            throw Errors.failedToDecodeValue(error)
        }
    }

    // MARK: - Keychain
    
    /// Add `data` to keychain against given `key`.
    ///
    /// - Parameters:
    ///   - key: Key to store data against.
    ///   - data: Data to store.
    /// - Returns: `OSStatus`
    private func set(key: String, data: Data) -> OSStatus {
        let query: [String : Any] = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)

        return SecItemAdd(query as CFDictionary, nil)
    }
    
    /// Retrieve data from keychain stored against `key`.
    ///
    /// - Parameter key: Key of the data stored in the keychain.
    /// - Throws: `Errors.FailedToRetrieveFromKeychain`.
    /// - Returns: The data stored in the keychain or nil.
    private func load(key: String) throws -> Data? {
        let query = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : key,
            kSecReturnData as String  : kCFBooleanTrue!,
            kSecMatchLimit as String  : kSecMatchLimitOne ] as [String : Any]

        var dataTypeRef: AnyObject? = nil

        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        switch status {
        case noErr:
            return dataTypeRef as! Data?
        case errSecItemNotFound:
            return nil
        default:
            throw Errors.failedToRetrieveFromKeychain(status)
        }
    }
}
