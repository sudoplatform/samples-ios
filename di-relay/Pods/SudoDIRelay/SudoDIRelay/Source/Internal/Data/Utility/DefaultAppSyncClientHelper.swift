//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSAppSync
import SudoLogging
import AWSCore
import SudoConfigManager
import SudoUser

public class DefaultAppSyncClientHelper: AppSyncClientHelper {

    // MARK: - Supplementary

    struct Namespace {
        /// Relay service.
        static let relayService = "relayService"
    }

    struct RelayService {
        /// Api key to do simple auth.
        static let apiKey = "apiKey"

        /// GraphQL url.
        static let apiUrl = "apiUrl"

        /// HTTP endpoint.
        static let httpEndpoint = "httpEndpoint"
    }

    // MARK: - Properties

    /// Default logger for DefaultAppSyncClientHelper.
    private let logger: Logger = Logger(identifier: "DefaultAppSyncClientHelper", driver: NSLogDriver(level: .debug))

    /// GraphQL client used calling Identity Service API.
    private var appSyncClient: AWSAppSyncClient?

    /// HTTP endpoint for peers to post messages to.
    private var relayServiceEndpoint: String

    // MARK: - Lifecycle

    /// Intializes a new `DefaultAppSyncClientHelper` instance. It uses configuration parameters defined in
    /// `sudoplatformconfig.json` file located in the app bundle.
    public init(userClient: SudoUserClient) throws {
        /// Programatically get SDK config via SudoConfigManager
        guard
            let configManager = DefaultSudoConfigManager(),
            let relayServiceConfig = configManager.getConfigSet(namespace: Namespace.relayService) else {
            throw SudoDIRelayError.invalidConfig
        }

        /// GraphQL url
        guard
            let graphqlUrlAsString = relayServiceConfig[RelayService.apiUrl] as? String,
            let graphQlUrl = URL(string: graphqlUrlAsString) else {
            throw SudoDIRelayError.invalidConfig
        }

        /// AppSync client
        let config: SudoDIRelayConfig = SudoDIRelayConfig(endpoint: graphQlUrl, region: AWSRegionType.USEast1)
        let authProvider = GraphQLAuthProvider(client: userClient)
        let cacheConfiguration = try AWSAppSyncCacheConfiguration()
        let appSyncConfig = try AWSAppSyncClientConfiguration(
            appSyncServiceConfig: config,
            userPoolsAuthProvider: authProvider,
            cacheConfiguration: cacheConfiguration)
        self.appSyncClient = try AWSAppSyncClient(appSyncConfig: appSyncConfig)
        self.appSyncClient?.apolloClient?.cacheKeyForObject = { $0["id"] }

        /// HTTP endpoint
        guard let endpoint = relayServiceConfig[RelayService.httpEndpoint] as? String else {
            throw SudoDIRelayError.invalidConfig
        }
        self.relayServiceEndpoint = endpoint
    }

    // MARK: - Conformance: AppSyncClientHelper

    public func getAppSyncClient() -> AWSAppSyncClient? {
        return self.appSyncClient
    }

    public func getHttpEndpoint() -> String {
        return self.relayServiceEndpoint
    }
}
