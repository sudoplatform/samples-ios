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

    /// Provides an AWS API key.
    private let awsApiKeyProvider: APIKeyAuthProvider

    // MARK: - Lifecycle

    /// Intializes a new `DefaultAppSyncClientHelper` instance. It uses configuration parameters defined in
    /// `sudoplatformconfig.json` file located in the app bundle.
    public init() throws {
        /// Programatically get SDK config via SudoConfigManager
        guard
            let configManager = DefaultSudoConfigManager(),
            let relayServiceConfig = configManager.getConfigSet(namespace: Namespace.relayService) else {
            throw SudoDIRelayError.invalidConfig
        }

        /// GraphQL url
        guard
            let urlAsString = relayServiceConfig[RelayService.apiUrl] as? String,
            let url = URL(string: urlAsString) else {
            throw SudoDIRelayError.invalidConfig
        }

        /// API key and auth provider
        guard
            let apiKey = relayServiceConfig[RelayService.apiKey] as? String else {
            throw SudoDIRelayError.invalidConfig
        }
        self.awsApiKeyProvider = APIKeyAuthProvider(apiKey)

        /// AppSync client
        let appSyncConfig = try AWSAppSyncClientConfiguration(
            url: url,
            serviceRegion: AWSRegionType.USEast1,
            apiKeyAuthProvider: self.awsApiKeyProvider
        )
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

// MARK: - APIKeyAuthProvider

private class APIKeyAuthProvider: AWSAPIKeyAuthProvider {

    // MARK: - Properties

    let apiKey: String

    // MARK: - Lifecycle

    public init(_ apiKey: String) {
        self.apiKey = apiKey
    }

    func getAPIKey() -> String {
        return apiKey
    }
}
