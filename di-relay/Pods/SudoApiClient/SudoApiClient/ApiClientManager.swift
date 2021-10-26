//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSAppSync
import SudoUser
import SudoLogging
import SudoConfigManager

/// Manages a singleton GraphQL client instance shared by multiple platform service clients.
public class ApiClientManager {

    // MARK: - Supplementary

    public static let instance = ApiClientManager()

    /// Callback for determing cache key for object in AppSync.
    static var cacheKeyForObject: AWSAppSync.CacheKeyForObject = {
        guard
            let typename = $0[Config.CacheKey.typename],
            let id = $0[Config.CacheKey.id]
        else {
            return nil
        }
        return "\(typename)\(id)"
    }

    private struct Config {

        // Configuration namespace.
        struct Namespace {
            static let apiService = "apiService"
        }

        struct CacheKey {
            static let id = "id"
            static let typename = "__typename"
        }

    }

    // MARK: - Properties

    private var client: AWSAppSyncClient?

    private let logger: Logger

    private let configProvider: SudoApiClientConfigProvider

    private let queue = DispatchQueue(label: "com.sudoplatform.apiclient")

    /// Initializes `ApiClientManager`.
    ///
    /// - Parameter logger: Logger used for logging.
    private init?(logger: Logger? = nil) {
        self.logger = logger ?? Logger.sudoApiClientLogger

        guard let config = DefaultSudoConfigManager()?.getConfigSet(namespace: Config.Namespace.apiService) else {
            self.logger.error("Configuration set for \"\(Config.Namespace.apiService)\" not found.")
            return nil
        }

        self.logger.info("Initializing SudoApiClient with config: \(config)")

        guard let configProvider = SudoApiClientConfigProvider(config: config) else {
            self.logger.error("Invalid config: \"\(config)\".")
            return nil
        }

        self.configProvider = configProvider
    }

    /// Returns the singleton GraphQL API client.
    ///
    /// - Parameter sudoUserClient: `SudoUserClient` instance used for authenticating the GraphQL API client.
    public func getClient(sudoUserClient: SudoUserClient) throws -> AWSAppSyncClient {
        try self.queue.sync {
            if let client = self.client {
                return client
            } else {
                let cacheConfiguration = try AWSAppSyncCacheConfiguration()
                let appSyncConfig = try AWSAppSyncClientConfiguration(appSyncServiceConfig: self.configProvider,
                                                                      userPoolsAuthProvider: GraphQLAuthProvider(client: sudoUserClient),
                                                                      urlSessionConfiguration: URLSessionConfiguration.default,
                                                                      cacheConfiguration: cacheConfiguration,
                                                                      connectionStateChangeHandler: nil,
                                                                      s3ObjectManager: nil,
                                                                      presignedURLClient: nil,
                                                                      retryStrategy: .aggressive)
                let client = try AWSAppSyncClient(appSyncConfig: appSyncConfig)
                client.apolloClient?.cacheKeyForObject = ApiClientManager.cacheKeyForObject
                self.client = client

                return client
            }
        }
    }

    /// Clears any cached data including queries, subscriptions and pending mutations data.
    public func reset() throws {
        try self.queue.sync {
            try client?.clearCaches()
        }
    }

}
