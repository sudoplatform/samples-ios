//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import CommonCrypto

/// Encapsulates a public key used for authentication and encryption.
public class PublicKey: JSONSerializableObject {

    private struct Constants {

        struct Property {
            static let keyId = "keyId"
            static let algorithm = "algorithm"
            static let symmetricAlgorithm = "symmetricAlgorithm"
            static let publicKey = "publicKey"
        }

        struct Encryption {
            static let AESKeySize = kCCKeySizeAES256
            static let AESBlockSize = kCCBlockSizeAES128
            static let algorithmRSA = "RSA"
            static let algorithmAES128 = "AES/128"
            static let algorithmAES256 = "AES/256"
            static let defaultSymmetricKeyName = "symmetrickey"
        }

    }

    /// Key ID.
    var keyId: String? {
        get { return getPropertyAsString(Constants.Property.keyId) }
        set { setProperty(Constants.Property.keyId, value: newValue) }
    }

    /// Public key data in PKCS1 RSAPublicKey format.
    var publicKey: Data? {
        get { return getPropertyAsString(Constants.Property.publicKey).flatMap { Data(base64Encoded: $0) } }
        set { setProperty(Constants.Property.publicKey, value: newValue?.base64EncodedString()) }
    }

    /// Public key crypto algorithm associated with the encrypt symmetric key.
    var algorithm: String? {
        get { return getPropertyAsString(Constants.Property.algorithm) }
        set { setProperty(Constants.Property.algorithm, value: newValue) }
    }

    /// Symmetric key algorithm used to encrypt payload.
    var symmetricAlgorithm: String? {
        get { return getPropertyAsString(Constants.Property.symmetricAlgorithm) }
        set { setProperty(Constants.Property.symmetricAlgorithm, value: newValue) }
    }

    /// Intializes a new `PublicKey` instance.
    ///
    /// - Parameters:
    ///   - publicKey: Public key data.
    ///   - keyId: Key ID.
    ///
    /// - Returns: A new initialized `Credential` instance.
    convenience init(publicKey: Data, keyId: String) {
        self.init()
        self.publicKey = publicKey
        self.keyId = keyId
        self.algorithm = Constants.Encryption.algorithmRSA
        self.symmetricAlgorithm = Constants.Encryption.AESKeySize == kCCKeySizeAES128 ? Constants.Encryption.algorithmAES128 : Constants.Encryption.algorithmAES256
    }

}
