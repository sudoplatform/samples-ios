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

    /// Identity provider to use for registration and authentication.
    private var identityProvider: IdentityProvider

    /// Actor for synchronizing access to client state information.
    private lazy var clientStateActor: ClientStateActor = {
        return ClientStateActor(
            keyManager: self.keyManager,
            credentialsProvider: self.credentialsProvider,
            authUI: self.authUI
        )
    }()

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

    private let signInObserversActor: SignInObserversActor

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
    ///         Mainly used for unit testing.
    ///   - apiClient: GrpahQL client to use for Identity Service API. Mainly used for unit testing.
    ///   - authUI: AuthUI used for presenting federated sign in UI. Mainly used for unit testing.
    ///   - logger: A logger to use for logging messages. If none provided then a default
    ///         internal logger will be used.
    public init(config: [String: Any],
                keyNamespace: String,
                credentialsProvider: CredentialsProvider? = nil,
                identityProvider: IdentityProvider? = nil,
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

        self.signInObserversActor = SignInObserversActor()

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

        self.clientStateActor = ClientStateActor(keyManager: keyManager, credentialsProvider: self.credentialsProvider, authUI: self.authUI)
    }

    public func isRegistered() async throws -> Bool {
        return try await self.clientStateActor.isRegistered()
    }

    public func reset() async throws {
        self.logger.info("Resetting client.")
        try await self.clientStateActor.reset()
    }

    public func registerWithDeviceCheck(
        token: Data,
        buildType: String,
        vendorId: UUID,
        registrationId: String?
    ) async throws -> String {
        let registrationId = registrationId ?? UUID().uuidString
        self.logger.info("Performing registration with DeviceCheck token: registrationId=\(registrationId)")

        guard !(try await self.clientStateActor.isRegistered()) else {
            throw SudoUserClientError.alreadyRegistered
        }

        // Clear out any partial registration data.
        try await self.reset()

        let publicKey = try await self.clientStateActor.generateRegistrationData()

        let challenge = RegistrationChallenge()
        challenge.type = .deviceCheck
        let answer = token.base64EncodedString()
        let buildType = buildType

        let uuid = UUID().uuidString
        var registrationParameters: [String: String] = [:]
        registrationParameters[CognitoUserPoolIdentityProvider.RegistrationParameter.challengeType] = challenge.type.rawValue
        if answer.count > Constants.Limit.maxValidationDataSize {
            // If the answer exceeds the validation data size limit then divide up the answer to parts.
            let parts = answer.chunks(size: Constants.Limit.maxValidationDataSize)
            var parameters: [(String, String)] = []
            for (index, part) in parts.enumerated() {
                parameters.append(("\(CognitoUserPoolIdentityProvider.RegistrationParameter.answer).\(index)", part))
            }

            registrationParameters.merge(parameters) {(_, new) in new}
            let answerMetadata: [String: Any] = ["parts": parameters.map { $0.0 }]
            guard let jsonData = answerMetadata.toJSONData() else {
                throw SudoUserClientError.fatalError(description: "Cannot serialize the answer metadata.")
            }
            registrationParameters[CognitoUserPoolIdentityProvider.RegistrationParameter.answerMetadata] = String(data: jsonData, encoding: .utf8)
        } else {
            registrationParameters[CognitoUserPoolIdentityProvider.RegistrationParameter.answer] = answer
        }
        registrationParameters[CognitoUserPoolIdentityProvider.RegistrationParameter.registrationId] = registrationId

        let data = withUnsafePointer(to: vendorId.uuid) {
            Data(bytes: $0, count: MemoryLayout.size(ofValue: vendorId.uuid))
        }
        registrationParameters[CognitoUserPoolIdentityProvider.RegistrationParameter.deviceId] = data.base64EncodedString()
        registrationParameters[CognitoUserPoolIdentityProvider.RegistrationParameter.buildType] = buildType

        guard let encodedKey = try String(data: publicKey.toData(), encoding: .utf8) else {
            throw SudoUserClientError.fatalError(description: "Cannot serialize the public key.")
        }

        registrationParameters[CognitoUserPoolIdentityProvider.RegistrationParameter.publicKey] = encodedKey

        let uid = try await self.identityProvider.register(uid: uuid, parameters: registrationParameters)
        try await self.setUserName(name: uid)

        self.logger.info("Registration with DeviceCheck token completed successfully.")

        return uid
    }

    public func registerWithAuthenticationProvider(
        authenticationProvider: AuthenticationProvider,
        registrationId: String?
    ) async throws -> String {
        let registrationId = registrationId ?? UUID().uuidString
        self.logger.info("Performing registration with authentication provider: registrationId=\(registrationId)")

        guard !(try await self.clientStateActor.isRegistered()) else {
            throw SudoUserClientError.alreadyRegistered
        }

        // Clear out any partial registration data.
        try await self.reset()

        var publicKey: PublicKey?
        if authenticationProvider is TESTAuthenticationProvider {
            publicKey = try await self.clientStateActor.generateRegistrationData()
        }

        var registrationParameters: [String: String] = [:]

        let authInfo = try await authenticationProvider.getAuthenticationInfo()
        let token = authInfo.toString()

        let jwt: JWT
        jwt = try JWT(string: token)

        let uuid = (jwt.payload["sub"] as? String) ?? UUID().uuidString

        registrationParameters[CognitoUserPoolIdentityProvider.RegistrationParameter.challengeType] = authInfo.type
        registrationParameters[CognitoUserPoolIdentityProvider.RegistrationParameter.answer] = authInfo.toString()
        registrationParameters[CognitoUserPoolIdentityProvider.RegistrationParameter.registrationId] = UUID().uuidString

        if let publicKey = publicKey {
            guard let encodedKey = try String(data: publicKey.toData(), encoding: .utf8) else {
                throw SudoUserClientError.fatalError(description: "Cannot serialize the public key.")
            }

            registrationParameters[CognitoUserPoolIdentityProvider.RegistrationParameter.publicKey] = encodedKey
        }

        let uid = try await self.identityProvider.register(uid: uuid, parameters: registrationParameters)
        try await self.setUserName(name: uid)

        self.logger.info("Registration with authentication provider completed successfully.")

        return uid
    }

    public func deregister() async throws -> String {
        self.logger.info("Performing deregistration.")

        guard let uid = try self.getUserName() else {
            throw SudoUserClientError.notRegistered
        }

        guard let apiClient = self.apiClient else {
            throw SudoUserClientError.invalidConfig
        }

        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<String, Error>) in
            apiClient.perform(mutation: DeregisterMutation(), queue: self.queue, resultHandler: { (result, error) in
                if let error = error as? AWSAppSyncClientError {
                    continuation.resume(throwing: SudoUserClientError.graphQLError(cause: [error]))
                } else {
                    if let errors = result?.errors {
                        continuation.resume(throwing: SudoUserClientError.graphQLError(cause: errors))
                    } else {
                        self.logger.info("User deregistered successfully..")

                        Task(priority: .medium) {
                            do {
                                try await self.reset()
                                continuation.resume(returning: uid)
                            } catch let error {
                                continuation.resume(throwing: error)
                            }
                        }
                    }
                }
            })
        })
    }

    public func signInWithKey() async throws -> AuthenticationTokens {
        self.logger.info("Performing sign in with private key.")

        guard let apiClient = self.apiClient else {
            throw SudoUserClientError.invalidConfig
        }

        // Retrieve the stored user name and private key ID from the keychain.
        guard let uid = try self.getUserName(),
              let data = try self.keyManager.getPassword(Constants.KeyName.userKeyId),
              let keyId = String(data: data, encoding: .utf8) else {
                  throw SudoUserClientError.notRegistered
              }

        await self.signInObserversActor.notifyObservers(status: .signingIn)

        let parameters: [String: Any] = [CognitoUserPoolIdentityProvider.AuthenticationParameter.keyId: keyId,
                                         CognitoUserPoolIdentityProvider.AuthenticationParameter.tokenLifetime: self.tokenLifetime]

        do {
            var tokens = try await self.identityProvider.signIn(uid: uid, parameters: parameters)
            try await self.clientStateActor.storeTokens(tokens: tokens)
            self.credentialsProvider.clearCredentials()
            try await self.clientStateActor.storeRefreshTokenLifetime(refreshTokenLifetime: self.refreshTokenLifetime)
            tokens = try await self.registerFederatedIdAndRefreshTokens(apiClient: apiClient, sudoUserClient: self, tokens: tokens)

            await self.signInObserversActor.notifyObservers(status: .signedIn)

            self.logger.info("Sign in with private key completed successfully.")

            return tokens
        } catch {
            await self.signInObserversActor.notifyObservers(status: .notSignedIn(cause: error))
            throw error
        }
    }

    public func signInWithAuthenticationProvider(authenticationProvider: AuthenticationProvider) async throws -> AuthenticationTokens {
        self.logger.info("Performing sign in with authentication provider.")

        guard let apiClient = self.apiClient else {
            throw SudoUserClientError.invalidConfig
        }

        await self.signInObserversActor.notifyObservers(status: .signingIn)

        let authInfo = try await authenticationProvider.getAuthenticationInfo()
        let uid = authInfo.getUsername()
        let parameters: [String: Any] = [
            CognitoUserPoolIdentityProvider.AuthenticationParameter.challengeType: "FSSO",
            CognitoUserPoolIdentityProvider.AuthenticationParameter.answer: authInfo.toString()
        ]

        do {
            var tokens = try await self.identityProvider.signIn(uid: uid, parameters: parameters)
            try await self.clientStateActor.storeTokens(tokens: tokens)
            self.credentialsProvider.clearCredentials()
            try await self.clientStateActor.storeRefreshTokenLifetime(refreshTokenLifetime: self.refreshTokenLifetime)
            tokens = try await self.registerFederatedIdAndRefreshTokens(apiClient: apiClient, sudoUserClient: self, tokens: tokens)

            await self.signInObserversActor.notifyObservers(status: .signedIn)

            self.logger.info("Sign in with authentication provider completed successfully.")

            return tokens
        } catch {
            await self.signInObserversActor.notifyObservers(status: .notSignedIn(cause: error))
            throw error
        }
    }

    public func presentFederatedSignInUI(presentationAnchor: ASPresentationAnchor) async throws -> AuthenticationTokens {
        guard let authUI = self.authUI,
            let apiClient = self.apiClient else {
            throw SudoUserClientError.invalidConfig
        }

        let tokens = try await authUI.presentFederatedSignInUI(presentationAnchor: presentationAnchor)
        try await self.setUserName(name: tokens.username)
        try await self.clientStateActor.storeRefreshTokenLifetime(refreshTokenLifetime: self.refreshTokenLifetime)
        try await self.clientStateActor.storeTokens(tokens: tokens)

        self.credentialsProvider.clearCredentials()

        return try await self.registerFederatedIdAndRefreshTokens(apiClient: apiClient, sudoUserClient: self, tokens: tokens)
    }

    public func presentFederatedSignOutUI(presentationAnchor: ASPresentationAnchor) async throws {
        guard let authUI = self.authUI else {
            throw SudoUserClientError.invalidConfig
        }

        try await authUI.presentFederatedSignOutUI(presentationAnchor: presentationAnchor)
    }

    public func processFederatedSignInTokens(url: URL) async throws -> Bool {
        guard let authUI = self.authUI else {
            throw SudoUserClientError.invalidConfig
        }

        return authUI.processFederatedSignInTokens(url: url)
    }

    public func refreshTokens(refreshToken: String) async throws -> AuthenticationTokens {
        self.logger.info("Refreshing authentication tokens.")

        await self.signInObserversActor.notifyObservers(status: .signingIn)

        do {
            let tokens = try await self.identityProvider.refreshTokens(refreshToken: refreshToken)
            try await self.clientStateActor.storeTokens(tokens: tokens)
            self.credentialsProvider.clearCredentials()

            await self.signInObserversActor.notifyObservers(status: .signedIn)

            self.logger.info("Authentication tokens refreshed successfully.")

            return tokens
        } catch {
            await self.signInObserversActor.notifyObservers(status: .notSignedIn(cause: error))
            throw error
        }
    }

    public func refreshTokens() async throws -> AuthenticationTokens {
        guard let refreshToken = try self.getRefreshToken() else {
            throw SudoUserClientError.notSignedIn
        }

        return try await self.refreshTokens(refreshToken: refreshToken)
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

    public func clearAuthTokens() async throws {
        try await self.clientStateActor.clearAuthTokens()
    }
    
    public func signOut() async throws {
        self.logger.info("Performing sign out.")
        
        guard let refreshToken = try self.getRefreshToken() else {
            throw SudoUserClientError.notSignedIn
        }

        try await self.identityProvider.signOut(refreshToken: refreshToken)
        try await self.clearAuthTokens()
    }

    public func globalSignOut() async throws {
        self.logger.info("Performing global sign out.")

        guard let apiClient = self.apiClient else {
            throw SudoUserClientError.invalidConfig
        }

        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Void, Error>) in
            apiClient.perform(mutation: GlobalSignOutMutation(), queue: self.queue, resultHandler: { (result, error) in
                if let error = error as? AWSAppSyncClientError {
                    continuation.resume(throwing: SudoUserClientError.graphQLError(cause: [error]))
                } else {
                    if let errors = result?.errors {
                        continuation.resume(throwing: SudoUserClientError.graphQLError(cause: errors))
                    } else {
                        self.logger.info("User globally signed out successfully.")
                        Task(priority: .medium) {
                            do {
                                try await self.clearAuthTokens()
                                continuation.resume()
                            } catch let error {
                                continuation.resume(throwing: error)
                            }
                        }
                    }
                }
            })
        })
    }

    public func getIdentityId() async -> String? {
        return try? self.getUserClaim(name: "custom:identityId") as? String
    }

    public func getUserClaim(name: String) throws -> Any? {
        guard let idToken = try self.getIdToken() else {
            return nil
        }

        let jwt = try JWT(string: idToken, keyManager: nil)
        return jwt.payload[name]
    }

    public func isSignedIn() async throws -> Bool {
        guard try self.getIdToken() != nil,
            try self.getAccessToken() != nil,
            let expiry = try self.getRefreshTokenExpiry() else {
                return false
        }

        // Considered signed in up to 1 hour before the expiry of refresh token.
        return expiry > Date(timeIntervalSinceNow: 60 * 60)
    }

    public func registerSignInStatusObserver(id: String, observer: SignInStatusObserver) async {
        await self.signInObserversActor.registerSignInStatusObserver(id: id, observer: observer)
    }

    public func deregisterSignInStatusObserver(id: String) async {
        await self.signInObserversActor.deregisterSignInStatusObserver(id: id)
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

    public func setUserName(name: String) async throws {
        try await self.clientStateActor.setUserName(name: name)
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
    private func registerFederatedIdAndRefreshTokens(
        apiClient: AWSAppSyncClient,
        sudoUserClient: SudoUserClient,
        tokens: AuthenticationTokens
    ) async throws -> AuthenticationTokens {
        guard try self.getUserClaim(name: "custom:identityId") == nil else {
            await self.signInObserversActor.notifyObservers(status: .signedIn)
            return tokens
        }

        self.logger.info("Registering federated identity.")

        try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Void, Error>) in
            let input = RegisterFederatedIdInput(idToken: tokens.idToken)
            apiClient.perform(mutation: RegisterFederatedIdMutation(input: input), queue: self.queue, resultHandler: { (result, error) in
                if let error = error as? AWSAppSyncClientError {
                    continuation.resume(throwing: SudoUserClientError.graphQLError(cause: [error]))
                } else {
                    if let errors = result?.errors {
                        continuation.resume(throwing: SudoUserClientError.graphQLError(cause: errors))
                    }

                    self.logger.info("Federated identity registered successfully.")

                    continuation.resume()
                }
            })
        })

        // Refresh the cached identity ID.
        _ = try await self.credentialsProvider.getIdentityId()

        // Refresh the ID token so it contains the registered identity ID as a claim.
        return try await self.refreshTokens(refreshToken: tokens.refreshToken)
    }

    public func getSupportedRegistrationChallengeType() -> [ChallengeType] {
        return self.challengeTypes
    }

}
