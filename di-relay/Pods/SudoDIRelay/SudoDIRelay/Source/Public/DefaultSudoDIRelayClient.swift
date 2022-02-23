//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
// swiftlint:disable nesting
// swiftlint:disable type_name

import AWSAppSync
import SudoLogging
import SudoConfigManager
import SudoUser

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

    /// App sync client for peforming operations against the relay service.
    let appSyncClient: AWSAppSyncClient

    /// Used to log diagnostic and error information.
    let logger: Logger

    /// Utility factory class to generate use cases.
    let useCaseFactory: UseCaseFactory

    /// Client used to authenticate to Sudo Platform.
    let sudoUserClient: SudoUserClient

    /// Helper class to create AWS AppSyncClient
    let appSyncClientHelper: AppSyncClientHelper

    /// Relay service that does the work of interacting with the service via GraphQL.
    let relayService: RelayService

    var allResetables: [Resetable] {
        return [
            relayService
        ]
    }

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

        guard let appSyncClient = appSyncHelper.getAppSyncClient() else {
            throw SudoDIRelayError.invalidConfig
        }

        let relayService = DefaultRelayService(appSyncClient: appSyncClient, appSyncClientHelper: appSyncHelper)
        self.init(
            appSyncClient: appSyncClient,
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
        appSyncClient: AWSAppSyncClient,
        appSyncClientHelper: AppSyncClientHelper,
        sudoUserClient: SudoUserClient,
        useCaseFactory: UseCaseFactory,
        relayService: RelayService,
        logger: Logger = .relaySDKLogger
    ) {
        self.appSyncClient = appSyncClient
        self.appSyncClientHelper = appSyncClientHelper
        self.sudoUserClient = sudoUserClient
        self.useCaseFactory = useCaseFactory
        self.relayService = relayService
        self.logger = logger
    }
    // MARK: - Methods

    public func reset() throws {
        allResetables.forEach { $0.reset() }
        try self.appSyncClient.clearCaches(options: .init(clearQueries: true, clearMutations: true, clearSubscriptions: false))
    }

// MARK: - Conformance: SudoDIRelayClient

    public func getMessages(withConnectionId connectionId: String, completion: @escaping ClientCompletion<[RelayMessage]>) {
        let useCase = useCaseFactory.generateGetMessages()
        useCase.execute(withConnectionId: connectionId, completion: completion)
    }

    public func storeMessage(
        withConnectionId connectionId: String,
        message: String,
        completion: @escaping ClientCompletion<RelayMessage?>
    ) {
        let useCase = useCaseFactory.generateStoreMessage()
        useCase.execute(withConnectionId: connectionId, message: message, completion: completion)
    }

    public func createPostbox(withConnectionId connectionId: String, completion: @escaping ClientCompletion<Void>) {
        let useCase = useCaseFactory.generateCreatePostbox()
        useCase.execute(withConnectionId: connectionId, completion: completion)
    }

    public func deletePostbox(withConnectionId connectionId: String, completion: @escaping ClientCompletion<Void>) {
        let useCase = useCaseFactory.generateDeletePostbox()
        useCase.execute(withConnectionId: connectionId, completion: completion)
    }

    public func subscribeToMessagesReceived(
        withConnectionId connectionId: String,
        resultHandler: @escaping ClientCompletion<RelayMessage>
    ) -> SubscriptionToken? {
        let useCase = useCaseFactory.generateSubscribeToMessagesReceived()
        let token = useCase.execute(withConnectionId: connectionId, completion: resultHandler)
        return token
    }

    public func subscribeToPostboxDeleted(
        withConnectionId connectionId: String,
        resultHandler: @escaping ClientCompletion<Status>
    ) -> SubscriptionToken? {
        let useCase = useCaseFactory.generateSubscribeToPostboxDeleted()
        let token = useCase.execute(withConnectionId: connectionId, completion: resultHandler)
        return token
    }

    public func getPostboxEndpoint(withConnectionId connectionId: String) -> URL? {
        let useCase = useCaseFactory.generateGetPostboxEndpoint()
        let endpoint = useCase.execute(withConnectionId: connectionId)
        return endpoint
    }
}
