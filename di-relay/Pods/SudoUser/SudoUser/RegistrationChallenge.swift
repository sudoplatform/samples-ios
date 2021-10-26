//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// List of valid challenge types.
public enum ChallengeType: String {
    case deviceCheck    = "DEVICE_CHECK"
    case test    = "TEST"
    case fsso    = "FSSO"
    case unknown = "UNKNOWN"
}

/// Encapsulates a registration challenge that must be answered in order
/// to successfully register a new user.
public class RegistrationChallenge: JSONSerializableObject {

    private struct Constants {

        struct PropertyName {
            static let type = "type"
            static let nonce = "nonce"
            static let expiry = "expiry"
            static let answer = "answer"
        }

    }

    /// Challenge type.
    public var type: ChallengeType {
        get {
            guard let value = self.getPropertyAsString(Constants.PropertyName.type) else {
                return .unknown
            }

            return ChallengeType(rawValue: value) ?? .unknown
        }
        set {
            self.setProperty(Constants.PropertyName.type, value: newValue.rawValue)
        }
    }

    /// One time use and short lived nonce for verifying the challenge.
    public var nonce: String?

    /// Challenge expiry.
    public var expiry: Date?

    /// Answer to the challenge.
    public var answer: String?

    /// Build type of the client from which the challenge was created, e.g. "debug" or "release".
    public var buildType: String?

    /// Initializes and returns a RegistrationChallenge object.
    ///
    /// - Parameters:
    ///   - nonce: The nonce used for challenge verification.
    ///   - expiry: The date when the challenge expires.
    ///   - properties: The object properties.
    convenience init?(nonce: String?, expiry: Date?, properties: [String: Any]) {
        self.init(properties: properties)
        self.nonce = nonce
        self.expiry = expiry
    }

    /// Creates and returns the response to the given challenge.
    ///
    /// - Returns: Challenge response.
    public func createResponse() -> JSONSerializableObject {
        let answer = JSONSerializableObject()
        answer.setProperty(Constants.PropertyName.type, value: self.type.rawValue)
        answer.setProperty(Constants.PropertyName.answer, value: self.answer)

        let response = JSONSerializableObject()
        response.setProperty(Constants.PropertyName.nonce, value: self.nonce)
        response.setProperty(Constants.PropertyName.answer, value: answer)

        return response
    }

}
