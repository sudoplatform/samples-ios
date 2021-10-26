//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoKeyManager

/// List of possible errors thrown by `JWT`.
///
/// - failedToEncode: Thrown when encapsulated attributes cannot be encoded to JWT.
/// - failedToDecode: Thrown when JWT cannot be decoded.
public enum JWTError: Error {
    case failedToEncode
    case failedToDecode
}

/// Encapsultes a JSON Web Token.
public class JWT {

    private struct Constants {

        struct Default {
            static let defaultAlgorithm = "RS256"
            static let defaultLifeTime = 3600.00
        }

        struct PropertyName {
            static let alg = "alg"
            static let kid = "kid"
            static let iss = "iss"
            static let aud = "aud"
            static let iat = "iat"
            static let nbf = "nbf"
            static let exp = "exp"
            static let sub = "sub"
            static let jti = "jti"
        }

    }

    /// URL to token issuer.
    public var issuer: String

    /// Intended audience of the token.
    public var audience: String

    /// Identity associated with the token.
    public var subject: String?

    /// Signature algorithm.
    public var algorithm: String

    /// External Key ID.
    public var keyId: String?

    /// Token expiry.
    public var expiry: Date

    /// Date/time at which the token was issued.
    public var issuedAt: Date

    /// Token is not valid before this time.
    public var notValidBefore: Date?

    /// Token ID.
    public var id: String?

    /// JWT payload.
    public var payload: [String: Any] = [:]

    /// Initialize and return `JWT` object.
    ///
    /// - Parameters:
    ///   - issuer: Token issuer
    ///   - audience: Intended audience of the token.
    ///   - subject: Identity associated with the token.
    ///   - id: Unique ID of this token.
    ///
    /// - Returns: Reference to the initialized object.
    public init(issuer: String, audience: String, subject: String, id: String) {
        self.algorithm = Constants.Default.defaultAlgorithm
        self.expiry = Date(timeIntervalSinceNow: Constants.Default.defaultLifeTime)
        self.issuedAt = Date()
        self.issuer = issuer
        self.audience = audience
        self.subject = subject
        self.id = id
    }

    /// Initialize and return the object.
    ///
    /// - Parameters:
    ///   - string: JWT string.
    ///   - keyManager: `KeyManager` instance used to validate the signature (optional).
    public init(string: String, keyManager: SudoKeyManager? = nil) throws {
        let array = string.split(separator: ".")

        guard array.count == 3 else {
            throw JWTError.failedToDecode
        }

        guard let headerData = JWT.urlSafeBase64Decode(string: String(array[0])),
            let header = headerData.toJSONObject() as? [String: Any] else {
            throw JWTError.failedToDecode
        }

        guard let payloadData = JWT.urlSafeBase64Decode(string: String(array[1])),
            let payload = payloadData.toJSONObject() as? [String: Any] else {
                throw JWTError.failedToDecode
        }

        self.payload = payload

        guard let signature = JWT.urlSafeBase64Decode(string: String(array[2])) else {
            throw JWTError.failedToDecode
        }

        guard let algorithm = header[Constants.PropertyName.alg] as? String,
            let kid = header[Constants.PropertyName.kid] as? String else {
                throw JWTError.failedToDecode
        }

        guard let expiry = payload[Constants.PropertyName.exp] as? Double,
            let issuedAt = payload[Constants.PropertyName.iat] as? Double,
            let issuer = payload[Constants.PropertyName.iss] as? String,
            let audience = payload[Constants.PropertyName.aud] as? String,
            let subject = payload[Constants.PropertyName.sub] as? String else {
            throw JWTError.failedToDecode
        }

        if let notValidBefore = payload[Constants.PropertyName.nbf] as? Double {
            self.notValidBefore = Date(timeIntervalSinceNow: notValidBefore)
        }

        if let id = payload[Constants.PropertyName.jti] as? String {
            self.id = id
        }

        self.algorithm = algorithm
        self.expiry = Date(timeIntervalSinceNow: expiry)
        self.issuedAt = Date(timeIntervalSinceNow: issuedAt)
        self.issuer = issuer
        self.audience = audience
        self.subject = subject
        self.keyId = kid

        let encoded = "\(array[0]).\(array[1])"

        guard let data = encoded.data(using: .utf8) else {
            throw JWTError.failedToDecode
        }

        if let keyManager = keyManager {
            guard try keyManager.verifySignatureWithPublicKey(kid, data: data, signature: signature) else {
                throw JWTError.failedToDecode
            }
        }
    }

    /// Sign and encode the token.
    ///
    /// - Parameters:
    ///   - keyManager: KeyManager instance used to generate a digital signature.
    ///   - keyId: Identifier of the key to use for generate the signature.
    public func signAndEncode(keyManager: SudoKeyManager, keyId: String) throws -> String {
        let headers = [Constants.PropertyName.alg: self.algorithm,
                       Constants.PropertyName.kid: self.keyId ?? keyId]
        let id = self.id ?? UUID().uuidString
        var payload: [String: Any] = [Constants.PropertyName.jti: id,
                                      Constants.PropertyName.iss: self.issuer,
                                      Constants.PropertyName.aud: self.audience,
                                      Constants.PropertyName.sub: self.subject ?? "",
                                      Constants.PropertyName.iat: round(self.issuedAt.timeIntervalSince1970),
                                      Constants.PropertyName.exp: round(self.expiry.timeIntervalSince1970)]

        if let notValidBefore = self.notValidBefore {
            payload[Constants.PropertyName.nbf] = round(notValidBefore.timeIntervalSince1970)
        }

        // Add any custom payload.
        for (name, value) in self.payload where payload[name] == nil {
            payload[name] = value
        }

        guard let encodedHeader = headers.toJSONData(),
            let encodedPayload = payload.toJSONData() else {
                throw JWTError.failedToEncode
        }

        let encoded = "\(self.urlSafeBase64Encode(data: encodedHeader)).\(self.urlSafeBase64Encode(data: encodedPayload))"
        guard let data = encoded.data(using: .utf8) else {
            throw JWTError.failedToEncode
        }

        let signature = try keyManager.generateSignatureWithPrivateKey(keyId, data: data)

        return "\(encoded).\(self.urlSafeBase64Encode(data: signature))"
    }

    private func urlSafeBase64Encode(data: Data) -> String {
        var encoded = data.base64EncodedString()
        encoded = encoded.replacingOccurrences(of: "+", with: "-", options: .literal, range: nil)
        encoded = encoded.replacingOccurrences(of: "/", with: "_", options: .literal, range: nil)
        encoded = encoded.replacingOccurrences(of: "=", with: "", options: .literal, range: nil)

        return encoded
    }

   static private func urlSafeBase64Decode(string: String) -> Data? {
        var decoded = string.replacingOccurrences(of: "-", with: "+", options: .literal, range: nil)
        decoded = decoded.replacingOccurrences(of: "_", with: "/", options: .literal, range: nil)
        if decoded.count % 4 != 0 {
            decoded.append(String(repeating: "=", count: 4 - decoded.count % 4))
        }

        return Data(base64Encoded: decoded)
    }

}
