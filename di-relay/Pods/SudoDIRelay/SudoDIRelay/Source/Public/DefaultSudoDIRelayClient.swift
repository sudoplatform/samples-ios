//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
// swiftlint:disable nesting

import AWSAppSync
import SudoLogging
import SudoConfigManager
import SudoUser
import SudoApiClient

/// Default Client API Endpoint for interacting with the Relay Service.
public class DefaultSudoDIRelayClient: SudoDIRelayClient {

    // MARK: - Supplementary

    /// Configuration parameter names.
    public struct Config {

        /// Configuration namespace.
        struct Namespace {

            /// Relay service related configuration.
            static let RelayService = "relayService"
        }
    }

    // MARK: - Properties

    /// Used to log diagnostic and error information.
    let logger: Logger

    /// Utility factory class to generate use cases.
    let useCaseFactory: UseCaseFactory

    /// Client used to authenticate to Sudo Platform.
    let sudoUserClient: SudoUserClient

    /// Helper class to create AWS AppSyncClient
    let appSyncClientHelper: AppSyncClientHelper

    /// App sync client for peforming operations against the relay service.
    let sudoApiClient: SudoApiClient

    /// Relay service that does the work of interacting with the service via GraphQL.
    let relayService: RelayService

    // MARK: - Lifecycle

    /// Initialize an instance of `DefaultSudoDIRelayClient`. It uses configuration parameters defined in
    /// `sudoplatformconfig.json` file located in the app bundle.
    /// - Parameters:
    ///   - sudoUserClient: SudoUserClient instance used for authenticating to the backend..
    /// Throws:
    ///     - `SudoDIRelayError` if invalid config.
    public convenience init(sudoUserClient: SudoUserClient) throws {
        guard let configManager = SudoConfigManagerFactory.instance.getConfigManager(name: SudoConfigManagerFactory.Constants.defaultConfigManagerName) else {
            throw SudoDIRelayError.invalidConfig
        }
        guard configManager.getConfigSet(namespace: "apiService") != nil else {
            throw SudoDIRelayError.invalidConfig
        }
        guard configManager.getConfigSet(namespace: Config.Namespace.RelayService) != nil else {
            throw SudoDIRelayError.relayServiceConfigNotFound
        }

        let appSyncHelper = try DefaultAppSyncClientHelper(userClient: sudoUserClient)

        let sudoApiClient = appSyncHelper.getSudoApiClient()

        let relayService = DefaultRelayService(sudoApiClient: sudoApiClient, appSyncClientHelper: appSyncHelper)

        self.init(
            sudoApiClient: sudoApiClient,
            appSyncClientHelper: appSyncHelper,
            sudoUserClient: sudoUserClient,
            useCaseFactory: UseCaseFactory(relayService: relayService),
            relayService: relayService
        )
    }

    /// Initialize an instance of `DefaultSudoDIRelayClient`.
    ///
    /// This is used internally for injection and mock testing.
    init(
        sudoApiClient: SudoApiClient,
        appSyncClientHelper: AppSyncClientHelper,
        sudoUserClient: SudoUserClient,
        useCaseFactory: UseCaseFactory,
        relayService: RelayService,
        logger: Logger = .relaySDKLogger
    ) {
        self.sudoApiClient = sudoApiClient
        self.appSyncClientHelper = appSyncClientHelper
        self.sudoUserClient = sudoUserClient
        self.useCaseFactory = useCaseFactory
        self.relayService = relayService
        self.logger = logger
    }
    // MARK: - Methods

    public func reset() throws {
        try self.sudoApiClient.clearCaches(options: .init(clearQueries: true, clearMutations: true, clearSubscriptions: false))
    }

// MARK: - Conformance: SudoDIRelayClient

    public func listMessages(withConnectionId connectionId: String) async throws -> [RelayMessage] {
        let useCase = useCaseFactory.generateListMessages()
        return try await useCase.execute(withConnectionId: connectionId)
    }

    public func storeMessage(withConnectionId connectionId: String, message: String) async throws -> RelayMessage? {
        let useCase = useCaseFactory.generateStoreMessage()
        return try await useCase.execute(withConnectionId: connectionId, message: message)
    }

    public func createPostbox(withConnectionId connectionId: String, ownershipProofToken: String) async throws {
        let useCase = useCaseFactory.generateCreatePostbox()
        try await useCase.execute(withConnectionId: connectionId, ownershipProofToken: ownershipProofToken)
    }

    public func deletePostbox(withConnectionId connectionId: String) async throws {
        let useCase = useCaseFactory.generateDeletePostbox()
        try await useCase.execute(withConnectionId: connectionId)
    }

    public func getPostboxEndpoint(withConnectionId connectionId: String) -> URL? {
        let useCase = useCaseFactory.generateGetPostboxEndpoint()
        let endpoint = useCase.execute(withConnectionId: connectionId)
        return endpoint
    }

    public func listPostboxes(withSudoId sudoId: String) async throws -> [Postbox] {
        let useCase = useCaseFactory.generateListPostboxes()
        return try await useCase.execute(withSudoId: sudoId)
    }

    public func subscribeToMessagesReceived(
        withConnectionId connectionId: String,
        resultHandler: @escaping ClientCompletion<RelayMessage>
    ) async throws -> SubscriptionToken? {
        let useCase = useCaseFactory.generateSubscribeToMessagesReceived()
        let token = try await useCase.execute(withConnectionId: connectionId, completion: resultHandler)
        return token
    }

    public func subscribeToPostboxDeleted(
        withConnectionId connectionId: String,
        resultHandler: @escaping ClientCompletion<Status>
    ) async throws -> SubscriptionToken? {
        let useCase = useCaseFactory.generateSubscribeToPostboxDeleted()
        let token = try await useCase.execute(withConnectionId: connectionId, completion: resultHandler)
        return token
    }

}
