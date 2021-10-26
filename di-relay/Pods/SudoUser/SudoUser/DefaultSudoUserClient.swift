//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoKeyManager
import SudoLogging
import AWSCognitoIdentityProvider
import AWSCore
import AWSMobileClient
import AWSS3
import AWSAppSync
import SudoConfigManager

/// Default implementation for `SudoUserClient`.
public class DefaultSudoUserClient: SudoUserClient {

    /// Configuration parameter names.
    public struct Config {

        // Configuration namespace.
        struct Namespace {
            // Identity service related configuration.
            static let identityService = "identityService"
            // Federated sign in related configuration
            static let federatedSignIn = "federatedSignIn"
        }

        struct IdentityService {
            // AWS region hosting the identity service.
            static let region = "region"
            // AWS Cognito user pool ID of the identity service.
            static let userPoolId = "poolId"
            // ID of the client configured to access the user pool.
            static let clientId = "clientId"
            // Refresh token lifetime.
            static let refreshTokenLifetime = "refreshTokenLifetime"
            // Lifetime of the private key based authentication token.
            static let tokenLifetime = "tokenLifetime"
            // AWS Cognito identity pool ID of the identity service.
            static let identityPoolId = "identityPoolId"
            // API URL.
            static let apiUrl = "apiUrl"
            // API key.
            static let apiKey = "apiKey"
            /// Registration methods.
            static let registrationMethods = "registrationMethods"
        }

        struct PushChallenge {
            // AWS region hosting the push challenge service.
            static let region = "region"
            // API URL.
            static let apiUrl = "apiUrl"
            // API key.
            static let apiKey = "apiKey"
        }

        struct S3 {
            // Service client key for S3 client specific to Sudo platform.
            static let serviceClientKey = "com.sudoplatform.s3"
        }

    }

    private struct Constants {

        struct KeyName {
            static let symmetricKeyId = "symmetricKeyId"
            static let userId = "userId"
            static let userKeyId = "userKeyId"
            static let idToken = "idToken"
            static let accessToken = "accessToken"
            static let refreshToken = "refreshToken"
            static let tokenExpiry = "tokenExpiry"
            static let refreshTokenExpiry = "refreshTokenExpiry"
            static let identityId = "identityId"
        }

        struct Encryption {
            static let algorithmRSA = "RSA"
            static let algorithmAES128 = "AES/128"
            static let algorithmAES256 = "AES/256"
            static let defaultSymmetricKeyName = "symmetrickey"
        }

        struct KeyManager {
            static let defaultKeyManagerServiceName = "com.sudoplatform.appservicename"
            static let defaultKeyManagerKeyTag = "com.sudoplatform"
        }

        struct Auth {
            static let authTokenDefaultExpiry = 7200.0
            static let authTokenExpiryClockSkewToleranceInSec = 600.0
        }

    }

    /// Default logger for SudoUserClient.
    private let logger: Logger

    /// KeyManager instance used for cryptographic operations.
    private var keyManager: SudoKeyManager

    /// GraphQL client used calling Identity Service API.
    private var apiClient: AWSAppSyncClient?

    public var version: String {
        return SUDO_USER_VERSION
    }

    /// A tuple encapsulating the authentication token and its expiry.
    private var authToken: (token: String, expiry: Date)?

    private let queue = DispatchQueue(label: "com.sudoplatform.sudouser")

    private var registerOperationQueue = UserOperationQueue()

    private var signInOperationQueue = UserOperationQueue()

    /// Identity provider to use for registration and authentication.
    private var identityProvider: IdentityProvider

    /// Lifetime of private key based token in seconds.
    private var tokenLifetime: Int = 300

    /// Refresh token lifetime in days.
    private var refreshTokenLifetime: Int = 60

    /// Federated authentication UI.
    private var authUI: AuthUI?

    /// Credentials provider required to access AWS resources such as S3.
    private lazy var credentialsProvider: CredentialsProvider = {
        return AWSCredentialsProvider(
            client: self,
            regionType: self.regionType,
            userPoolId: self.userPoolId,
            identityPoolId: self.identityPoolId
        )
    }()

    /// GraphQL authentication provider.
    private lazy var graphQLAuthProvider: GraphQLAuthProvider = {
        return GraphQLAuthProvider(client: self)
    }()

    /// AWS region hosting identity service as `String`.
    private let region: String

    /// AWS region hosting identity service as `AWSRegionType`. Some AWS APIs
    /// require this instead of `String` variant of it.
    private let regionType: AWSRegionType

    /// ID of AWS Cognito User Pool used by identity service.
    private let userPoolId: String

    /// ID of AWS Cognito Identity Pool used by identity service.
    private let identityPoolId: String

    /// Config provider used to initialize an `AWSAppSyncClient` that can talk to GraphQL endpoint of
    /// the identity service.
    private let configProvider: SudoUserClientConfigProvider

    /// List of supported registration challenge types.
    private let challengeTypes: [ChallengeType]

    /// List of sign in status observers.
    private var signInStatusObservers: [String: SignInStatusObserver] = [:]

    /// Intializes a new `DefaultSudoUserClient` instance. It uses configuration parameters defined in
    /// `sudoplatformconfig.json` file located in the app bundle.
    ///
    /// - Parameters:
    ///   - keyNamespace: Namespace to use for the keys and passwords. This has to be unique per client
    ///         per app to avoid different apps (with keychain sharing) or different clients creating conflicting
    ///         keys.
    ///   - logger: A logger to use for logging messages. If none provided then a default
    ///         internal logger will be used.
    convenience public init(keyNamespace: String, logger: Logger? = nil) throws {
        guard let configManager = DefaultSudoConfigManager(),
            let identityServiceConfig = DefaultSudoConfigManager()?.getConfigSet(namespace: Config.Namespace.identityService) else {
            throw SudoUserClientError.identityServiceConfigNotFound
        }

        var config: [String: Any] = [:]
        config[Config.Namespace.identityService] = identityServiceConfig

        if let federatedSignInConfig = configManager.getConfigSet(namespace: Config.Namespace.federatedSignIn) {
            config[Config.Namespace.federatedSignIn] = federatedSignInConfig
        }

        try self.init(config: config, keyNamespace: keyNamespace, logger: logger)
    }

    /// Intializes a new `DefaultSudoUserClient` instance.
    ///
    /// - Parameters:
    ///   - config: Configuration parameters for the client.
    ///   - keyNamespace: Namespace to use for the keys and passwords.
    ///   - credentialsProvider: Credentials provider to use for obtaining AWS credential. Mainly used for unit testing.
    ///   - identityProvider: Identity provider to use to user management. Mainly used for unit testing.
    ///   - registrationChallengeClient: GraphQL client to use for communicating with the challenge service.
    ///         Mainly used for unit testing.
    ///   - apiClient: GrpahQL client to use for Identity Service API. Mainly used for unit testing.
    ///   - authUI: AuthUI used for presenting federated sign in UI. Mainly used for unit testing.
    ///   - logger: A logger to use for logging messages. If none provided then a default
    ///         internal logger will be used.
    public init(config: [String: Any],
                keyNamespace: String,
                credentialsProvider: CredentialsProvider? = nil,
                identityProvider: IdentityProvider? = nil,
                registrationChallengeClient: GraphQLClient? = nil,
                apiClient: AWSAppSyncClient? = nil,
                authUI: AuthUI? = nil,
                logger: Logger? = nil) throws {
        let logger = logger ?? Logger.sudoUserLogger
        self.logger = logger

        self.logger.debug("Initializing with config: \(config), keyNamespace: \(keyNamespace)")

        let keyManager = SudoKeyManagerImpl(serviceName: Constants.KeyManager.defaultKeyManagerServiceName,
                                        keyTag: Constants.KeyManager.defaultKeyManagerKeyTag,
                                        namespace: keyNamespace)
        self.keyManager = keyManager

        guard let identityServiceConfig = config[Config.Namespace.identityService] as? [String: Any] else {
            throw SudoUserClientError.identityServiceConfigNotFound
        }

        try self.identityProvider = identityProvider ?? CognitoUserPoolIdentityProvider(config: identityServiceConfig, keyManager: keyManager, logger: logger)

        guard let region = identityServiceConfig[Config.IdentityService.region] as? String,
            let regionType = AWSEndpoint.regionTypeFrom(name: region),
            let userPoolId = identityServiceConfig[Config.IdentityService.userPoolId] as? String,
            let identityPoolId = identityServiceConfig[Config.IdentityService.identityPoolId] as? String else {
                throw SudoUserClientError.invalidConfig
        }

        self.region = region
        self.regionType = regionType
        self.userPoolId = userPoolId
        self.identityPoolId = identityPoolId
        self.refreshTokenLifetime = identityServiceConfig[Config.IdentityService.refreshTokenLifetime] as? Int ?? 60

        if let challengeTypes = identityServiceConfig[Config.IdentityService.registrationMethods] as? [String] {
            self.challengeTypes = challengeTypes.compactMap { ChallengeType(rawValue: $0) }
        } else {
            self.challengeTypes = []
        }

        if let tokenLifetime = config[Config.IdentityService.tokenLifetime] as? Int {
            self.tokenLifetime = tokenLifetime
        }

        guard let configProvider = SudoUserClientConfigProvider(config: identityServiceConfig) else {
            throw SudoUserClientError.invalidConfig
        }

        self.configProvider = configProvider

        if let federatedSignInConfig = config[Config.Namespace.federatedSignIn] as? [String: Any] {
            self.refreshTokenLifetime = federatedSignInConfig[Config.IdentityService.refreshTokenLifetime] as? Int ?? 60
            try self.authUI = authUI ?? CognitoAuthUI(config: federatedSignInConfig)
        }

        if let apiClient = apiClient {
            self.apiClient = apiClient
        } else {
            // Set up an `AWSAppSyncClient` to call GraphQL API that requires sign in.
            let appSyncConfig = try AWSAppSyncClientConfiguration(appSyncServiceConfig: configProvider,
                                                                  userPoolsAuthProvider: self.graphQLAuthProvider,
                                                                  urlSessionConfiguration: URLSessionConfiguration.default,
                                                                  cacheConfiguration: AWSAppSyncCacheConfiguration.inMemory,
                                                                  connectionStateChangeHandler: nil,
                                                                  s3ObjectManager: nil,
                                                                  presignedURLClient: nil,
                                                                  retryStrategy: .aggressive)
            self.apiClient = try AWSAppSyncClient(appSyncConfig: appSyncConfig)
            self.apiClient?.apolloClient?.cacheKeyForObject = { $0["id"] }
        }

        if let credentialsProvider = credentialsProvider {
            self.credentialsProvider = credentialsProvider
        }
    }

    public func isRegistered() -> Bool {
        var username: String?
        do {
            username = try self.getUserName()
        } catch {
            self.logger.error("Failed to retrieve key from the keychain.")
        }

        return username != nil
    }

    public func getSymmetricKeyId() throws -> String {
        guard let symmKeyIdData = try self.keyManager.getPassword(Constants.KeyName.symmetricKeyId), let symmetricKeyId = String(data: symmKeyIdData, encoding: .utf8) else {
            throw SudoUserClientError.fatalError(description: "Symmetric key missing.")
        }

        return symmetricKeyId
    }

    public func reset() throws {
        self.logger.info("Resetting client.")

        do {
            try self.keyManager.removeAllKeys()
            self.credentialsProvider.reset()
        } catch let error {
            let message = "Unexpected error occurred while trying to remove all keys: \(error)."
            self.logger.error(message)
            throw SudoUserClientError.fatalError(description: message)
        }
    }

    public func register(challenge: RegistrationChallenge,
                         vendorId: UUID? = nil,
                         registrationId: String? = nil,
                         completion: @escaping (Swift.Result<String, Error>) -> Void) throws {
        self.logger.info("Performing registration.")

        try self.queue.sync {
            guard !isRegistered() else {
                throw SudoUserClientError.alreadyRegistered
            }

            guard self.registerOperationQueue.operationCount == 0 else {
                throw SudoUserClientError.registerOperationAlreadyInProgress
            }

            // Clear out any partial registration data.
            try self.reset()

            let publicKey = try self.generateRegistrationData()

            let op = Register(challenge: challenge,
                                       vendorId: vendorId,
                                       registrationId: registrationId,
                                       publicKey: publicKey,
                                       identityProvider: self.identityProvider,
                                       logger: self.logger)
            op.completionBlock = {
                if let error = op.error {
                    completion(.failure(error))
                } else {
                    guard let uid = op.uid else {
                        return completion(.failure(SudoUserClientError.fatalError(description: "uid not found.")))
                    }

                    do {
                        try self.setUserName(name: uid)
                    } catch let error {
                        return completion(.failure(SudoUserClientError.fatalError(description: "Failed to set user name: \(error)")))
                    }

                    self.logger.info("Registration completed successfully..")

                    completion(.success(uid))
                }
            }

            self.registerOperationQueue.addOperation(op)
        }
    }

    public func registerWithDeviceCheck(token: Data,
                                        buildType: String,
                                        vendorId: UUID?,
                                        registrationId: String?,
                                        completion: @escaping (Swift.Result<String, Error>) -> Void) throws {
        self.logger.info("Performing registration.")

        try self.queue.sync {
            guard !isRegistered() else {
                throw SudoUserClientError.alreadyRegistered
            }

            guard self.registerOperationQueue.operationCount == 0 else {
                throw SudoUserClientError.registerOperationAlreadyInProgress
            }

            // Clear out any partial registration data.
            try self.reset()

            // Generate the shared encryption key.
            try self.generateSymmetricKey()

            let publicKey = try self.generateRegistrationData()

            let challenge = RegistrationChallenge()
            challenge.type = .deviceCheck
            challenge.answer = token.base64EncodedString()
            challenge.buildType = buildType

            let op = Register(challenge: challenge,
                                       vendorId: vendorId,
                                       registrationId: registrationId,
                                       publicKey: publicKey,
                                       identityProvider: self.identityProvider,
                                       logger: self.logger)
            op.completionBlock = {
                if let error = op.error {
                    completion(.failure(error))
                } else {
                    guard let uid = op.uid else {
                        return completion(.failure(SudoUserClientError.fatalError(description: "uid not found.")))
                    }

                    do {
                        try self.setUserName(name: uid)
                    } catch let error {
                        return completion(.failure(SudoUserClientError.fatalError(description: "Failed to set user name: \(error)")))
                    }

                    self.logger.info("Registration completed successfully..")

                    completion(.success(uid))
                }
            }

            self.registerOperationQueue.addOperation(op)
        }
    }

    public func registerWithAuthenticationProvider(authenticationProvider: AuthenticationProvider,
                                                   registrationId: String?,
                                                   completion: @escaping (Swift.Result<String, Error>) -> Void) throws {
        self.logger.info("Performing registration with external authentication provider.")

        try self.queue.sync {
            guard !isRegistered() else {
                throw SudoUserClientError.alreadyRegistered
            }

            guard self.registerOperationQueue.operationCount == 0 else {
                throw SudoUserClientError.registerOperationAlreadyInProgress
            }

            // Clear out any partial registration data.
            try self.reset()

            // Generate the shared encryption key.
            try self.generateSymmetricKey()

            var publicKey: PublicKey?
            if authenticationProvider is TESTAuthenticationProvider {
                publicKey = try self.generateRegistrationData()
            }

            let op = RegisterWithAuthenticationProvider(authenticationProvider: authenticationProvider,
                                                                 registrationId: registrationId,
                                                                 publicKey: publicKey,
                                                                 identityProvider: self.identityProvider,
                                                                 logger: self.logger)
            op.completionBlock = {
                if let error = op.error {
                    completion(.failure(error))
                } else {
                    guard let uid = op.uid else {
                        return completion(.failure(SudoUserClientError.fatalError(description: "uid not found.")))
                    }

                    do {
                        try self.generateSymmetricKey()
                        try self.setUserName(name: uid)
                    } catch let error {
                        return completion(.failure(SudoUserClientError.fatalError(description: "Failed to set user name: \(error)")))
                    }

                    completion(.success(uid))
                }
            }

            self.registerOperationQueue.addOperation(op)
        }
    }

    public func deregister(completion: @escaping (Swift.Result<String, Error>) -> Void) throws {
        self.logger.info("Performing deregistration.")

        guard let uid = try self.getUserName() else {
            throw SudoUserClientError.notRegistered
        }

        guard let apiClient = self.apiClient else {
            throw SudoUserClientError.invalidConfig
        }

        apiClient.perform(mutation: DeregisterMutation(), queue: self.queue, resultHandler: { (result, error) in
            if let error = error as? AWSAppSyncClientError {
                completion(.failure(GraphQLClientError.graphQLError(cause: [error])))
            } else {
                if let errors = result?.errors {
                    completion(.failure(GraphQLClientError.graphQLError(cause: errors)))
                } else {
                    self.logger.info("User deregistered successfully..")

                    do {
                        try self.reset()
                        completion(.success(uid))
                    } catch let error {
                        completion(.failure(error))
                    }
                }
            }
        })
    }

    public func signInWithKey(completion: @escaping (Swift.Result<AuthenticationTokens, Error>) -> Void) throws {
        self.logger.info("Performing sign in with private key.")

        try self.queue.sync {
            guard self.signInOperationQueue.operationCount == 0 else {
                throw SudoUserClientError.signInOperationAlreadyInProgress
            }

            guard let apiClient = self.apiClient else {
                throw SudoUserClientError.invalidConfig
            }

            // Retrieve the stored user name and private key ID from the keychain.
            guard let uid = try self.getUserName(),
                let data = try self.keyManager.getPassword(Constants.KeyName.userKeyId),
                let keyId = String(data: data, encoding: .utf8) else {
                    throw SudoUserClientError.notRegistered
            }

            self.signInStatusObservers.values.forEach { (observer) in
                observer.signInStatusChanged(status: .signingIn)
            }

            let parameters: [String: Any] = [CognitoUserPoolIdentityProvider.AuthenticationParameter.keyId: keyId,
                                             CognitoUserPoolIdentityProvider.AuthenticationParameter.tokenLifetime: self.tokenLifetime]

            let op = SignIn(identityProvider: self.identityProvider, sudoUserClient: self, uid: uid, parameters: parameters)
            op.completionBlock = {
                if let error = op.error {
                    self.signInStatusObservers.values.forEach { (observer) in
                        observer.signInStatusChanged(status: .notSignedIn(cause: error))
                    }

                    completion(.failure(error))
                } else {
                    if let tokens = op.tokens {
                        self.credentialsProvider.clearCredentials()
                        do {
                            try self.storeRefreshTokenLifetime(refreshTokenLifetime: self.refreshTokenLifetime)
                            try self.registerFederatedIdAndRefreshTokens(apiClient: apiClient, sudoUserClient: self, tokens: tokens, completion: completion)
                        } catch {
                            self.signInStatusObservers.values.forEach { (observer) in
                                observer.signInStatusChanged(status: .notSignedIn(cause: error))
                            }

                            completion(.failure(error))
                        }
                    } else {
                        let error = SudoUserClientError.fatalError(description: "SignIn operation completed successfully but tokens were missing.")

                        self.signInStatusObservers.values.forEach { (observer) in
                            observer.signInStatusChanged(status: .notSignedIn(cause: error))
                        }

                        completion(.failure(error))
                    }
                }
            }
            self.signInOperationQueue.addOperation(op)
        }
    }

    public func signInWithAuthenticationProvider(authenticationProvider: AuthenticationProvider, completion: @escaping (Swift.Result<AuthenticationTokens, Error>) -> Void) throws {
        self.logger.info("Performing sign in with authentication provider.")

        try self.queue.sync {
            guard self.signInOperationQueue.operationCount == 0 else {
                throw SudoUserClientError.signInOperationAlreadyInProgress
            }

            guard let apiClient = self.apiClient else {
                throw SudoUserClientError.invalidConfig
            }

            self.signInStatusObservers.values.forEach { (observer) in
                observer.signInStatusChanged(status: .signingIn)
            }

            authenticationProvider.getAuthenticationInfo { (result) in
                switch result {
                case .success(let authenticationInfo):
                    let uid = authenticationInfo.getUsername()
                    let parameters: [String: Any] = [
                        CognitoUserPoolIdentityProvider.AuthenticationParameter.challengeType: "FSSO",
                        CognitoUserPoolIdentityProvider.AuthenticationParameter.answer: authenticationInfo.toString()
                    ]

                    let op = SignIn(identityProvider: self.identityProvider, sudoUserClient: self, uid: uid, parameters: parameters)
                    op.completionBlock = {
                        if let error = op.error {
                            self.signInStatusObservers.values.forEach { (observer) in
                                observer.signInStatusChanged(status: .notSignedIn(cause: error))
                            }

                            completion(.failure(error))
                        } else {
                            if let tokens = op.tokens {
                                self.credentialsProvider.clearCredentials()
                                do {
                                    try self.storeRefreshTokenLifetime(refreshTokenLifetime: self.refreshTokenLifetime)
                                    try self.registerFederatedIdAndRefreshTokens(apiClient: apiClient, sudoUserClient: self, tokens: tokens, completion: completion)
                                } catch {
                                    self.signInStatusObservers.values.forEach { (observer) in
                                        observer.signInStatusChanged(status: .notSignedIn(cause: error))
                                    }

                                    completion(.failure(error))
                                }
                            } else {
                                let error = SudoUserClientError.fatalError(description: "SignIn operation completed successfully but tokens were missing.")

                                self.signInStatusObservers.values.forEach { (observer) in
                                    observer.signInStatusChanged(status: .notSignedIn(cause: error))
                                }

                                completion(.failure(error))
                            }
                        }
                    }
                    self.signInOperationQueue.addOperation(op)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    public func presentFederatedSignInUI(presentationAnchor: ASPresentationAnchor,
                                         completion: @escaping(Swift.Result<AuthenticationTokens, Error>) -> Void) throws {
        guard let authUI = self.authUI,
            let apiClient = self.apiClient else {
            throw SudoUserClientError.invalidConfig
        }

        try authUI.presentFederatedSignInUI(presentationAnchor: presentationAnchor) { (result) in
            do {
                switch result {
                case let .success(tokens):
                    self.logger.info("Sign in completed successfully.")

                    try self.setUserName(name: tokens.username)
                    try self.storeRefreshTokenLifetime(refreshTokenLifetime: self.refreshTokenLifetime)
                    try self.storeTokens(tokens: tokens)

                    // Generate the symmetric key if one does not exist already.
                    do {
                        _ = try self.getSymmetricKeyId()
                    } catch {
                        try self.generateSymmetricKey()
                    }

                    self.credentialsProvider.clearCredentials()
                    try self.registerFederatedIdAndRefreshTokens(apiClient: apiClient, sudoUserClient: self, tokens: tokens, completion: completion)
                case let .failure(cause):
                    completion(.failure(cause))
                }
            } catch let error {
                completion(.failure(error))
            }
        }
    }

    public func presentFederatedSignOutUI(presentationAnchor: ASPresentationAnchor,
                                          completion: @escaping(Swift.Result<Void, Error>) -> Void) throws {
        guard let authUI = self.authUI else {
            throw SudoUserClientError.invalidConfig
        }

        try authUI.presentFederatedSignOutUI(presentationAnchor: presentationAnchor, completion: completion)
    }

    public func processFederatedSignInTokens(url: URL) throws -> Bool {
        guard let authUI = self.authUI else {
            throw SudoUserClientError.invalidConfig
        }

        return authUI.processFederatedSignInTokens(url: url)
    }

    public func refreshTokens(refreshToken: String, completion: @escaping (Swift.Result<AuthenticationTokens, Error>) -> Void) throws {
        self.logger.info("Refreshing authentication tokens.")

        try self.queue.sync {
            guard self.signInOperationQueue.operationCount == 0 else {
                throw SudoUserClientError.refreshTokensOperationAlreadyInProgress
            }

            self.signInStatusObservers.values.forEach { (observer) in
                observer.signInStatusChanged(status: .signingIn)
            }

            let op = RefreshTokens(identityProvider: self.identityProvider, sudoUserClient: self, refreshToken: refreshToken)
            op.completionBlock = {
                if let error = op.error {
                    self.signInStatusObservers.values.forEach { (observer) in
                        observer.signInStatusChanged(status: .notSignedIn(cause: error))
                    }

                    completion(.failure(error))
                } else {
                    if let tokens = op.tokens {
                        self.credentialsProvider.clearCredentials()

                        self.signInStatusObservers.values.forEach { (observer) in
                            observer.signInStatusChanged(status: .signedIn)
                        }

                        completion(.success(tokens))
                    } else {
                        let error = SudoUserClientError.fatalError(description: "RefreshTokens operation completed successfully but tokens were missing.")

                        self.signInStatusObservers.values.forEach { (observer) in
                            observer.signInStatusChanged(status: .notSignedIn(cause: error))
                        }

                        completion(.failure(error))
                    }
                }
            }
            self.signInOperationQueue.addOperation(op)
        }
    }

    public func getUserName() throws -> String? {
        guard let data = try self.keyManager.getPassword(Constants.KeyName.userId),
            let username = String(data: data, encoding: .utf8) else {
            return nil
        }

        return username
    }

    public func getSubject() throws -> String? {
        guard let idToken = try self.getIdToken() else {
            return nil
        }

        let jwt = try JWT(string: idToken, keyManager: nil)
        return jwt.subject
    }

    public func getIdToken() throws -> String? {
        guard let data = try self.keyManager.getPassword(Constants.KeyName.idToken),
            let idToken = String(data: data, encoding: .utf8) else {
                return nil
        }

        return idToken
    }

    public func getAccessToken() throws -> String? {
        guard let data = try self.keyManager.getPassword(Constants.KeyName.accessToken),
            let accessToken = String(data: data, encoding: .utf8) else {
                return nil
        }

        return accessToken
    }

    public func getTokenExpiry() throws -> Date? {
        guard let data = try self.keyManager.getPassword(Constants.KeyName.tokenExpiry),
            let string = String(data: data, encoding: .utf8),
            let tokenExpiry = Double(string) else {
                return nil
        }

        return Date(timeIntervalSince1970: tokenExpiry)
    }

    public func getRefreshTokenExpiry() throws -> Date? {
        guard let data = try self.keyManager.getPassword(Constants.KeyName.refreshTokenExpiry),
            let string = String(data: data, encoding: .utf8),
            let refreshTokenExpiry = Double(string) else {
                return nil
        }

        return Date(timeIntervalSince1970: refreshTokenExpiry)
    }

    public func getRefreshToken() throws -> String? {
        guard let data = try self.keyManager.getPassword(Constants.KeyName.refreshToken),
            let refreshToken = String(data: data, encoding: .utf8) else {
                return nil
        }

        return refreshToken
    }

    public func encrypt(keyId: String, algorithm: SymmetricKeyEncryptionAlgorithm, data: Data) throws -> Data {
        let iv = try self.keyManager.createIV()
        let encryptedData = try self.keyManager.encryptWithSymmetricKey(keyId, data: data, iv: iv)
        return encryptedData + iv
    }

    public func decrypt(keyId: String, algorithm: SymmetricKeyEncryptionAlgorithm, data: Data) throws -> Data {
        guard data.count > SudoKeyManagerImpl.Constants.defaultBlockSizeAES else {
            throw SudoUserClientError.invalidInput
        }

        let encryptedData = data[0..<data.count - 16]
        let iv = data[data.count - 16..<data.count]
        return try self.keyManager.decryptWithSymmetricKey(keyId, data: encryptedData, iv: iv)
    }

    public func clearAuthTokens() throws {
        try self.keyManager.deletePassword(Constants.KeyName.idToken)
        try self.keyManager.deletePassword(Constants.KeyName.accessToken)
        try self.keyManager.deletePassword(Constants.KeyName.refreshToken)
        try self.keyManager.deletePassword(Constants.KeyName.tokenExpiry)

        if let authUI = self.authUI {
            authUI.reset()
        }
    }

    public func globalSignOut(completion: @escaping(Swift.Result<Void, Error>) -> Void) throws {
        self.logger.info("Performing global sign out.")

        guard let apiClient = self.apiClient else {
            throw SudoUserClientError.invalidConfig
        }

        apiClient.perform(mutation: GlobalSignOutMutation(), queue: self.queue, resultHandler: { (result, error) in
            if let error = error as? AWSAppSyncClientError {
                completion(.failure(GraphQLClientError.graphQLError(cause: [error])))
            } else {
                if let errors = result?.errors {
                    completion(.failure(GraphQLClientError.graphQLError(cause: errors)))
                } else {
                    self.logger.info("User globally signed out successfully.")

                    do {
                        try self.clearAuthTokens()
                        completion(.success(()))
                    } catch let error {
                        completion(.failure(error))
                    }
                }
            }
        })
    }

    public func getIdentityId() -> String? {
        return try? self.getUserClaim(name: "custom:identityId") as? String
    }

    public func getUserClaim(name: String) throws -> Any? {
        guard let idToken = try self.getIdToken() else {
            return nil
        }

        let jwt = try JWT(string: idToken, keyManager: nil)
        return jwt.payload[name]
    }

    public func isSignedIn() throws -> Bool {
        guard try self.getIdToken() != nil,
            try self.getAccessToken() != nil,
            let expiry = try self.getRefreshTokenExpiry() else {
                return false
        }

        // Considered signed in up to 1 hour before the expiry of refresh token.
        return expiry > Date(timeIntervalSinceNow: 60 * 60)
    }

    public func registerSignInStatusObserver(id: String, observer: SignInStatusObserver) {
        self.signInStatusObservers[id] = observer
    }

    public func deregisterSignInStatusObserver(id: String) {
        self.signInStatusObservers.removeValue(forKey: id)
    }

    public func storeTokens(tokens: AuthenticationTokens) throws {
        guard let idTokenData = tokens.idToken.data(using: .utf8),
            let accessTokenData = tokens.accessToken.data(using: .utf8),
            let refreshTokenData = tokens.refreshToken.data(using: .utf8),
            let tokenExpiryData = "\(Date().timeIntervalSince1970 + Double(tokens.lifetime))".data(using: .utf8) else {
                throw SudoUserClientError.fatalError(description: "Tokens cannot be serialized.")
        }

        // Cache the tokens and token lifetime in the keychain.
        try self.keyManager.deletePassword(Constants.KeyName.idToken)
        try self.keyManager.addPassword(idTokenData, name: Constants.KeyName.idToken)

        try self.keyManager.deletePassword(Constants.KeyName.accessToken)
        try self.keyManager.addPassword(accessTokenData, name: Constants.KeyName.accessToken)

        try self.keyManager.deletePassword(Constants.KeyName.refreshToken)
        try self.keyManager.addPassword(refreshTokenData, name: Constants.KeyName.refreshToken)

        try self.keyManager.deletePassword(Constants.KeyName.tokenExpiry)
        try self.keyManager.addPassword(tokenExpiryData, name: Constants.KeyName.tokenExpiry)
    }

    private func storeRefreshTokenLifetime(refreshTokenLifetime: Int) throws {
        // If a new refresh token lifetime is specified then stored that in the keychain as well.
        if let refreshTokenExpiryData = "\(Date().timeIntervalSince1970 + Double(refreshTokenLifetime * 24 * 60 * 60))".data(using: .utf8) {
            try self.keyManager.deletePassword(Constants.KeyName.refreshTokenExpiry)
            try self.keyManager.addPassword(refreshTokenExpiryData, name: Constants.KeyName.refreshTokenExpiry)
        }
    }

    private func getPrivateKeyId() throws -> String? {
        do {
            guard let data = try self.keyManager.getPassword(Constants.KeyName.userKeyId),
                let keyId = String(data: data, encoding: .utf8) else {
                    return nil
            }

            return keyId
        } catch {
            throw SudoUserClientError.fatalError(description: "Unexpected error occurred while retrieving private key ID.")
        }
    }

    public func setUserName(name: String) throws {
        guard let data = name.data(using: .utf8) else {
            throw SudoUserClientError.fatalError(description: "Cannot serialize user name.")
        }

        // Delete the user name first so there won't be a conflict when adding the new one.
        try self.keyManager.deletePassword(Constants.KeyName.userId)

        try self.keyManager.addPassword(data, name: Constants.KeyName.userId)
    }

    private func generateRegistrationData() throws -> PublicKey {
        // Generate a public/private key pair for this identity.
        let keyId = try self.keyManager.generateKeyId()
        try self.keyManager.deleteKeyPair(keyId)
        try self.keyManager.generateKeyPair(keyId)

        guard let publicKeyData = try self.keyManager.getPublicKey(keyId) else {
            throw SudoUserClientError.fatalError(description: "Public key not found.")
        }

        // Make sure the key ID that we are trying to add don't exist.
        try self.keyManager.deletePassword(Constants.KeyName.userKeyId)

        // Store the key ID for user key in the keychain.
        guard let keyIdData = keyId.data(using: .utf8) else {
            throw SudoUserClientError.fatalError(description: "Cannot convert key ID to data.")
        }

        try self.keyManager.addPassword(keyIdData, name: Constants.KeyName.userKeyId)

        let publicKey = PublicKey(publicKey: publicKeyData, keyId: keyId)

        return publicKey
    }

    private func generateSymmetricKey() throws {
        // Generate symmetric key and store it under a unique key ID.
        let symmetricKeyId = try self.keyManager.generateKeyId()

        // Make sure symmetric key does not exists.
        try self.keyManager.deletePassword(Constants.KeyName.symmetricKeyId)
        try self.keyManager.deletePassword(symmetricKeyId)

        try self.keyManager.generateSymmetricKey(symmetricKeyId)

        guard let symmetricKeyIdData = symmetricKeyId.data(using: .utf8) else {
            throw SudoUserClientError.fatalError(description: "Cannot convert key ID to data.")
        }

        try self.keyManager.addPassword(symmetricKeyIdData, name: Constants.KeyName.symmetricKeyId)
    }

    /// Performs federated sign in and binds the resulting identity ID to the user. It also refreshes the authentication tokens so that
    ///  the ID token contains the identity ID as a claim.
    ///
    /// - Parameters:
    ///   - apiClient: GraphQL client used calling Identity Service API.
    ///   - sudoUserClient: `SudoUserClient` to store the authentication tokens.
    ///   - idToken: ID token to use for federated sign in.
    ///   - refreshToken: Refresh token to use for refreshing authentication tokens.
    ///   - completion: completion handler to pass the resulting tokens or error.
    private func registerFederatedIdAndRefreshTokens(apiClient: AWSAppSyncClient,
                                                     sudoUserClient: SudoUserClient,
                                                     tokens: AuthenticationTokens,
                                                     completion: @escaping (Swift.Result<AuthenticationTokens, Error>) -> Void) throws {
        guard try self.getUserClaim(name: "custom:identityId") == nil else {
            self.signInStatusObservers.values.forEach { (observer) in
                observer.signInStatusChanged(status: .signedIn)
            }

            return completion(.success(tokens))
        }

        self.logger.info("Registering federated identity.")

        let registerFederatedIdOp = RegisterFederatedId(apiClient: apiClient, idToken: tokens.idToken)
        let getIdentityIdOp = GetIdentityId(credentialsProvider: self.credentialsProvider)
        let refreshTokensOp = RefreshTokens(identityProvider: self.identityProvider, sudoUserClient: self, refreshToken: tokens.refreshToken)
        let operations: [UserOperation] = [registerFederatedIdOp, getIdentityIdOp, refreshTokensOp]

        getIdentityIdOp.addDependency(registerFederatedIdOp)
        refreshTokensOp.addDependency(getIdentityIdOp)

        refreshTokensOp.completionBlock = {
            let errors = operations.compactMap { $0.error }
            if let error = errors.first {
                self.signInStatusObservers.values.forEach { (observer) in
                    observer.signInStatusChanged(status: .notSignedIn(cause: error))
                }

                completion(.failure(error))
            } else {
                if let tokens = refreshTokensOp.tokens {
                    self.signInStatusObservers.values.forEach { (observer) in
                        observer.signInStatusChanged(status: .signedIn)
                    }

                    completion(.success(tokens))
                } else {
                    let error = SudoUserClientError.fatalError(description: "RefreshTokens operation completed successfully but tokens were missing.")

                    self.signInStatusObservers.values.forEach { (observer) in
                        observer.signInStatusChanged(status: .notSignedIn(cause: error))
                    }

                    completion(.failure(error))
                }
            }
        }

        self.signInOperationQueue.addOperations(operations, waitUntilFinished: false)
    }

    public func getSupportedRegistrationChallengeType() -> [ChallengeType] {
        return self.challengeTypes
    }

}
