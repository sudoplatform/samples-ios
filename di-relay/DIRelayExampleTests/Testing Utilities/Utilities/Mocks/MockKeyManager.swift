//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoKeyManager

class MockKeyManager: SudoKeyManager {
    func deletePrivateKey(_ name: String) throws {

    }

    func addPublicKeyFromPEM(_ key: String, name: String) throws {

    }

    func addPublicKeyFromPEM(_ key: String, name: String, isExportable: Bool) throws {

    }

    func getPublicKeyAsPEM(_ name: String) throws -> String? {
        return nil
    }

    func deletePublicKey(_ name: String) throws {

    }

    var namespace: String = ""

    var addPasswordCallCount = 0
    var addPasswordLastProperties: (password: Data, name: String)?
    var addPasswordError: Error?

    func addPassword(_ password: Data, name: String) throws {
        addPasswordCallCount += 1
        addPasswordLastProperties = (password, name)
        if let error = addPasswordError {
            throw error
        }
    }

    var getPasswordCallCount = 0
    var getPasswordResult: Data?

    func getPassword(_ name: String) throws -> Data? {
        getPasswordCallCount += 1
        return getPasswordResult
    }

    var deletePasswordCallCount = 0
    var deletePasswordLastProperties: String?
    var deletePasswordName: String?

    func deletePassword(_ name: String) throws {
        deletePasswordCallCount += 1
        deletePasswordLastProperties = name
    }

    var generateKeyIdCallCount = 0
    var generateKeyIdResult: String = ""

    func generateKeyId() throws -> String {
        generateKeyIdCallCount += 1
        return generateKeyIdResult
    }

    var getPrivateKeyCallCount = 0
    var getPrivateKeyName: String?
    var getPrivateKeyResult: Data?

    func getPrivateKey(_ name: String) throws -> Data? {
        getPrivateKeyCallCount += 1
        getPrivateKeyName = name
        return getPrivateKeyResult
    }

    var getPublicKeyCallCount = 0
    var getPublicKeyName: String?
    var getPublicKeyResult: Data?

    func getPublicKey(_ name: String) throws -> Data? {
        getPublicKeyCallCount += 1
        getPublicKeyName = name
        return getPublicKeyResult
    }

    var deleteKeyPairCallCount = 0
    var deleteKeyPairLastProperty: String?

    func deleteKeyPair(_ name: String) throws {
        deleteKeyPairCallCount += 1
        deleteKeyPairLastProperty = name
    }

    var decryptWithPrivateKeyCallCount = 0
    var decryptWithPrivateKeyLastProperties: (name: String, data: Data, algorithm: PublicKeyEncryptionAlgorithm)?
    var decryptWithPrivateKeyResult: Data = Data()

    func decryptWithPrivateKey(_ name: String, data: Data, algorithm: PublicKeyEncryptionAlgorithm) throws -> Data {
        decryptWithPrivateKeyCallCount += 1
        decryptWithPrivateKeyLastProperties = (name, data, algorithm)
        return decryptWithPrivateKeyResult
    }

    var encryptWithPublicKeyCallCount = 0
    var encryptWithPublicKeyResult: Data = Data()

    func encryptWithPublicKey(_ name: String, data: Data, algorithm: PublicKeyEncryptionAlgorithm) throws -> Data {
        encryptWithPublicKeyCallCount += 1
        return encryptWithPublicKeyResult
    }

    var generateKeyPairCallCount = 0
    var generateKeyPairLastProperty: String?

    func generateKeyPair(_ name: String) throws {
        generateKeyPairCallCount += 1
        generateKeyPairLastProperty = name
    }

    var decryptWithSymmetricKeyCallCount = 0
    var decryptWithSymmetricKeyLastProperties: (key: Data, data: Data)?
    var decryptWithSymmetricKeyError: Error?
    var decryptWithSymmetricKeyResult = Data()

    func decryptWithSymmetricKey(_ key: Data, data: Data) throws -> Data {
        decryptWithSymmetricKeyCallCount += 1
        decryptWithSymmetricKeyLastProperties = (key, data)
        if let error = decryptWithSymmetricKeyError {
            throw error
        }
        return decryptWithSymmetricKeyResult
    }

    func addPassword(_ password: Data, name: String, isSynchronizable: Bool, isExportable: Bool) throws {
    }

    func updatePassword(_ password: Data, name: String) throws {
    }

    func getKeyAttributes(_ name: String, type: KeyType) throws -> KeyAttributeSet? {
        return nil
    }

    func updateKeyAttributes(_ attributes: KeyAttributeSet, name: String, type: KeyType) throws {
    }

    func generateSymmetricKey(_ name: String) throws {
    }

    func generateSymmetricKey(_ name: String, isExportable: Bool) throws {
    }

    func addSymmetricKey(_ key: Data, name: String) throws {
    }

    func addSymmetricKey(_ key: Data, name: String, isExportable: Bool) throws {
    }

    func getSymmetricKey(_ name: String) throws -> Data? {
        return nil
    }

    func deleteSymmetricKey(_ name: String) throws {
    }

    func encryptWithSymmetricKey(_ name: String, data: Data) throws -> Data {
        return Data()
    }

    func encryptWithSymmetricKey(_ name: String, data: Data, iv: Data) throws -> Data {
        return Data()
    }

    func encryptWithSymmetricKey(_ key: Data, data: Data) throws -> Data {
        return Data()
    }

    func encryptWithSymmetricKey(_ key: Data, data: Data, iv: Data) throws -> Data {
        return Data()
    }

    func decryptWithSymmetricKey(_ name: String, data: Data) throws -> Data {
        return Data()
    }

    func decryptWithSymmetricKey(_ name: String, data: Data, iv: Data) throws -> Data {
        return Data()
    }

    func decryptWithSymmetricKey(_ key: Data, data: Data, iv: Data) throws -> Data {
        return Data()
    }

    func createSymmetricKeyFromPassword(_ password: String) throws -> (key: Data, salt: Data, rounds: UInt32) {
        return (Data(), Data(), 0)
    }

    func createSymmetricKeyFromPassword(_ password: String, salt: Data, rounds: UInt32) throws -> Data {
        return Data()
    }

    func generateHash(_ data: Data) throws -> Data {
        return Data()
    }

    func generateKeyPair(_ name: String, isExportable: Bool) throws {
    }

    func addPrivateKey(_ key: Data, name: String) throws {
    }

    func addPrivateKey(_ key: Data, name: String, isExportable: Bool) throws {
    }

    func addPublicKey(_ key: Data, name: String) throws {
    }

    func addPublicKey(_ key: Data, name: String, isExportable: Bool) throws {
    }

    func generateSignatureWithPrivateKey(_ name: String, data: Data) throws -> Data {
        return Data()
    }

    func verifySignatureWithPublicKey(_ name: String, data: Data, signature: Data) throws -> Bool {
        return true
    }

    func createRandomData(_ size: Int) throws -> Data {
        return Data()
    }

    func removeAllKeys() throws {
    }

    func exportKeys() throws -> [[KeyAttributeName: AnyObject]] {
        return []
    }

    func importKeys(_ keys: [[KeyAttributeName: AnyObject]]) throws {
    }

    func getKeyId(_ name: String, type: KeyType) throws -> String {
        return ""
    }

    func getAttributesForKeys(_ searchAttributes: KeyAttributeSet) throws -> [KeyAttributeSet] {
        return []
    }

    func createIV() throws -> Data {
        return Data()
    }

    func createSymmetricKeyFromPassword(_ password: Data, salt: Data, rounds: UInt32) throws -> Data {
        return Data()
    }
}
