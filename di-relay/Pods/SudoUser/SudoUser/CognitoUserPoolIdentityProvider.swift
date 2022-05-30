//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoLogging
import SudoKeyManager
import AWSCognitoIdentityProvider

/// Identity provider that uses Cognito user pool.
public class CognitoUserPoolIdentityProvider: IdentityProvider {

    /// Configuration parameter names.
    public struct Config {
        // AWS region hosting the identity service.
        static let region = "region"
        // AWS Cognito user pool ID of the identity service.
        static let poolId = "poolId"
        // ID of the client configured to access the user pool.
        static let clientId = "clientId"
    }

    private struct Constants {

        static let identityServiceName = "com.sudoplatform.identityservice"

        struct PasswordCharSet {
            static let allChars = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.!?;,&%$@#^*~")
            static let upperCaseChars = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
            static let lowerCaseChars = Array("abcdefghijklmnopqrstuvwxyz")
            static let numberChars = Array("0123456789")
            static let specialChars = Array(".!?;,&%$@#^*~")
        }

        struct CognitoChallengeParameter {
            static let audience = "audience"
            static let nonce = "nonce"
        }

        struct CognitoAuthenticationParameter {
            static let userName = "USERNAME"
            static let answer = "ANSWER"
            static let refreshToken = "REFRESH_TOKEN"
        }

        struct ServiceError {
            static let message = "message"
            static let decodingError = "sudoplatform.DecodingError"
            static let validationFailedError = "sudoplatform.identity.UserValidationFailed"
            static let missingRequiredInputError = "sudoplatform.identity.MissingRequiredInputs"
            static let deviceCheckAlreadyRegisteredError = "sudoplatform.identity.DeviceCheckAlreadyRegistered"
            static let testRegCheckFailedError = "sudoplatform.identity.TestRegCheckFailed"
            static let challengeTypeNotSupportedError = "sudoplatform.identity.ChallengeTypeNotSupported"
            static let alreadyRegisteredError = "sudoplatform.identity.AlreadyRegistered"
            static let tokenValidationError = "sudoplatform.identity.TokenValidationError"
            static let serviceError = "sudoplatform.ServiceError"
        }

    }

    struct RegistrationParameter {
        static let challengeType = "challengeType"
        static let answer = "answer"
        static let answerMetadata = "answerMetadata"
        static let buildType = "buildType"
        static let deviceId = "deviceId"
        static let publicKey = "publicKey"
        static let registrationId = "registrationId"
    }

    struct AuthenticationParameter {
        static let keyId = "keyId"
        static let tokenLifetime = "tokenLifetime"
        static let answer = "answer"
        static let challengeType = "challengeType"
    }

    private var userPool: AWSCognitoIdentityUserPool

    private var serviceConfig: AWSServiceConfiguration

    private var keyManager: SudoKeyManager

    private unowned var logger: Logger

    /// Initializes and returns a `CognitoUserPoolIdentityProvider` object.
    ///
    /// - Parameters:
    ///   - config: Configuration parameters for this identity provider.
    ///   - keyManager: `KeyManager` instance required for signing authentication token.
    ///   - logger: Logger used for logging.
    init(config: [String: Any],
         keyManager: SudoKeyManager,
         logger: Logger = Logger.sudoUserLogger) throws {
        self.logger = logger
        self.keyManager = keyManager

        self.logger.debug("Initializing with config: \(config)")

        // Validate the config.
        guard let region = config[Config.region] as? String,
            let poolId = config[Config.poolId] as? String,
            let clientId = config[Config.clientId] as? String else {
                throw SudoUserClientError.invalidConfig
        }

        guard let regionType = AWSEndpoint.regionTypeFrom(name: region) else {
            throw SudoUserClientError.invalidConfig
        }

        // Initialize the user pool instance.
        guard let serviceConfig = AWSServiceConfiguration(region: regionType, credentialsProvider: nil) else {
            throw SudoUserClientError.fatalError(description: "Failed to initialize AWS service configuration.")
        }

        self.serviceConfig = serviceConfig

        AWSCognitoIdentityProvider.register(with: self.serviceConfig, forKey: Constants.identityServiceName)

        let poolConfiguration = AWSCognitoIdentityUserPoolConfiguration(clientId: clientId, clientSecret: nil, poolId: poolId)
        AWSCognitoIdentityUserPool.register(with: serviceConfig, userPoolConfiguration: poolConfiguration, forKey: Constants.identityServiceName)
        guard let userPool = AWSCognitoIdentityUserPool(forKey: Constants.identityServiceName) else {
            throw SudoUserClientError.fatalError(description: "Failed to locate user pool instance with service name: \(Constants.identityServiceName)")
        }

        self.userPool = userPool
    }

    public func register(uid: String, parameters: [String: String]) async throws -> String {
        let validationData: [AWSCognitoIdentityUserAttributeType] = parameters.map { AWSCognitoIdentityUserAttributeType(name: $0.key, value: $0.value) }

        // Generate a random password that complies with default Cognito user pool password policy. This password is actually not used since
        // we use a custom authentication using a signing key but is required to create a user.
        let password = self.generatePassword(length: 50, upperCase: true, lowerCase: true, special: true, number: true)

        self.logger.debug("Performing sign-up with uid: \(uid), validationData: \(validationData)")

        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<String, Error>) in
            self.userPool.signUp(uid, password: password, userAttributes: nil, validationData: validationData).continueWith {(task) -> Any? in
                if let error = task.error as NSError? {
                    if let message = error.userInfo[Constants.ServiceError.message] as? String {
                        if message.contains(Constants.ServiceError.decodingError) {
                            continuation.resume(throwing: SudoUserClientError.invalidInput)
                        } else if message.contains(Constants.ServiceError.missingRequiredInputError) {
                            continuation.resume(throwing: SudoUserClientError.invalidInput)
                        } else if message.contains(Constants.ServiceError.validationFailedError) {
                            continuation.resume(throwing: SudoUserClientError.notAuthorized)
                        } else if message.contains(Constants.ServiceError.deviceCheckAlreadyRegisteredError) {
                            continuation.resume(throwing: SudoUserClientError.notAuthorized)
                        } else if message.contains(Constants.ServiceError.testRegCheckFailedError) {
                            continuation.resume(throwing: SudoUserClientError.notAuthorized)
                        } else if message.contains(Constants.ServiceError.tokenValidationError) {
                            continuation.resume(throwing: SudoUserClientError.notAuthorized)
                        } else if message.contains(Constants.ServiceError.challengeTypeNotSupportedError) {
                            continuation.resume(throwing: SudoUserClientError.notAuthorized)
                        } else if message.contains(Constants.ServiceError.alreadyRegisteredError) {
                            continuation.resume(throwing: SudoUserClientError.alreadyRegistered)
                        } else if message.contains(Constants.ServiceError.serviceError) {
                            continuation.resume(throwing: SudoUserClientError.serviceError)
                        } else {
                            continuation.resume(throwing: error)
                        }
                    } else {
                        continuation.resume(throwing: error)
                    }
                } else if let result = task.result, let userConfirmed = result.userConfirmed {
                    if userConfirmed.boolValue {
                        continuation.resume(returning: uid)
                    } else {
                        continuation.resume(throwing: SudoUserClientError.identityNotConfirmed)
                    }
                } else {
                    continuation.resume(
                        throwing: SudoUserClientError.fatalError(
                            description: "signUp result did not contain user confirmation status."
                        )
                    )
                }

                return nil
            }
        })
    }

    public func deregister(uid: String, accessToken: String) async throws -> String {
        let provider = AWSCognitoIdentityProvider(forKey: Constants.identityServiceName)
        guard let deleteUserRequest = AWSCognitoIdentityProviderDeleteUserRequest() else {
            throw SudoUserClientError.fatalError(description: "Failed to create a delete user request.")
        }

        deleteUserRequest.accessToken = accessToken

        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<String, Error>) in
            provider.deleteUser(deleteUserRequest).continueWith { (task) -> Any? in
                if let error = task.error {
                    continuation.resume(throwing: error)
                    return nil
                }

                continuation.resume(returning: uid)
                return nil
            }
        })
    }

    public func signIn(uid: String, parameters: [String: Any]) async throws -> AuthenticationTokens {
        guard let request = AWSCognitoIdentityProviderInitiateAuthRequest() else {
            throw SudoUserClientError.fatalError(description: "Failed to create Cognito authentication request.")
        }

        // Set up the request to use custom authentication.
        request.authFlow = .customAuth
        request.clientId = self.userPool.userPoolConfiguration.clientId
        request.authParameters = [Constants.CognitoAuthenticationParameter.userName: uid]

        self.logger.debug("Initiating auth with request: \(request)")
        let provider = AWSCognitoIdentityProvider(forKey: Constants.identityServiceName)

        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<AuthenticationTokens, Error>) in
            provider.initiateAuth(request).continueWith { response in
                if let error = response.error as NSError? {
                    if let message = error.userInfo[Constants.ServiceError.message] as? String {
                        if message.contains(Constants.ServiceError.decodingError) {
                            continuation.resume(throwing: SudoUserClientError.invalidInput)
                        } else if message.contains(Constants.ServiceError.missingRequiredInputError) {
                            continuation.resume(throwing: SudoUserClientError.invalidInput)
                        } else if message.contains(Constants.ServiceError.validationFailedError) {
                            continuation.resume(throwing: SudoUserClientError.notAuthorized)
                        } else if message.contains(Constants.ServiceError.serviceError) {
                            continuation.resume(throwing: SudoUserClientError.serviceError)
                        } else {
                            continuation.resume(throwing: error)
                        }
                    } else {
                        continuation.resume(throwing: error)
                    }
                    return nil
                }

                let respondToAuthChallengeRequest: AWSCognitoIdentityProviderRespondToAuthChallengeRequest
                do {
                    respondToAuthChallengeRequest = try self.generateChallengeResponse(uid: uid, parameters: parameters, initiateAuthResponse: response)
                } catch {
                    return continuation.resume(throwing: error)
                }

                // Respond to challenge.
                self.logger.debug("Responding to auth challenge with request: \(respondToAuthChallengeRequest)")
                provider.respond(toAuthChallenge: respondToAuthChallengeRequest, completionHandler: { (response, error) in
                    if let error = error {
                        guard let errorType = AWSCognitoIdentityProviderErrorType(rawValue: error._code) else {
                            return continuation.resume(throwing: error)
                        }

                        switch errorType {
                        case AWSCognitoIdentityProviderErrorType.notAuthorized:
                            return continuation.resume(throwing: SudoUserClientError.notAuthorized)
                        default:
                            return continuation.resume(throwing: error)
                        }
                    } else {
                        guard let idToken = response?.authenticationResult?.idToken,
                              let accessToken = response?.authenticationResult?.accessToken,
                              let refreshToken = response?.authenticationResult?.refreshToken,
                              let lifetime = response?.authenticationResult?.expiresIn?.intValue else {
                                  return continuation.resume(throwing: SudoUserClientError.authTokenMissing)
                              }

                        continuation.resume(
                            returning: AuthenticationTokens(
                                idToken: idToken,
                                accessToken: accessToken,
                                refreshToken: refreshToken,
                                lifetime: lifetime,
                                username: ""
                            )
                        )
                    }
                })

                return nil
            }
        })
    }

    public func refreshTokens(refreshToken: String) async throws -> AuthenticationTokens {
        guard let request = AWSCognitoIdentityProviderInitiateAuthRequest() else {
            throw SudoUserClientError.fatalError(description: "Failed to create Cognito authentication request.")
        }

        // Set up the request to use refresh token to authenticate.
        request.authFlow = .refreshTokenAuth
        request.clientId = self.userPool.userPoolConfiguration.clientId
        request.authParameters = [Constants.CognitoAuthenticationParameter.refreshToken: refreshToken]

        let provider = AWSCognitoIdentityProvider(forKey: Constants.identityServiceName)

        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<AuthenticationTokens, Error>) in
            provider.initiateAuth(request).continueWith { response in
                if let error = response.error {
                    guard let errorType = AWSCognitoIdentityProviderErrorType(rawValue: error._code) else {
                        return continuation.resume(throwing: error)
                    }

                    switch errorType {
                    case AWSCognitoIdentityProviderErrorType.notAuthorized:
                        continuation.resume(throwing: SudoUserClientError.notAuthorized)
                    default:
                        continuation.resume(throwing: error)
                    }

                    return nil
                }

                guard let idToken = response.result?.authenticationResult?.idToken,
                      let accessToken = response.result?.authenticationResult?.accessToken,
                      let lifetime = response.result?.authenticationResult?.expiresIn?.intValue else {
                          continuation.resume(throwing: SudoUserClientError.authTokenMissing)
                          return nil
                      }

                continuation.resume(
                    returning: AuthenticationTokens(
                        idToken: idToken,
                        accessToken: accessToken,
                        refreshToken: refreshToken,
                        lifetime: lifetime,
                        username: ""
                    )
                )
                return nil
            }
        })
    }
    
    public func signOut(refreshToken: String) async throws {
        guard let request = AWSCognitoIdentityProviderRevokeTokenRequest() else {
            throw SudoUserClientError.fatalError(description: "Failed to create revoke token request.")
        }

        request.clientId = self.userPool.userPoolConfiguration.clientId
        request.token = refreshToken

        let provider = AWSCognitoIdentityProvider(forKey: Constants.identityServiceName)

        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Void, Error>) in
            provider.revokeToken(request).continueWith { response in
                if let error = response.error {
                    guard let errorType = AWSCognitoIdentityProviderErrorType(rawValue: error._code) else {
                        return continuation.resume(throwing: error)
                    }

                    switch errorType {
                    case AWSCognitoIdentityProviderErrorType.notAuthorized:
                        continuation.resume(throwing: SudoUserClientError.notAuthorized)
                    default:
                        continuation.resume(throwing: error)
                    }

                    return nil
                }

                continuation.resume()
                return nil
            }
        })
    }

    public func globalSignOut(accessToken: String) async throws {
        guard let request = AWSCognitoIdentityProviderGlobalSignOutRequest() else {
            throw SudoUserClientError.fatalError(description: "Failed to create Cognito global sign out request.")
        }

        request.accessToken = accessToken

        let provider = AWSCognitoIdentityProvider(forKey: Constants.identityServiceName)

        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Void, Error>) in
            provider.globalSignOut(request).continueWith { response in
                if let error = response.error {
                    guard let errorType = AWSCognitoIdentityProviderErrorType(rawValue: error._code) else {
                        return continuation.resume(throwing: error)
                    }

                    switch errorType {
                    case AWSCognitoIdentityProviderErrorType.notAuthorized:
                        continuation.resume(throwing: SudoUserClientError.notAuthorized)
                    default:
                        continuation.resume(throwing: error)
                    }

                    return nil
                }

                continuation.resume()
                return nil
            }
        })
    }

    /// Generate a random password with specified password policy.
    ///
    /// - Parameters:
    ///   - length: Password length.
    ///   - upperCase: Requires 1 uppercase character.
    ///   - lowerCase: Requires 1 lowercase character.
    ///   - special: Requires 1 special character.
    ///   - number: Requires 1 numeric character.
    ///
    /// - Returns: Generated password.
    func generatePassword(length: UInt, upperCase: Bool, lowerCase: Bool, special: Bool, number: Bool) -> String {

        var password: [Character] = []

        if upperCase {
            let index = Int(arc4random()) % (Constants.PasswordCharSet.upperCaseChars.count - 1)
            password.append(Constants.PasswordCharSet.upperCaseChars[index])
        }

        if lowerCase {
            let index = Int(arc4random()) % (Constants.PasswordCharSet.lowerCaseChars.count - 1)
            password.append(Constants.PasswordCharSet.lowerCaseChars[index])
        }

        if special {
            let index = Int(arc4random()) % (Constants.PasswordCharSet.specialChars.count - 1)
            password.append(Constants.PasswordCharSet.specialChars[index])
        }

        if number {
            let index = Int(arc4random()) % (Constants.PasswordCharSet.numberChars.count - 1)
            password.append(Constants.PasswordCharSet.numberChars[index])
        }

        while password.count < length {
            let index = Int(arc4random()) % (Constants.PasswordCharSet.allChars.count - 1)
            password.append(Constants.PasswordCharSet.allChars[index])
        }

        return String(password.shuffled())
    }

    private func generateChallengeResponse(uid: String, parameters: [String: Any], initiateAuthResponse: AWSTask<AWSCognitoIdentityProviderInitiateAuthResponse>) throws -> AWSCognitoIdentityProviderRespondToAuthChallengeRequest {
        guard let challengeName = initiateAuthResponse.result?.challengeName else {
            throw SudoUserClientError.fatalError(description: "Challenge name missing from initiateAuth result.")
        }

        guard let session = initiateAuthResponse.result?.session else {
            throw SudoUserClientError.fatalError(description: "Session missing from initiateAuth result.")
        }

        guard let respondToAuthChallengeRequest = AWSCognitoIdentityProviderRespondToAuthChallengeRequest() else {
            throw SudoUserClientError.fatalError(description: "Failed to create Cognito challenge response request.")
        }

        respondToAuthChallengeRequest.clientId = self.userPool.userPoolConfiguration.clientId
        respondToAuthChallengeRequest.challengeName = challengeName
        respondToAuthChallengeRequest.session = session

        if let challengeType = parameters[AuthenticationParameter.challengeType] as? String, challengeType == "FSSO" {
            guard let answer = parameters[AuthenticationParameter.answer] as? String else {
                throw SudoUserClientError.fatalError(description: "Answer missing from FSSO authentication parameters.")
            }

            respondToAuthChallengeRequest.challengeResponses = [Constants.CognitoAuthenticationParameter.userName: uid, Constants.CognitoAuthenticationParameter.answer: answer]
            respondToAuthChallengeRequest.clientMetadata = [AuthenticationParameter.challengeType: challengeType]
        } else {
            guard let keyId = parameters[AuthenticationParameter.keyId] as? String else {
                throw SudoUserClientError.fatalError(description: "Key ID not provided.")
            }

            guard let audience = initiateAuthResponse.result?.challengeParameters?[Constants.CognitoChallengeParameter.audience] else {
                throw SudoUserClientError.fatalError(description: "Audience challenge parameter missing from initiateAuth result.")
            }

            guard let nonce = initiateAuthResponse.result?.challengeParameters?[Constants.CognitoChallengeParameter.nonce] else {
                throw SudoUserClientError.fatalError(description: "Audience challenge parameter missing from initiateAuth result.")
            }

            // Default token lifetime of private key signed token is 5 minutes unless specified otherwise.
            let tokenLifetime = parameters[AuthenticationParameter.tokenLifetime] as? Int ?? 300

            // Challenge requires the private key signed JWT as the answer.
            let jwt = JWT(issuer: uid, audience: audience, subject: uid, id: nonce)
            jwt.expiry = Date(timeIntervalSinceNow: Double(tokenLifetime))

            let encodedJWT = try jwt.signAndEncode(keyManager: self.keyManager, keyId: keyId)

            respondToAuthChallengeRequest.challengeResponses = [Constants.CognitoAuthenticationParameter.userName: uid, Constants.CognitoAuthenticationParameter.answer: encodedJWT]
        }

        return respondToAuthChallengeRequest
    }

}
