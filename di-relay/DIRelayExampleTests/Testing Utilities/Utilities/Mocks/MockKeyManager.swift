//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoKeyManager

class MockKeyManager: SudoKeyManager {

    var namespace: String = ""

    func encryptWithPublicKey(_ name: String, data: Data, algorithm: PublicKeyEncryptionAlgorithm) throws -> Data {
        return Data()
    }

    func decryptWithPrivateKey(_ name: String, data: Data, algorithm: PublicKeyEncryptionAlgorithm) throws -> Data {
        return Data()
    }

    func addPassword(_ password: Data, name: String) throws {
    }

    func addPassword(_ password: Data, name: String, isSynchronizable: Bool, isExportable: Bool) throws {
    }

    func getPassword(_ name: String) throws -> Data? {
        return nil
    }

    func deletePassword(_ name: String) throws {
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

    func decryptWithSymmetricKey(_ key: Data, data: Data) throws -> Data {
        return Data()
    }

    func decryptWithSymmetricKey(_ key: Data, data: Data, iv: Data) throws -> Data {
        return Data()
    }

    func createSymmetricKeyFromPassword(_ password: String) throws -> (key: Data, salt: Data, rounds: UInt32) {
        return (Data(), Data(), 0)
    }

    func createSymmetricKeyFromPassword(_ password: Data, salt: Data, rounds: UInt32) throws -> Data {
        return Data()
    }

    func createSymmetricKeyFromPassword(_ password: String, salt: Data, rounds: UInt32) throws -> Data {
        return Data()
    }

    func generateHash(_ data: Data) throws -> Data {
        return Data()
    }

    func generateKeyPair(_ name: String) throws {
    }

    func generateKeyPair(_ name: String, isExportable: Bool) throws {
    }

    func generateKeyId() throws -> String {
        return ""
    }

    func addPrivateKey(_ key: Data, name: String) throws {
    }

    func addPrivateKey(_ key: Data, name: String, isExportable: Bool) throws {
    }

    func getPrivateKey(_ name: String) throws -> Data? {
        return nil
    }

    func addPublicKey(_ key: Data, name: String) throws {
    }

    func addPublicKey(_ key: Data, name: String, isExportable: Bool) throws {
    }

    func getPublicKey(_ name: String) throws -> Data? {
        return nil
    }

    func deleteKeyPair(_ name: String) throws {
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

}
