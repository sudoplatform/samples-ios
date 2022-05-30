//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoLogging
import SudoUser
import AWSAppSync
import AWSS3
import SudoConfigManager
import SudoApiClient

/// List of possible errors thrown by `SudoProfilesClient` implementation.
///
/// - sudoServiceConfigNotFound: Indicates the configuration related to Sudo Service is not found.
///     This may indicate that Sudo Service is not deployed into your runtime instance or the config
///     file that you are using is invalid..
/// - invalidInput: Indicates that the input to the API was invalid.
/// - notSignedIn: Indicates the API being called requires the client to sign in.
/// - badData: Indicates the bad data was found in cache or in backend response.
/// - graphQLError: Indicates that a GraphQL error was returned by the backend.
/// - fatalError: Indicates that a fatal error occurred. This could be due to coding error, out-of-memory
///     condition or other conditions that is beyond control of `SudoProfilesClient` implementation.
public enum SudoProfilesClientError: Error {

    /// Indicates that the configuration dictionary passed to initialize the client was not valid.
    case invalidConfig

    /// Indicates the configuration related to Sudo Service is not found. This may indicate that Sudo Service
    /// is not deployed into your runtime instance or the config file that you are using is invalid..
    case sudoServiceConfigNotFound

    /// Indicates that the input to the API was invalid.
    case invalidInput

    /// Indicates the requested operation failed because the user account is locked.
    case accountLocked

    /// Indicates the API being called requires the client to sign in.
    case notSignedIn

    /// Indicates that the request operation failed due to authorization error. This maybe due to the authentication
    /// token being invalid or other security controls that prevent the user from accessing the API.
    case notAuthorized

    /// Indicates that the user does not have sufficient entitlements to perform the requested operation.
    case insufficientEntitlements

    /// Indicates the version of the Sudo that is getting updated does not match the current version of the Sudo stored
    /// in the backend. The caller should retrieve the current version of the Sudo and reconcile the difference..
    case versionMismatch

    /// Indicates that an internal server error caused the operation to fail. The error is possibly transient and
    /// retrying at a later time may cause the operation to complete successfully
    case serviceError

    /// Indicates that the request failed due to connectivity, availability or access error.
    case requestFailed(response: HTTPURLResponse?, cause: Error?)

    /// Indicates that there were too many attempts at sending API requests within a short period of time.
    case rateLimitExceeded

    /// Indicates the bad data was found in cache or in backend response.
    case badData

    /// Indicates the specified Sudo was not found.
    case sudoNotFound

    /// Indicates that a GraphQL error was returned by the backend.
    case graphQLError(description: String)

    /// Indicates that a fatal error occurred. This could be due to coding error, out-of-memory condition or other
    /// conditions that is beyond control of `SudoProfilesClient` implementation.
    case fatalError(description: String)
}

extension SudoProfilesClientError {

    struct Constants {
        static let errorType = "errorType"
        static let sudoNotFoundError = "sudoplatform.sudo.SudoNotFound"
        static let invalidTokenError = "sudoplatform.InvalidTokenError"
        static let invalidUserTypeError = "sudoplatform.InvalidUserTypeError"
    }

    static func fromApiOperationError(error: Error) -> SudoProfilesClientError {
        switch error {
        case ApiOperationError.accountLocked:
            return .accountLocked
        case ApiOperationError.notSignedIn:
            return .notSignedIn
        case ApiOperationError.notAuthorized:
            return .notAuthorized
        case ApiOperationError.insufficientEntitlements:
            return .insufficientEntitlements
        case ApiOperationError.serviceError:
            return .serviceError
        case ApiOperationError.invalidRequest:
            return .invalidInput
        case ApiOperationError.rateLimitExceeded:
            return .rateLimitExceeded
        case ApiOperationError.versionMismatch:
            return .versionMismatch
        case ApiOperationError.graphQLError(let cause):
            guard let errorType = cause[Constants.errorType] as? String else {
              return .fatalError(description: "GraphQL operation failed but error type was not found in the response. \(error)")
            }

            switch errorType {
            case Constants.sudoNotFoundError:
                return .sudoNotFound
            case Constants.invalidTokenError, Constants.invalidUserTypeError:
                return .invalidInput
            default:
                return .graphQLError(description: "Unexpected GraphQL error: \(cause)")
            }
        case ApiOperationError.requestFailed(let response, let cause):
            return .requestFailed(response: response, cause: cause)
        default:
            return .fatalError(description: "Unexpected API operation error: \(error)")
        }
    }

}

/// Options for controlling the behaviour of `listSudos` API.
///
/// - cacheOnly: returns Sudos from the local cache only. The cache is only updated after listSudos is called with remoteOnly.
/// - remoteOnly: fetches Sudos from the backend, updates the local cache and returns the fetched Sudos.
/// - returnCachedElseFetch: returns Sudos from the local cache if cache is not empty otherwise fetch from the backend.
public enum ListOption {
    case cacheOnly
    case remoteOnly
    case returnCachedElseFetch
}

/// Protocol encapsulating a library functions for managing Sudos in the Sudo service.
public protocol SudoProfilesClient: AnyObject {

    /// Creates a new Sudo.
    ///
    /// - Parameter sudo: Sudo to create.
    /// - Returns: the created Sudo.
    /// - Throws: `SudoProfilesClientError`
    func createSudo(sudo: Sudo) async throws -> Sudo

    /// Update a Sudo.
    ///
    /// - Parameter sudo: Sudo to update.
    /// - Returns: the updated Sudo.
    /// - Throws: `SudoProfilesClientError`
    func updateSudo(sudo: Sudo) async throws -> Sudo

    /// Deletes a Sudo.
    ///
    /// - Parameters sudo: Sudo to delete.
    /// - Throws: `SudoProfilesClientError`
    func deleteSudo(sudo: Sudo) async throws

    /// Retrieves all Sudos owned by signed in user.
    ///
    /// - Parameter option: option for controlling the behaviour of this API. Refer to `ListOption` enum.
    /// - Returns: an array of all the Sudos owned by signed in user.
    /// - Throws: `SudoProfilesClientError`
    func listSudos(option: ListOption) async throws -> [Sudo]

    /// Returns the count of outstanding create or update requests.
    ///
    /// - Returns: Outstanding requests count.
    func getOutstandingRequestsCount() -> Int

    /// Resets any cached data.
    ///
    /// - Throws: `SudoProfilesClientError`
    func reset() throws

    /// Subscribes to be notified of new, updated or deleted Sudos. Blob data is not downloaded automatically
    /// so the caller is expected to use `listSudos` API if they need to access any associated blobs.
    ///
    /// - Parameter id: Unique ID to be associated with the subscriber.
    /// - Parameter changeType: Change type to subscribe to.
    /// - Parameter subscriber: Subscriber to notify.
    func subscribe(id: String, changeType: SudoChangeType, subscriber: SudoSubscriber) async throws

    /// Subscribes to be notified of new, updated and deleted Sudos. Blob data is not downloaded automatically
    /// so the caller is expected to use `listSudos` API if they need to access any associated blobs.
    ///
    /// - Parameter id: Unique ID to be associated with the subscriber.
    /// - Parameter subscriber: Subscriber to notify.
    func subscribe(id: String, subscriber: SudoSubscriber) async throws

    /// Unsubscribes the specified subscriber so that it no longer receives notifications about
    ///  new, updated or deleted Sudos.
    ///
    /// - Parameter id: Unique ID associated with the subscriber to unsubscribe.
    /// - Parameter changeType: Change type to unsubscribe from.
    func unsubscribe(id: String, changeType: SudoChangeType)

    /// Unsubscribes the specified subscriber so that it no longer receives change notifications.
    ///
    /// - Parameter id: Unique ID associated with the subscriber to unsubscribe.
    func unsubscribe(id: String)

    /// Unsubscribe all subscribers from receiving notifications about new, updated or deleted Sudos.
    func unsubscribeAll()

    /// Retrieves a signed owernship proof for the specified Sudo.
    ///
    /// - Parameters:
    ///   - sudo: Sudo to generate an ownership proof for.
    ///   - audience: Target audience for this proof.
    /// - Returns: JSON Web Token representing Sudo ownership proof.
    func getOwnershipProof(sudo: Sudo, audience: String) async throws -> String

    /// Generate an encryption key to use for encrypting Sudo claims. Any existing keys are not removed
    /// to be able to decrypt existing claims but new claims will be encrypted using the newly generated
    /// key.
    ///
    /// - Returns: Unique ID of the generated key.
    @discardableResult
    func generateEncryptionKey() throws -> String

    /// Get the current (most recently generated) symmetric key ID..
    ///
    /// - Returns: Symmetric Key ID.
    func getSymmetricKeyId() throws -> String?

    /// Import encyrption keys to use for encrypting and decrypting Sudo claims. All existing keys will be removed
    /// before the new keys are imported.
    ///
    /// - Parameters:
    ///     - keys: Keys to import.
    ///     - currentKeyId: ID of the key to use for encrypting new claims..
    func importEncryptionKeys(keys: [EncryptionKey], currentKeyId: String) throws

    /// Export encryption keys used for encrypting and decrypting Sudo claims.
    ///
    /// - Returns: Encryption keys.
    func exportEncryptionKeys() throws -> [EncryptionKey]

}

/// Default implementation of `SudoProfilesClient`.
public class DefaultSudoProfilesClient: SudoProfilesClient {

    public enum CacheType {
        case memory
        case disk
    }

    public struct Config {

        // Configuration namespace.
        struct Namespace {
            static let sudoService = "sudoService"
            static let apiService = "apiService"
            static let identityService = "identityService"
        }

        /// Configuration parameters.
        struct SudoService {
            static let region = "region"
            static let bucket = "bucket"
        }

    }

    private struct Constants {

        static let s3ClientKey = "com.sudoplatform.s3"
        static let defaultKeyNamespace = "ss"

    }

    private enum GetSudoResult {
        case success(sudo: Sudo?)
        case failure(cause: Error)
    }

    /// Default logger for the client.
    private let logger: Logger

    /// AWS region hosting directory service.
    private let region: String

    /// S3 bucket used by Sudo service for storing large objects.
    private let s3Bucket: String

    /// `SudoProfilesClient` instance required to issue authentication tokens and perform cryptographic operations.
    private let sudoUserClient: SudoUserClient

    /// `CryptoProvider` instance used for cryptographic operations.
    private var cryptoProvider: CryptoProvider

    /// GraphQL client for communicating with the Sudo  service.
    private let graphQLClient: SudoApiClient

    /// Wrapper client for S3 access.
    private let s3Client: S3Client

    /// Default query for fetch Sudos.
    private let defaultQuery: ListSudosQuery

    /// Cache for storing large binary objects.
    private let blobCache: BlobCache

    private let queue = DispatchQueue(label: "com.sudoplatform.sudoprofiles")

    /// Subscription manager for Sudo creation events.
    private var onCreateSubscriptionManager = SubscriptionManager<OnCreateSudoSubscription>()

    /// Subscription manager for Sudo update events.
    private var onUpdateSubscriptionManager = SubscriptionManager<OnUpdateSudoSubscription>()

    /// Subscription manager for Sudo deletion events.
    private var onDeleteSubscriptionManager = SubscriptionManager<OnDeleteSudoSubscription>()

    /// Queue for processing API result.
    private let apiResultQueue = DispatchQueue(label: "com.sudoplatform.sudoprofiles.api.result")

    /// Sudo ownership proof issuer.
    private let ownershipProofIssuer: OwnershipProofIssuer

    private let contentType = "binary/octet-stream"

    /// Intializes a new `DefaultSudoProfilesClient` instance.  It uses configuration parameters defined in
    /// `sudoplatformconfig.json` file located in the app bundle.
    ///
    /// - Parameters:
    ///   - sudoUserClient: `SudoUserClient` instance required to issue authentication tokens and perform cryptographic operations.
    ///   - blobContainerURL: Container URL to which large binary objects will be stored.
    ///   - maxSudos: Maximum number of Sudos to cap the queries to. Defaults to 10.
    ///   - logger: A logger to use for logging messages. If none provided then a default internal logger will be used.
    /// - Throws: `SudoProfilesClientError`
    convenience public init(sudoUserClient: SudoUserClient, blobContainerURL: URL, maxSudos: Int = 10) throws {
        guard let configManager = SudoConfigManagerFactory.instance.getConfigManager(name: SudoConfigManagerFactory.Constants.defaultConfigManagerName),
            let identityServiceConfig = configManager.getConfigSet(namespace: Config.Namespace.identityService),
            let apiServiceConfig = configManager.getConfigSet(namespace: Config.Namespace.apiService) else {
            throw SudoProfilesClientError.invalidConfig
        }

        guard let sudoServiceConfig = configManager.getConfigSet(namespace: Config.Namespace.sudoService) else {
            throw SudoProfilesClientError.sudoServiceConfigNotFound
        }

        // Use the singleton AppSync client instance if we are using the config file.
        guard let graphQLClient = try SudoApiClientManager.instance?.getClient(sudoUserClient: sudoUserClient) else {
            throw SudoProfilesClientError.invalidConfig
        }

        try self.init(config: [Config.Namespace.identityService: identityServiceConfig,
                               Config.Namespace.apiService: apiServiceConfig,
                               Config.Namespace.sudoService: sudoServiceConfig],
                      sudoUserClient: sudoUserClient, blobContainerURL: blobContainerURL, maxSudos: maxSudos, graphQLClient: graphQLClient)
    }

    /// Intializes a new `DefaultSudoProfilesClient` instance with the specified backend configuration.
    ///
    /// - Parameters:
    ///   - config: Configuration parameters for the client.
    ///   - sudoUserClient: `SudoUserClient` instance required to issue authentication tokens and perform cryptographic operations.
    ///   - cacheType: Cache type to use. Please refer to CacheType enum.
    ///   - blobContainerURL: Container URL to which large binary objects will be stored.
    ///   - maxSudos: Maximum number of Sudos to cap the quries to. Defaults to 10.
    ///   - logger: A logger to use for logging messages. If none provided then a default internal logger will be used.
    ///   - graphQLClient: Optional GraphQL client to use. Mainly used for unit testing.
    ///   - s3Client: Optional S3 client to use. Mainly use for unit testing.
    ///   - ownershipProofIssuer: Optional ownership proof issuer to use. Mainly use for testing of various service clients.
    /// - Throws: `SudoProfilesClientError`
    public init(config: [String: Any], sudoUserClient: SudoUserClient, cacheType: CacheType = .disk, blobContainerURL: URL, maxSudos: Int = 10, logger: Logger? = nil, cryptoProvider: CryptoProvider? = nil, graphQLClient: SudoApiClient? = nil, s3Client: S3Client? = nil, ownershipProofIssuer: OwnershipProofIssuer? = nil) throws {

        #if DEBUG
            AWSDDLog.sharedInstance.logLevel = .verbose
            AWSDDLog.add(AWSDDTTYLogger.sharedInstance)
        #endif

        let logger = logger ?? Logger.sudoProfilesClientLogger
        self.logger = logger
        self.blobCache = try BlobCache(containerURL: blobContainerURL)
        self.sudoUserClient = sudoUserClient
        self.cryptoProvider = cryptoProvider ?? DefaultCryptoProvider(keyNamespace: Constants.defaultKeyNamespace)

        if (try self.cryptoProvider.getSymmetricKeyId()) == nil {
            _ = try self.cryptoProvider.generateEncryptionKey()
        }

        self.s3Client = s3Client ?? DefaultS3Client(s3ClientKey: Constants.s3ClientKey)
        self.defaultQuery = ListSudosQuery(limit: maxSudos, nextToken: nil)

        // Currently there isn't Sudo Service specific config but we are just checking the existent
        // of it as an indication on whether or not Sudo Service is deployed.
        guard (config[Config.Namespace.sudoService] as? [String: Any]) != nil else {
            throw SudoProfilesClientError.sudoServiceConfigNotFound
        }

        guard let sudoServiceConfig = config[Config.Namespace.sudoService] as? [String: Any],
            let identityServiceConfig = config[Config.Namespace.identityService] as? [String: Any],
            let region = sudoServiceConfig[Config.SudoService.region] as? String,
            let bucket = sudoServiceConfig[Config.SudoService.bucket] as? String ?? identityServiceConfig[Config.SudoService.bucket] as? String else {
            throw SudoProfilesClientError.invalidConfig
        }

        self.region = region
        self.s3Bucket = bucket

        guard let graphQLClient = graphQLClient else {
            throw SudoProfilesClientError.invalidConfig
        }

        self.graphQLClient = graphQLClient
        try self.ownershipProofIssuer = ownershipProofIssuer ?? DefaultOwnershipProofIssuer(graphQLClient: graphQLClient)
    }

    public func createSudo(sudo: Sudo) async throws -> Sudo {
        self.logger.info("Creating a Sudo.")

        // Ensure we have an IdentityId. This ID is required
        // to authorize the access to S3 bucket and required to be a part of the S3 key.
        guard (await self.sudoUserClient.getIdentityId()) != nil else {
            self.logger.error("Identity ID is missing. The client may not be signed in yet.")
            throw SudoProfilesClientError.notSignedIn
        }

        // First create the Sudo without any claims since we need the Sudo ID to create
        // the blob claims in S3.
        self.logger.info("Creating a Sudo.")
        let input = CreateSudoInput(claims: [], objects: [])
        let (result, error) = try await self.graphQLClient.perform(mutation: CreateSudoMutation(input: input), queue: self.queue)
        if let error = error {
            self.logger.error("Failed to create a Sudo: \(error)")
            throw SudoProfilesClientError.fromApiOperationError(error: error)
        }

        guard let result = result else {
            self.logger.error("Mutation completed successfully but result is missing.")
            throw SudoProfilesClientError.fatalError(description: "Mutation completed successfully but result is missing.")
        }

        if let error = result.errors?.first {
            self.logger.error("Failed to create a Sudo: \(error)")
            throw SudoProfilesClientError.fromApiOperationError(error: error)
        }

        guard let sudoResult = result.data?.createSudo else {
            self.logger.error("Mutation result did not contain required object.")
            throw SudoProfilesClientError.fatalError(description: "Mutation result did not contain required object.")
        }

        var createdSudo = Sudo()
        createdSudo.id = sudoResult.id
        createdSudo.version = sudoResult.version
        createdSudo.createdAt = Date(millisecondsSinceEpoch: sudoResult.createdAtEpochMs)
        createdSudo.updatedAt = Date(millisecondsSinceEpoch: sudoResult.updatedAtEpochMs)

        let item = ListSudosQuery.Data.ListSudo.Item(id: sudoResult.id,
                                                     claims: sudoResult.claims.map {
                                                        ListSudosQuery.Data.ListSudo.Item.Claim(
                                                            name: $0.name,
                                                            version: $0.version,
                                                            algorithm: $0.algorithm,
                                                            keyId: $0.keyId,
                                                            base64Data: $0.base64Data
                                                        )
                                                     },
                                                     objects: sudoResult.objects.map {
                                                        ListSudosQuery.Data.ListSudo.Item.Object(
                                                            name: $0.name,
                                                            version: $0.version,
                                                            algorithm: $0.algorithm,
                                                            keyId: $0.keyId,
                                                            bucket: $0.bucket,
                                                            region: $0.region,
                                                            key: $0.key
                                                        )
                                                     },
                                                     metadata: sudoResult.metadata.map {
                                                        ListSudosQuery.Data.ListSudo.Item.Metadatum(
                                                            name: $0.name,
                                                            value: $0.value
                                                        )
                                                     },
                                                     createdAtEpochMs: sudoResult.createdAtEpochMs,
                                                     updatedAtEpochMs: sudoResult.updatedAtEpochMs,
                                                     version: sudoResult.version,
                                                     owner: sudoResult.owner)

        _ = try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Void, Error>) in
            _ = self.graphQLClient.getAppSyncClient().store?.withinReadWriteTransaction { transaction in
                do {
                    try transaction.update(query: self.defaultQuery) { (data: inout ListSudosQuery.Data) in
                        var listSudos = data.listSudos ?? ListSudosQuery.Data.ListSudo(items: [])
                        var items = listSudos.items ?? []
                        // There shouldn't be duplicate entries but just in case remove existing
                        // entry if found.
                        items = items.filter { $0.id != item.id }
                        items.append(item)
                        listSudos.items = items
                        data.listSudos = listSudos
                        continuation.resume()
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        })

        self.logger.info("Sudo created successfully. \(item.id)")
        // Update the newly created Sudo to add the claims.
        createdSudo.claims = sudo.claims
        let updatedSudo = try await self.updateSudo(sudo: createdSudo)
        self.logger.info("Created sudo claims updated successfully. \(String(describing: updatedSudo.getClaim(name: "avatar")))")
        return updatedSudo
    }

    public func updateSudo(sudo: Sudo) async throws -> Sudo {
        self.logger.info("Updating a Sudo.")

        guard let sudoId = sudo.id else {
            self.logger.error("Sudo ID is missing.")
            throw SudoProfilesClientError.invalidInput
        }

        // Retrieve the federated identity's ID from the identity client. This ID is required
        // to authorize the access to S3 bucket and required to be a part of the S3 key.
        guard let identityId = await self.sudoUserClient.getIdentityId() else {
            self.logger.error("Identity ID is missing. The client may not be signed in yet.")
            throw SudoProfilesClientError.notSignedIn
        }

        var updatedSudo = sudo

        // upload any blob claims.
        for var claim in updatedSudo.claims {
            switch (claim.visibility, claim.value) {
            case (.private, .blob(let value)):
                let blobCacheId = "sudo/\(sudoId)/\(claim.name)"
                do {
                    // Copy the blob into the cache and change the claim value to point
                    // to the cache entry since that's going to be master copy.
                    let cacheEntry = try self.blobCache.replace(fileURL: value, id: blobCacheId)
                    claim.value = .blob(cacheEntry.toURL())
                    updatedSudo.updateClaim(claim: claim)

                    let encryptedS3Data: Data
                    do {
                        // Retrieve the symmetric key ID required for encryption.
                        guard let keyId = try self.cryptoProvider.getSymmetricKeyId() else {
                            throw SudoProfilesClientError.fatalError(description: "Symmetric key missing.")
                        }

                        // Load the data from the cache and encrypt it.
                        let data = try cacheEntry.load()
                        encryptedS3Data = try self.cryptoProvider.encrypt(keyId: keyId, algorithm: .aesCBCPKCS7Padding, data: data)
                    } catch {
                        self.logger.error("Failed to encrypt data for upload: \(error)")
                        throw error
                    }

                    do {
                        // Upload the encrypted blob to S3. S3 key must be prefixed with the signed in user's federeated identity
                        // ID in order for the fine grained authorization to pass.
                        self.logger.info("Uploading encrypted blob to S3 bucket: \(self.s3Bucket), key: \(identityId)/\(cacheEntry.id)")
                        try await self.s3Client.upload(data: encryptedS3Data, contentType: self.contentType, bucket: self.s3Bucket, key: "\(identityId)/\(cacheEntry.id)")
                        self.logger.debug("successfully uploaded encrypted blob to key: \(identityId)/\(cacheEntry.id)")
                    } catch {
                        self.logger.error("Failed to upload the encrypted blob: \(error)")
                        throw error
                    }

                } catch {
                    self.logger.error("Failed to upload new Sudo blob claims: \(error)")
                    // remove the cache entry if there was an error uploading to S3
                    try self.blobCache.remove(id: blobCacheId)
                    throw error
                }
            default:
                break
            }
        }

        // Process secure claims or secure S3 objects associated with Sudo.
        var secureClaims: [SecureClaimInput] = []
        var secureS3Objects: [SecureS3ObjectInput] = []
        do {
            for claim in updatedSudo.claims {
                switch (claim.visibility, claim.value) {
                case (.private, .string(let value)):
                    secureClaims.append(try self.createSecureClaim(name: claim.name, value: value))
                case (.private, .blob(let value)):
                    secureS3Objects.append(try self.createSecureS3Object(name: claim.name, key: "\(identityId)/sudo/\(sudoId)/\(value.lastPathComponent)"))
                default:
                    // No other claim type currently supported.
                    break
                }
            }
        } catch {
            self.logger.error("Failed to process secure claims and objects: \(error)")
            throw error
        }

        let input = UpdateSudoInput(
            id: sudoId,
            claims: secureClaims,
            objects: secureS3Objects,
            expectedVersion: updatedSudo.version
        )

        var result: GraphQLResult<UpdateSudoMutation.Data>?
        var error: Error?
        do {
            (result, error) = try await self.graphQLClient.perform(mutation: UpdateSudoMutation(input: input), queue: self.queue)
        } catch {
            throw SudoProfilesClientError.fromApiOperationError(error: error)
        }
        if let error = error {
            self.logger.error("Failed to update a Sudo: \(error)")
            throw SudoProfilesClientError.fromApiOperationError(error: error)
        }

        guard let result = result else {
            self.logger.error("Mutation completed successfully but result is missing.")
            throw SudoProfilesClientError.fatalError(description: "Mutation completed successfully but result is missing.")
        }

        if let error = result.errors?.first {
            self.logger.error("Failed to update a Sudo: \(error)")
            throw SudoProfilesClientError.fromApiOperationError(error: error)
        }

        guard let resultSudo = result.data?.updateSudo else {
            self.logger.error("Mutation result did not contain required object.")
            throw SudoProfilesClientError.fatalError(description: "Mutation result did not contain required object.")
        }

        updatedSudo.id = resultSudo.id
        updatedSudo.version = resultSudo.version
        updatedSudo.createdAt = Date(millisecondsSinceEpoch: resultSudo.createdAtEpochMs)
        updatedSudo.updatedAt = Date(millisecondsSinceEpoch: resultSudo.updatedAtEpochMs)

        self.logger.info("Sudo updated successfully.")
        return updatedSudo
    }

    public func deleteSudo(sudo: Sudo) async throws {
        self.logger.info("Deleting a Sudo.")

        guard try await self.sudoUserClient.isSignedIn() else {
            throw SudoProfilesClientError.notSignedIn
        }

        // Create delete blob operations for any blob claims.
        for claim in sudo.claims {
            switch claim.value {
            case .blob(let value):
                if let cacheEntry = self.blobCache.get(url: value) {
                    do {
                        try self.blobCache.remove(id: cacheEntry.id)
                    } catch {
                        self.logger.error("Failed to remove the blob from the local cache.")
                        throw error
                    }
                }
            default:
                break
            }
        }

        guard let id = sudo.id else {
            self.logger.error("Sudo ID is missing but is required to delete a Sudo.")
            throw SudoProfilesClientError.invalidInput
        }

        var result: GraphQLResult<DeleteSudoMutation.Data>?
        var error: Error?

        do {
            (result, error) = try await self.graphQLClient.perform(mutation: DeleteSudoMutation(input: DeleteSudoInput(id: id, expectedVersion: sudo.version)), queue: self.queue)
        } catch {
            self.logger.error("Failed to delete Sudo due to thrown error \(error)")
            throw SudoProfilesClientError.fromApiOperationError(error: error)
        }

        if let error = error {
            self.logger.error("Failed to delete a Sudo with error: \(error)")
            throw SudoProfilesClientError.fromApiOperationError(error: error)
        }

        guard let result = result else {
            self.logger.error("Mutation completed successfully but result is missing.")
            throw SudoProfilesClientError.fatalError(description: "Mutation completed successfully but result is missing.")
        }

        if let error = result.errors?.first {
            self.logger.error("Failed to delete a Sudo with result.errors: \(error)")
            throw SudoProfilesClientError.fromApiOperationError(error: error)
        }

        guard let item = result.data?.deleteSudo else {
            self.logger.error("Mutation completed successfully but result is empty.")
            throw SudoProfilesClientError.fatalError(description: "Mutation completed successfully but result is empty.")
        }

        _ = try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Void, Error>) in
            _ = self.graphQLClient.getAppSyncClient().store?.withinReadWriteTransaction { transaction in
                do {
                    try transaction.update(query: self.defaultQuery) { (data: inout ListSudosQuery.Data) in
                        // Remove the deleted Sudo from the cache.
                        let newState = data.listSudos?.items?.filter { $0.id != item.id }
                        data.listSudos?.items = newState
                        continuation.resume()
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        })
        self.logger.info("Sudo deleted successfully.")
    }

    public func listSudos(option: ListOption) async throws -> [Sudo] {
        self.logger.info("Listing Sudos.")

        let cachePolicy: CachePolicy
        switch option {
        case .cacheOnly:
            cachePolicy = .returnCacheDataDontFetch
        case .remoteOnly:
            cachePolicy = .fetchIgnoringCacheData
        case .returnCachedElseFetch:
            cachePolicy = .returnCacheDataElseFetch
        }

        var result: GraphQLResult<ListSudosQuery.Data>?
        var error: Error?
        do {
            (result, error) = try await self.graphQLClient.fetch(query: self.defaultQuery, cachePolicy: cachePolicy, queue: self.queue)
        } catch {
            throw SudoProfilesClientError.fromApiOperationError(error: error)
        }
        if let error = error {
            self.logger.error("Failed to list sudos \(error)")
            throw SudoProfilesClientError.fromApiOperationError(error: error)
        }

        guard let result = result else {
            return []
        }

        if let error = result.errors?.first {
            self.logger.error("listSudos query failed with errors: \(error)")
            throw SudoProfilesClientError.fromApiOperationError(error: error)
        }

        guard let items = result.data?.listSudos?.items else {
            self.logger.error("Query result contained no list data.")
            throw SudoProfilesClientError.fatalError(description: "Query result contained no list data.")
        }

        self.logger.info("Sudos fetched successfully. Processing the result....")
        do {
            return try await self.processListSudosResult(items: items, option: option, processS3Objects: true)
        } catch {
            self.logger.error("Failed to process list sudos result \(error)")
            throw error
        }
    }

    public func getOutstandingRequestsCount() -> Int {
        return self.graphQLClient.serialQueue.operationCount
    }

    public func reset() throws {
        self.logger.info("Resetting client state.")

        try self.graphQLClient.clearCaches(options: .init(clearQueries: true, clearMutations: true, clearSubscriptions: true))
        try self.blobCache.reset()
        try self.cryptoProvider.reset()
        self.unsubscribeAll()
    }

    public func subscribe(id: String, subscriber: SudoSubscriber) async throws {
        try await self.subscribe(id: id, changeType: .create, subscriber: subscriber)
        try await self.subscribe(id: id, changeType: .delete, subscriber: subscriber)
        try await self.subscribe(id: id, changeType: .update, subscriber: subscriber)
    }

    public func subscribe(id: String, changeType: SudoChangeType, subscriber: SudoSubscriber) async throws {
        self.logger.info("Subscribing for Sudo change notification.")

        guard let owner = try self.sudoUserClient.getSubject() else {
            throw SudoProfilesClientError.notSignedIn
        }

        switch changeType {
        case .create:
            self.onCreateSubscriptionManager.replaceSubscriber(id: id, subscriber: subscriber)

            guard self.onCreateSubscriptionManager.watcher == nil else {
                // If there's existing AppSync subscription then immediately notify the subscriber
                // that the subscription is already connected.
                subscriber.connectionStatusChanged(state: .connected)
                return
            }

            let createSubscription = OnCreateSudoSubscription(owner: owner)
            self.onCreateSubscriptionManager.watcher = try await self.graphQLClient.subscribe(subscription: createSubscription, queue: self.apiResultQueue, statusChangeHandler: { (status) in
                self.onCreateSubscriptionManager.connectionStatusChanged(status: status)
            }, resultHandler: { [weak self] (result, transaction, error) in
                guard let self = self else {
                    return
                }

                if let error = error {
                    self.logger.error("Subscription callback invoked with an error: \(error)")
                    return
                }

                guard let result = result else {
                    self.logger.error("Subscription callback called but result was missing.")
                    return
                }

                guard let response = result.data?.onCreateSudo else {
                    self.logger.error("GraphQL response data was missing.")
                    return
                }

                let item = ListSudosQuery.Data.ListSudo.Item(id: response.id,
                                                             claims: response.claims.map {
                                                                ListSudosQuery.Data.ListSudo.Item.Claim(
                                                                    name: $0.name,
                                                                    version: $0.version,
                                                                    algorithm: $0.algorithm,
                                                                    keyId: $0.keyId,
                                                                    base64Data: $0.base64Data
                                                                )
                    },
                                                             objects: response.objects.map {
                                                                ListSudosQuery.Data.ListSudo.Item.Object(
                                                                    name: $0.name,
                                                                    version: $0.version,
                                                                    algorithm: $0.algorithm,
                                                                    keyId: $0.keyId,
                                                                    bucket: $0.bucket,
                                                                    region: $0.region,
                                                                    key: $0.key
                                                                )
                    },
                                                             metadata: response.metadata.map {
                                                                ListSudosQuery.Data.ListSudo.Item.Metadatum(
                                                                    name: $0.name,
                                                                    value: $0.value
                                                                )
                    },
                                                             createdAtEpochMs: response.createdAtEpochMs,
                                                             updatedAtEpochMs: response.updatedAtEpochMs,
                                                             version: response.version,
                                                             owner: response.owner)

                do {
                    // Update the query cache.
                    try transaction?.update(query: self.defaultQuery) { (data: inout ListSudosQuery.Data) in
                        var listSudos = data.listSudos ?? ListSudosQuery.Data.ListSudo(items: [])
                        var items = listSudos.items ?? []
                        // There shouldn't be duplicate entries but just in case remove existing
                        // entry if found.
                        items = items.filter { $0.id != item.id }
                        items.append(item)
                        listSudos.items = items
                        data.listSudos = listSudos
                    }
                } catch let error {
                    self.logger.error("Query cache updated failed: \(error)")
                }
                Task.detached(priority: .medium) {
                    do {
                        let sudos = try await self.processListSudosResult(items: [item], option: .cacheOnly, processS3Objects: false)
                        guard let sudo = sudos.first else {
                            return
                        }
                        self.onCreateSubscriptionManager.sudoChanged(changeType: .create, sudo: sudo)
                    } catch {
                        self.logger.info("processListSudosResult failed \(error)")
                    }
                }
            })
        case .update:
            self.onUpdateSubscriptionManager.replaceSubscriber(id: id, subscriber: subscriber)

            guard self.onUpdateSubscriptionManager.watcher == nil else {
                // If there's existing AppSync subscription then immediately notify the subscriber
                // that the subscription is already connected.
                subscriber.connectionStatusChanged(state: .connected)
                return
            }

            let updateSubscription = OnUpdateSudoSubscription(owner: owner)
            self.onUpdateSubscriptionManager.watcher = try await self.graphQLClient.subscribe(subscription: updateSubscription, queue: self.apiResultQueue, statusChangeHandler: { (status) in
                self.onUpdateSubscriptionManager.connectionStatusChanged(status: status)
            }, resultHandler: { [weak self] (result, transaction, error) in
                guard let self = self else {
                    return
                }

                if let error = error {
                    self.logger.error("Subscription callback invoked with an error: \(error)")
                    return
                }

                guard let result = result else {
                    self.logger.error("Subscription callback called but result was missing.")
                    return
                }

                guard let response = result.data?.onUpdateSudo else {
                    self.logger.error("GraphQL response data was missing.")
                    return
                }

                let item = ListSudosQuery.Data.ListSudo.Item(id: response.id,
                                                             claims: response.claims.map {
                                                                ListSudosQuery.Data.ListSudo.Item.Claim(
                                                                    name: $0.name,
                                                                    version: $0.version,
                                                                    algorithm: $0.algorithm,
                                                                    keyId: $0.keyId,
                                                                    base64Data: $0.base64Data
                                                                )
                    },
                                                             objects: response.objects.map {
                                                                ListSudosQuery.Data.ListSudo.Item.Object(
                                                                    name: $0.name,
                                                                    version: $0.version,
                                                                    algorithm: $0.algorithm,
                                                                    keyId: $0.keyId,
                                                                    bucket: $0.bucket,
                                                                    region: $0.region,
                                                                    key: $0.key
                                                                )
                    },
                                                             metadata: response.metadata.map {
                                                                ListSudosQuery.Data.ListSudo.Item.Metadatum(
                                                                    name: $0.name,
                                                                    value: $0.value
                                                                )
                    },
                                                             createdAtEpochMs: response.createdAtEpochMs,
                                                             updatedAtEpochMs: response.updatedAtEpochMs,
                                                             version: response.version,
                                                             owner: response.owner)

                do {
                    // Update the query cache.
                    try transaction?.update(query: self.defaultQuery) { (data: inout ListSudosQuery.Data) in
                        guard let items = data.listSudos?.items else {
                            return
                        }

                        // Replace the older entry.
                        let newState = items.filter { !($0.id == item.id && $0.updatedAtEpochMs < item.updatedAtEpochMs) }
                        if newState.count < items.count {
                            data.listSudos?.items = newState
                            data.listSudos?.items?.append(item)
                        }
                    }
                } catch let error {
                    self.logger.error("Query cache updated failed: \(error)")
                }

                Task.detached(priority: .medium) {
                    do {
                        let sudos = try await self.processListSudosResult(items: [item], option: .cacheOnly, processS3Objects: false)
                        guard let sudo = sudos.first else {
                            return
                        }
                        self.onUpdateSubscriptionManager.sudoChanged(changeType: .update, sudo: sudo)
                    } catch {
                        self.logger.info("processListSudosResult failed \(error)")
                    }
                }
            })
        case .delete:
            self.onDeleteSubscriptionManager.replaceSubscriber(id: id, subscriber: subscriber)

            guard self.onDeleteSubscriptionManager.watcher == nil else {
                // If there's existing AppSync subscription then immediately notify the subscriber
                // that the subscription is already connected.
                subscriber.connectionStatusChanged(state: .connected)
                return
            }

            let deleteSubscription = OnDeleteSudoSubscription(owner: owner)
            self.onDeleteSubscriptionManager.watcher = try await self.graphQLClient.subscribe(subscription: deleteSubscription, queue: self.apiResultQueue, statusChangeHandler: { (status) in
                self.onDeleteSubscriptionManager.connectionStatusChanged(status: status)
            }, resultHandler: { [weak self] (result, transaction, error) in
                guard let self = self else {
                    return
                }

                if let error = error {
                    self.logger.error("Subscription callback invoked with an error: \(error)")
                    return
                }

                guard let result = result else {
                    self.logger.error("Subscription callback called but result was missing.")
                    return
                }

                guard let response = result.data?.onDeleteSudo else {
                    self.logger.error("GraphQL response data was missing.")
                    return
                }

                let item = ListSudosQuery.Data.ListSudo.Item(id: response.id,
                                                             claims: response.claims.map {
                                                                ListSudosQuery.Data.ListSudo.Item.Claim(
                                                                    name: $0.name,
                                                                    version: $0.version,
                                                                    algorithm: $0.algorithm,
                                                                    keyId: $0.keyId,
                                                                    base64Data: $0.base64Data
                                                                )
                    },
                                                             objects: response.objects.map {
                                                                ListSudosQuery.Data.ListSudo.Item.Object(
                                                                    name: $0.name,
                                                                    version: $0.version,
                                                                    algorithm: $0.algorithm,
                                                                    keyId: $0.keyId,
                                                                    bucket: $0.bucket,
                                                                    region: $0.region,
                                                                    key: $0.key
                                                                )
                    },
                                                             metadata: response.metadata.map {
                                                                ListSudosQuery.Data.ListSudo.Item.Metadatum(
                                                                    name: $0.name,
                                                                    value: $0.value
                                                                )
                    },
                                                             createdAtEpochMs: response.createdAtEpochMs,
                                                             updatedAtEpochMs: response.updatedAtEpochMs,
                                                             version: response.version,
                                                             owner: response.owner)

                do {
                    let query = ListSudosQuery()
                    try transaction?.update(query: query) { (data: inout ListSudosQuery.Data) in
                        // Remove the deleted Sudo from the cache.
                        let newState = data.listSudos?.items?.filter { $0.id != item.id }
                        data.listSudos?.items = newState
                    }
                } catch let error {
                    self.logger.error("Query cache updated failed: \(error)")
                }

                Task.detached(priority: .medium) {
                    do {
                        let sudos = try await self.processListSudosResult(items: [item], option: .cacheOnly, processS3Objects: false)
                        guard let sudo = sudos.first else {
                            return
                        }
                        self.onDeleteSubscriptionManager.sudoChanged(changeType: .delete, sudo: sudo)
                    } catch {
                        self.logger.info("processListSudosResult failed \(error)")
                    }
                }
            })
        }
    }

    public func unsubscribe(id: String, changeType: SudoChangeType) {
        self.logger.info("Unsubscribing from Sudo change notification.")

        switch changeType {
        case .create:
            self.onCreateSubscriptionManager.removeSubscriber(id: id)
        case .update:
            self.onUpdateSubscriptionManager.removeSubscriber(id: id)
        case .delete:
            self.onDeleteSubscriptionManager.removeSubscriber(id: id)
        }
    }

    public func unsubscribe(id: String) {
        self.logger.info("Unsubscribing from all Sudo change notification.")
        self.unsubscribe(id: id, changeType: .create)
        self.unsubscribe(id: id, changeType: .update)
        self.unsubscribe(id: id, changeType: .delete)
    }

    public func unsubscribeAll() {
        self.logger.info("Unsubscribing all subscribers from Sudo change notification.")

        self.onCreateSubscriptionManager.removeAllSubscribers()
        self.onUpdateSubscriptionManager.removeAllSubscribers()
        self.onDeleteSubscriptionManager.removeAllSubscribers()
    }

    public func getOwnershipProof(sudo: Sudo, audience: String) async throws -> String {
        self.logger.info("Retrieving ownership proof.")

        guard let subject = try self.sudoUserClient.getSubject() else {
            throw SudoProfilesClientError.notSignedIn
        }

        guard let sudoId = sudo.id else {
            throw SudoProfilesClientError.invalidInput
        }

        return try await self.ownershipProofIssuer.getOwnershipProof(ownerId: sudoId, subject: subject, audience: audience)
    }

    public func generateEncryptionKey() throws -> String {
        return try self.cryptoProvider.generateEncryptionKey()
    }

    public func getSymmetricKeyId() throws -> String? {
        return try self.cryptoProvider.getSymmetricKeyId()
    }

    public func importEncryptionKeys(keys: [EncryptionKey], currentKeyId: String) throws {
        try self.cryptoProvider.importEncryptionKeys(keys: keys, currentKeyId: currentKeyId)
    }

    public func exportEncryptionKeys() throws -> [EncryptionKey] {
        return try self.cryptoProvider.exportEncryptionKeys()
    }

    private func processSecureClaim(secureClaim: ListSudosQuery.Data.ListSudo.Item.Claim) throws -> Claim {
        guard let algorithm = SymmetricKeyEncryptionAlgorithm(rawValue: secureClaim.algorithm) else {
            self.logger.error("Secure claim encryption algorithm is invalid.")
            throw SudoProfilesClientError.badData
        }

        guard let encryptedData = Data(base64Encoded: secureClaim.base64Data) else {
            self.logger.error("Failed to base64 decode secure claim.")
            throw SudoProfilesClientError.badData
        }

        let decryptedData = try self.cryptoProvider.decrypt(keyId: secureClaim.keyId, algorithm: algorithm, data: encryptedData)

        guard let value = String(data: decryptedData, encoding: .utf8) else {
            self.logger.error("Secure claim value cannot be encoded to String.")
            throw SudoProfilesClientError.badData
        }

        return Claim(name: secureClaim.name, visibility: .private, value: .string(value))
    }

    private func getS3ObjectIdFromKey(key: String) -> String? {
        let components = key.components(separatedBy: "/")
        return components.last
    }

    private func processListSudosResult(items: [ListSudosQuery.Data.ListSudo.Item], option: ListOption, processS3Objects: Bool) async throws -> [Sudo] {
        var sudos: [Sudo] = []
        for item in items {
            do {
                var sudo = Sudo(id: item.id,
                                version: item.version,
                                createdAt: Date(timeIntervalSince1970: item.createdAtEpochMs / 1000),
                                updatedAt: Date(timeIntervalSince1970: item.updatedAtEpochMs / 1000)
                                )
                for metadata in item.metadata {
                    sudo.metadata[metadata.name] = metadata.value
                }

                // Process secure claims which need to be decrypted using the specified key.
                for secureClaim in item.claims {
                    sudo.updateClaim(claim: try self.processSecureClaim(secureClaim: secureClaim))
                }
                if processS3Objects {
                    // Process secure s3 objects which need to be downloaded from AWS S3 and decrypted
                    // using the specified key.
                    for secureS3Object in item.objects {
                        guard let objectId = self.getS3ObjectIdFromKey(key: secureS3Object.key) else {
                            self.logger.error("Invalid key in SecureS3Object.")
                            throw SudoProfilesClientError.fatalError(description: "Invalid key in SecureS3Object.")
                        }

                        // Check if we already have the S3 object in the cache. Return the cache entry
                        // if asked to fetch from cache but otherwise download the S3 object.
                        if let cacheEntry = self.blobCache.get(id: objectId),
                            option == ListOption.cacheOnly {
                            sudo.updateClaim(claim: Claim(name: secureS3Object.name, visibility: .private, value: .blob(cacheEntry.toURL())))
                        } else {
                            sudo.updateClaim(claim: Claim(name: secureS3Object.name, visibility: .private, value: .blob(self.blobCache.cacheUrlFromId(id: objectId))))
                            guard let algorithm = SymmetricKeyEncryptionAlgorithm(rawValue: secureS3Object.algorithm) else {
                                self.logger.error("Invalid encryption algorithm specified.")
                                throw SudoProfilesClientError.invalidInput
                            }

                            do {
                                self.logger.info("Downloading encrypted blob from S3. key: \(secureS3Object.key)")
                                let data = try await self.s3Client.download(bucket: secureS3Object.bucket, key: secureS3Object.key)
                                self.logger.info("Encrypted blob downloaded successfully.")

                                do {
                                    // Decrypt the downloaded blob and store it in the local cache.
                                    let decryptedData = try self.cryptoProvider.decrypt(keyId: secureS3Object.keyId, algorithm: algorithm, data: data)
                                    try _ = self.blobCache.replace(data: decryptedData, id: objectId)
                                } catch {
                                    self.logger.error("Failed to decrypt the encrypted blob: \(error)")
                                    throw error
                                }
                            } catch {
                                self.logger.error("Failed to download the encrypted blob: \(error)")
                                throw error
                            }

                        }
                    }
                }
                sudos.append(sudo)
            } catch {
                self.logger.error("Failed to process secure claims: \(error)")
                throw error
            }
        }
        return sudos
    }

    /// Create a secure claim from a name and a String value.
    ///
    /// - Parameters:
    ///   - name: Claim name.
    ///   - value: String value of the claim.
    /// - Returns: Secure claim.
    private func createSecureClaim(name: String, value: String) throws -> SecureClaimInput {
        guard let keyId = try self.cryptoProvider.getSymmetricKeyId() else {
            throw SudoProfilesClientError.fatalError(description: "Symmetric key missing.")
        }
        let encrypted = try self.cryptoProvider.encrypt(keyId: keyId, algorithm: SymmetricKeyEncryptionAlgorithm.aesCBCPKCS7Padding, data: value.data(using: .utf8)!)
        return SecureClaimInput(name: name,
                                version: 1,
                                algorithm: SymmetricKeyEncryptionAlgorithm.aesCBCPKCS7Padding.rawValue,
                                keyId: keyId,
                                base64Data: encrypted.base64EncodedString())
    }

    /// Creates a secure S3 object from a name and a key.
    ///
    /// - Parameters:
    ///   - name: Object name.
    ///   - key: Object key.
    /// - Returns: Secure S3 object.
    private func createSecureS3Object(name: String, key: String) throws -> SecureS3ObjectInput {
        guard let keyId = try self.cryptoProvider.getSymmetricKeyId() else {
            throw SudoProfilesClientError.fatalError(description: "Symmetric key missing.")
        }
        return SecureS3ObjectInput(name: name,
                                   version: 1,
                                   algorithm: SymmetricKeyEncryptionAlgorithm.aesCBCPKCS7Padding.rawValue,
                                   keyId: keyId,
                                   bucket: self.s3Bucket,
                                   region: self.region,
                                   key: key)
    }
}
