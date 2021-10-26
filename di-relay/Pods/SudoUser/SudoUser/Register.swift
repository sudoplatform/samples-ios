//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoLogging
import AWSCognitoIdentityProvider
import SudoKeyManager

/// List of possible errors returned by `RegisterOperation`.
///
/// - noAnswer: No answer was provided during registration.
/// - invalidChallenge: Challenge provided was invalid.
/// - identityNotConfirmed: identity is not confirmed hence cannot sign in yet.
/// - fatalError: Indicates that a fatal error occurred. This could be due to
///     coding error, out-of-memory condition or other conditions that is
///     beyond control of `RegisterOperation` implementation.
public enum RegisterOperationError: Error {
    case noAnswer
    case invalidChallenge
    case identityNotConfirmed
    case fatalError(description: String)
}

/// Performs register operation.
class Register: UserOperation {

    private struct Constants {

        struct KeyName {
            static let symmetricKeyId = "symmetricKeyId"
            static let userKeyId = "userKeyId"
        }

        struct ValidationDataName {
            static let challengeType = "challengeType"
            static let answer = "answer"
            static let vendorId = "vendorId"
            static let publicKey = "publicKey"
            static let registrationId = "registrationId"
        }

        struct Limit {
            static let maxValidationDataSize = 2048
        }

    }

    /// ID of the registered identity (user).
    public private(set) var uid: String?

    private let challenge: RegistrationChallenge

    private let vendorId: UUID?

    private let registrationId: String

    private let publicKey: PublicKey

    private unowned let identityProvider: IdentityProvider

    /// Initializes and returns a `Register` operation.
    ///
    /// - Parameters:
    ///   - challenge: The registration challenge that has the `answer` property set.
    ///   - vendorId: An alphanumeric string that uniquely identifies a device to the app’s vendor. Obtained via
    ///     `identifierForVendor` property of `UIDevice` class.
    ///   - registrationId: The registration ID  used for uniquely identifying the registration request in case it fails.
    ///   - publicKey: Public key to used for authentication.
    ///   - identityProvider: Identity provider to register against.
    ///   - logger: Logger used for logging.
    init(challenge: RegistrationChallenge,
         vendorId: UUID?,
         registrationId: String?,
         publicKey: PublicKey,
         identityProvider: IdentityProvider,
         logger: Logger = Logger.sudoUserLogger) {
        self.challenge = challenge
        self.vendorId = vendorId
        self.registrationId = registrationId ?? UUID().uuidString
        self.publicKey = publicKey
        self.identityProvider = identityProvider
        super.init(logger: logger)
    }

    override func execute() {
        self.logger.info("Performing sign-up with registration ID: \(self.registrationId)")

        let uuid = UUID().uuidString
        var registrationParameters: [String: String] = [:]
        registrationParameters[CognitoUserPoolIdentityProvider.RegistrationParameter.challengeType] = self.challenge.type.rawValue
        if let answer = self.challenge.answer {
            if answer.count > Constants.Limit.maxValidationDataSize {
                // Set dummy answer for backward compatibility.
                registrationParameters[CognitoUserPoolIdentityProvider.RegistrationParameter.answer] = "dummy_answer"

                // If the answer exceeds the validation data size limit then divide up the answer to parts.
                let parts = answer.chunks(size: Constants.Limit.maxValidationDataSize)
                var parameters: [(String, String)] = []
                for (index, part) in parts.enumerated() {
                    parameters.append(("\(CognitoUserPoolIdentityProvider.RegistrationParameter.answer).\(index)", part))
                }

                registrationParameters.merge(parameters) {(_, new) in new}
                let answerMetadata: [String: Any] = ["parts": parameters.map { $0.0 }]
                guard let jsonData = answerMetadata.toJSONData() else {
                    self.error = RegisterOperationError.fatalError(description: "Cannot serialize the answer metadata.")
                    return self.done()
                }
                registrationParameters[CognitoUserPoolIdentityProvider.RegistrationParameter.answerMetadata] = String(data: jsonData, encoding: .utf8)
            } else {
                registrationParameters[CognitoUserPoolIdentityProvider.RegistrationParameter.answer] = answer
            }
        }
        registrationParameters[CognitoUserPoolIdentityProvider.RegistrationParameter.registrationId] = self.registrationId

        if let vendorId = self.vendorId {
            let data = withUnsafePointer(to: vendorId.uuid) {
                Data(bytes: $0, count: MemoryLayout.size(ofValue: vendorId.uuid))
            }

            registrationParameters[CognitoUserPoolIdentityProvider.RegistrationParameter.deviceId] = data.base64EncodedString()
        }

        if let buildType = challenge.buildType {
            registrationParameters[CognitoUserPoolIdentityProvider.RegistrationParameter.buildType] = buildType
        }

        do {
            guard let encodedKey = try String(data: publicKey.toData(), encoding: .utf8) else {
                self.error = RegisterOperationError.fatalError(description: "Cannot serialize the public key.")
                return self.done()
            }

            registrationParameters[CognitoUserPoolIdentityProvider.RegistrationParameter.publicKey] = encodedKey

            try self.identityProvider.register(uid: uuid, parameters: registrationParameters) { (result) in
                defer {
                    self.done()
                }

                switch result {
                case let .success(uid):
                    self.uid = uid
                case let .failure(cause):
                    self.error = cause
                }
            }
        } catch let error {
            self.error = error
            self.done()
        }
    }

}

/// Performs register operation with an authentication provider.
class RegisterWithAuthenticationProvider: UserOperation {

    private struct Constants {

        struct KeyName {
            static let symmetricKeyId = "symmetricKeyId"
            static let userKeyId = "userKeyId"
        }

        struct ValidationDataName {
            static let challengeType = "challengeType"
            static let answer = "answer"
            static let vendorId = "vendorId"
            static let publicKey = "publicKey"
            static let registrationId = "registrationId"
        }

    }

    /// ID of the registered identity (user).
    public private(set) var uid: String?

    private var authenticationProvider: AuthenticationProvider

    private var registrationId: String

    private var publicKey: PublicKey?

    private unowned var identityProvider: IdentityProvider

    /// Initializes and returns a `RegisterWithAuthenticationProvider` operation.
    ///
    /// - Parameters:
    ///   - authenticationProvider: Authentication provider to authenticate the registration request.
    ///   - registrationId: The registration ID  used for uniquely identifying the registration request in case it fails.
    ///   - publicKey: Public key to use for authentication.
    ///   - identityProvider: Identity provider to register against.
    ///   - logger: Logger to use for logging.
    init(authenticationProvider: AuthenticationProvider,
         registrationId: String?,
         publicKey: PublicKey?,
         identityProvider: IdentityProvider,
         logger: Logger = Logger.sudoUserLogger) {
        self.authenticationProvider = authenticationProvider
        self.registrationId = registrationId ?? UUID().uuidString
        self.publicKey = publicKey
        self.identityProvider = identityProvider
        super.init(logger: logger)
    }

    override func execute() {
        self.logger.info("Performing sign-up with registration ID: \(self.registrationId)")

        var registrationParameters: [String: String] = [:]

        self.authenticationProvider.getAuthenticationInfo { (result) in
            switch result {
            case .success(let authInfo):
                let token = authInfo.toString()

                let jwt: JWT
                do {
                    jwt = try JWT(string: token)
                } catch {
                    self.error = error
                    return self.done()
                }

                let uuid = (jwt.payload["sub"] as? String) ?? UUID().uuidString

                registrationParameters[CognitoUserPoolIdentityProvider.RegistrationParameter.challengeType] = type(of: authInfo).type
                registrationParameters[CognitoUserPoolIdentityProvider.RegistrationParameter.answer] = authInfo.toString()
                registrationParameters[CognitoUserPoolIdentityProvider.RegistrationParameter.registrationId] = self.registrationId

                do {
                    if let publicKey = self.publicKey {
                        guard let encodedKey = try String(data: publicKey.toData(), encoding: .utf8) else {
                            self.error = RegisterOperationError.fatalError(description: "Cannot serialize the public key.")
                            return self.done()
                        }

                        registrationParameters[CognitoUserPoolIdentityProvider.RegistrationParameter.publicKey] = encodedKey
                    }

                    try self.identityProvider.register(uid: uuid, parameters: registrationParameters) { (result) in
                        defer {
                            self.done()
                        }

                        switch result {
                        case let .success(uid):
                            self.uid = uid
                        case let .failure(cause):
                            self.error = cause
                        }
                    }
                } catch let error {
                    self.error = error
                    self.done()
                }
            case .failure(let error):
                self.error = error
                self.done()
            }
        }
    }

}

fileprivate extension Array {
    func chunks(size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

fileprivate extension String {
    func chunks(size: Int) -> [String] {
        map { $0 }.chunks(size: size).compactMap { String($0) }
    }
}
