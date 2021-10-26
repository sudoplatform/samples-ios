//
//  KeyAttributeValue.swift
//  KeyManagerIOS
//
//  Created by Lachlan McCulloch on 10/6/19.
//  Copyright © 2019 Anonyome Labs, Inc. All rights reserved.
//

/// Key attribute value types.
public enum KeyAttributeValue: Hashable {
    case stringValue(String)
    case boolValue(Bool)
    case intValue(Int)
    case dataValue(Data)
    case keyTypeValue(KeyType)
}

/// Supported key types. Declared as String so that when keys are exported the type is easily recognizable.
///
/// - privateKey: RSA private key.
/// - publicKey: RSA public key.
/// - symmetricKey: AES key.
/// - password: Password or any other generic data to store securely.
/// - unknown: Key type is either unspecified or unknown.
public enum KeyType: String {
    case privateKey = "PrivateKey"
    case publicKey = "PublicKey"
    case symmetricKey = "SymmetricKey"
    case password = "Password"
    case unknown = "Unknown"
}
