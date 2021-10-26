//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import KeyManager
import SudoLogging


class KeyManagement {
    private var keyManager: KeyManager = KeyManagerImpl(serviceName: "SudoDIRelay", keyTag: "DIR", namespace: "DIR")

    /// Create and store a KeyPair for a given `connectionId.
    ///
    /// - Parameter connectionId: Postbox ID to store the KeyPair against.
    /// - Throws:`KeyManagerError.DuplicateKey`,
    ///          `KeyManagerError.UnhandledUnderlyingSecAPIError`,
    ///          `KeyManagerError.FatalError`
    func createKeyPairForConnection(connectionId: String) throws {
        try keyManager.generateKeyPair(connectionId)
    }

    /// Get the public key that is stored for the given `connectionId`.
    ///
    /// - Parameter connectionId: Postbox ID stored with KeyPair
    /// - Throws:  `KeyManagerError.UnhandledUnderlyingSecAPIError`,
    ///            `KeyManagerError.FatalError`
    /// - Returns: The public key for the given connection ID as a url safe base64 or nil.
    func getPublicKeyForConnection(connectionId: String) throws -> String? {
        if let rawPubKey = try keyManager.getPublicKey(connectionId) {
            return rawPubKey.base64URLEncodedString()
        }
       return nil
    }

    /// Attempts to remove all stored public and private keys mapped to the given `connectionId`.
    ///
    /// - Parameter connectionId: ConnectionId mapped to keys to be removed.
    /// - Throws: `KeyManagerError.UnhandledUnderlyingSecAPIError`,
    ///           `KeyManagerError.FatalError`
    func removeKeysForConnection(connectionId: String) throws {
        try keyManager.deleteKeyPair(connectionId)
    }

    /// Given an encrypted `base64Message` message from a peer connected at the given `connectionId`,
    /// decrypt the `base64Message` and then return the decrypted string.
    /// - Parameters:
    ///   - connectionId: Postbox ID attached to the private key needed for decryption.
    ///   - base64Message: Encrypted message with base64 encoding.
    /// - Throws: `KeyManagerError.KeyNotFound`,
    ///           `KeyManagerError.InvalidCipherText`,
    ///           `KeyManagerError.UnhandledUnderlyingSecAPIError`,
    ///           `KeyManagerError.FatalError`
    /// - Returns: The decrypted string or nil
    func decryptMessageForConnection(connectionId: String, base64Message: String) throws -> String? {
        if let encryptedBytes = Data(base64Encoded: base64Message) {
            let decryptedBase64 = try keyManager.decryptWithPrivateKey(connectionId, data: encryptedBytes)
            return String(decoding: decryptedBase64, as: UTF8.self)
        }
        return nil
    }
    
    /// Stores the `base64PublicKey` of the peer with the identifier of `peerConnectionId`.
    /// - Parameters:
    ///   - peerConnectionId: Postbox ID of the peer.
    ///   - base64PublicKey: The public key of the peer to store.
    /// - Throws: `KeyManagerError.DuplicateKey`,
    ///           `KeyManagerError.UnhandledUnderlyingSecAPIError`,
    ///           `KeyManagerError.FatalError`
    func storePublicKeyOfPeer(peerConnectionId: String, base64PublicKey: String) throws {
        if let rawPubKey = Data(base64URLEncoded: base64PublicKey) {
            try keyManager.addPublicKey(rawPubKey, name: peerConnectionId)
        }
    }

    /// Encrypt and pack  a `message` using the public key stored with the `peerConnectionId` and a newly generated
    /// AES key.
    ///
    /// - Parameters:
    ///   - peerConnectionId: The postbox ID of the peer.
    ///   - message: The message to encrypt.
    /// - Throws: `KeyManagerError.KeyNotFound`,
    ///           `KeyManagerError.UnhandledUnderlyingSecAPIError`,
    ///           `KeyManagerError.FatalError`
    /// - Returns: The encrypted packet as a URL safe base64 encoded `EncryptedPayload` or nil.
    func packEncryptedMessageForPeer(peerConnectionId: String, message: String) throws -> String? {
        
        // First, generate a symmetric key
        let tempId = UUID().uuidString
        try keyManager.generateSymmetricKey(tempId)
        
        // Encrypt the message with the symmetric key
        guard let rawData = message.data(using: .utf8) else {
            return nil
        }
        let AESEncryptedTextAsData = try keyManager.encryptWithSymmetricKey(tempId, data: rawData)
        
        // Encrypt the AES symmetric key with the peer's public key
        guard let AESKeyAsData = try keyManager.getSymmetricKey(tempId) else {
            return nil
        }

        let encryptedAESKey = try keyManager.encryptWithPublicKey(peerConnectionId, data: AESKeyAsData)
        
        // Pack it in an EncryptedPayload and return the JSON string representation of it
        let encryptedPayload = EncryptedPayload(cipherText: AESEncryptedTextAsData.base64URLEncodedString(),
                                                encryptedKey: encryptedAESKey.base64URLEncodedString())
        
        let encodedPayload = try JSONEncoder().encode(encryptedPayload)
        let payloadAsString = String(data: encodedPayload, encoding: .utf8)
        return payloadAsString
    }
    
    /// Given a packet `message` which is an encoded `EncryptedPayload`,
    /// from a peer who is connected on a given `connectionId`, unpack and decrypt the `message`
    /// and return the string contents.
    ///
    /// - Parameters:
    ///   - connectionId: Postbox identifier.
    ///   - encryptedPayloadString:  the plaintext JSON representation of an `EncryptedPayload`.
    /// - Returns: The unpacked decrypted message string.
     func unpackEncryptedMessageForConnection(connectionId: String, encryptedPayloadString: String) throws -> String? {
        
        // First decode the EncryptedPayload object
        guard let messageAsData = encryptedPayloadString.data(using: .utf8) else {
            return nil
        }
        let encryptedPayload = try JSONDecoder().decode(EncryptedPayload.self, from: messageAsData)

        // Next, decrypt the AES key with our private key
        guard let encryptedKeyAsData = Data(base64URLEncoded: encryptedPayload.encryptedKey) else {
            return nil
        }
        let symmetricKey = try keyManager.decryptWithPrivateKey(connectionId, data: encryptedKeyAsData)
        
        // Lastly, use the private key to decrypt the cipherText
        guard let encryptedCiphertextAsData = Data(base64URLEncoded: encryptedPayload.cipherText) else {
            return nil
        }
        let rawDecryptedCiphertextAsData = try keyManager.decryptWithSymmetricKey(symmetricKey, data: encryptedCiphertextAsData)
        return String(data: rawDecryptedCiphertextAsData, encoding: .utf8)
     }
}
