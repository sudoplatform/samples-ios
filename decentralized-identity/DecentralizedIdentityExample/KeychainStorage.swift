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

    // MARK: Keychain

    private func set(key: String, data: Data) -> OSStatus {
        let query = [
            kSecClass as String       : kSecClassGenericPassword as String,
            kSecAttrAccount as String : key,
            kSecValueData as String   : data ] as [String : Any]

        SecItemDelete(query as CFDictionary)

        return SecItemAdd(query as CFDictionary, nil)
    }

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
