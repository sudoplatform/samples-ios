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
public class SudoApiClientManager {

    // MARK: - Supplementary

    /// Singleton instance of `SudoApiClientManager`.
    public static let instance = SudoApiClientManager()

    /// Serial operation queue shared (defaut) by `SudoApiClient` instances for GraphQL mutations and queries with unsatisfied
    /// preconditions.
    public static let serialOperationQueue = ApiOperationQueue(maxConcurrentOperationCount: 1, maxQueueDepth: 10)

    /// Concurrent operation queue shaed (default) by `SudoApiClient` instances for GraphQL queries with all preconditions met.
    public static let concurrentOperationQueue = ApiOperationQueue(maxConcurrentOperationCount: 3, maxQueueDepth: 10)

    private struct Config {

        // Configuration namespace.
        struct Namespace {
            static let apiService = "apiService"
        }

    }

    // MARK: - Properties

    private var client: SudoApiClient?

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
    public func getClient(sudoUserClient: SudoUserClient) throws -> SudoApiClient {
        try self.queue.sync {
            if let client = self.client {
                return client
            } else {
                let client = try SudoApiClient(configProvider: self.configProvider, sudoUserClient: sudoUserClient)
                self.client = client
                return client
            }
        }
    }

    /// Clears any cached data including queries, subscriptions and pending mutations data.
    public func reset() throws {
        try self.queue.sync {
            try self.client?.clearCaches()
        }
    }

}
