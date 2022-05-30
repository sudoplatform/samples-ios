//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoUser
import AWSAppSync
import SudoLogging

/// Wrapper class for AppSyncClient to provide rate control and common error handling.
public class SudoApiClient {

    private struct Config {

        struct CacheKey {
            static let id = "id"
            static let typename = "__typename"
        }

    }

    unowned private let sudoUserClient: SudoUserClient?

    private let appSyncClient: AWSAppSyncClient

    private let logger: Logger

    /// Serial operation queue used for GraphQL mutations and queries with unsatisfied preconditions.
    public let serialQueue: ApiOperationQueue

    /// Concurrent operation queue used for GraphQL queries with all precondtions met.
    public let concurrentQueue: ApiOperationQueue

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

    /// Initializes a `SudoApiClient` instance.
    ///
    /// - Parameters:
    ///   - configProvider: `AWSAppSyncServiceConfigProvider` to provide the client configuration.
    ///   - sudoUserClient: `SudoUserClient` instance to provide the authentication token.
    ///   - logger: `Logger` instance to use for logging.
    ///   - serialQueue: Serial queue to use for mutations and queries with unmet preconditions.
    ///   - concurrentQueue: Concurrent queue to use for queries with preconditions met..
    ///   - appSyncClient: `AWSAppSyncClient` instance to use for unit testing.
    public init(
        configProvider: AWSAppSyncServiceConfigProvider,
        sudoUserClient: SudoUserClient,
        logger: Logger = Logger.sudoApiClientLogger,
        serialQueue: ApiOperationQueue = SudoApiClientManager.serialOperationQueue,
        concurrentQueue: ApiOperationQueue = SudoApiClientManager.concurrentOperationQueue,
        appSyncClient: AWSAppSyncClient? = nil
    ) throws {
        self.sudoUserClient = sudoUserClient
        self.logger = logger
        self.serialQueue = serialQueue
        self.concurrentQueue = concurrentQueue
        if let appSyncClient = appSyncClient {
            self.appSyncClient = appSyncClient
        } else {
            let cacheConfiguration = try AWSAppSyncCacheConfiguration()
            let appSyncConfig = try AWSAppSyncClientConfiguration(
                appSyncServiceConfig: configProvider,
                userPoolsAuthProvider: GraphQLAuthProvider(client: sudoUserClient),
                urlSessionConfiguration: URLSessionConfiguration.default,
                cacheConfiguration: cacheConfiguration,
                connectionStateChangeHandler: nil,
                s3ObjectManager: nil,
                presignedURLClient: nil,
                retryStrategy: .aggressive
            )
            self.appSyncClient = try AWSAppSyncClient(appSyncConfig: appSyncConfig)
            self.appSyncClient.apolloClient?.cacheKeyForObject = SudoApiClient.cacheKeyForObject
        }
    }

    /// Initializes a `SudoApiClient` instance.
    ///
    /// - Parameters:
    ///   - appSyncClient: `AWSAppSyncClient` instance to use..
    ///   - logger: `Logger` instance to use for logging.
    ///   - serialQueue: Serial queue to use for mutations and queries with unmet preconditions.
    ///   - concurrentQueue: Concurrent queue to use for queries with preconditions met..
    public init(
        appSyncClient: AWSAppSyncClient,
        logger: Logger = Logger.sudoApiClientLogger,
        serialQueue: ApiOperationQueue = SudoApiClientManager.serialOperationQueue,
        concurrentQueue: ApiOperationQueue = SudoApiClientManager.concurrentOperationQueue
    ) throws {
        self.appSyncClient = appSyncClient
        self.sudoUserClient = nil
        self.logger = logger
        self.serialQueue = serialQueue
        self.concurrentQueue = concurrentQueue
    }

    /// Performs a mutation by sending it to the server. Internally, these mutations are added to a queue and performed
    /// serially, in first-in, first-out order. Clients can inspect the size of the queue with the `queuedMutationCount`
    /// property.
    ///
    /// - Parameters:
    ///   - mutation: The mutation to perform.
    ///   - queue: A dispatch queue on which the result handler will be called. Defaults to the main queue.
    ///   - optimisticUpdate: An optional closure which gets executed before making the network call, should be used to update local store using the `transaction` object.
    ///   - conflictResolutionBlock: An optional closure that is called when mutation results into a conflict.
    ///
    /// - Returns: The result of the mutation or error.
    public func perform<Mutation: GraphQLMutation>(
        mutation: Mutation,
        queue: DispatchQueue = .main,
        optimisticUpdate: OptimisticResponseBlock? = nil,
        conflictResolutionBlock: MutationConflictHandler<Mutation>? = nil
    ) async throws -> (result: GraphQLResult<Mutation.Data>?, error: Error?) {
        if let sudoUserClient = self.sudoUserClient {
            guard try await sudoUserClient.isSignedIn() else {
                throw ApiOperationError.notSignedIn
            }
        }

        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<(result: GraphQLResult<Mutation.Data>?, error: Error?), Error>) in
            do {
                let op = MutationOperation(
                    appSyncClient: self.appSyncClient,
                    logger: self.logger,
                    mutation: mutation,
                    dispatchQueue: queue,
                    optimisticUpdate: optimisticUpdate,
                    conflictResolutionBlock: conflictResolutionBlock,
                    resultHandler: { (result, error) in
                        continuation.resume(returning: (result, error))
                    })
                try self.serialQueue.addOperation(op)
            } catch {
                continuation.resume(throwing: error)
            }
        })
    }

    /// Fetches a query from the server or from the local cache, depending on the current contents of the cache and the
    /// specified cache policy.
    ///
    /// - Parameters:
    ///   - query: The query to fetch.
    ///   - cachePolicy: A cache policy that specifies when results should be fetched from the server and when data should be loaded from the local cache.
    ///   - queue: A dispatch queue on which the result handler will be called. Defaults to the main queue.
    ///   - resultHandler: An optional closure that is called when query results are available or when an error occurs.
    ///   - error: An error that indicates why the fetch failed, or `nil` if the fetch was succesful.
    ///
    /// - Returns: The result of the query or error.
    public func fetch<Query: GraphQLQuery>(
        query: Query,
        cachePolicy: CachePolicy = .returnCacheDataElseFetch,
        queue: DispatchQueue = DispatchQueue.main
    ) async throws -> (result: GraphQLResult<Query.Data>?, error: Error?) {
        var opQueue = self.serialQueue

        if let sudoUserClient = self.sudoUserClient {
            guard try await sudoUserClient.isSignedIn() else {
                throw ApiOperationError.notSignedIn
            }

            // If the ID token is at least good for 2 mins then allow concurrent execution of
            // queries since no auto refreshing of tokens will occur 1 min before the expiry.
            if let expiry = try sudoUserClient.getTokenExpiry(),
               expiry > Date(timeIntervalSinceNow: 120) {
                opQueue = self.concurrentQueue
            }
        }

        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<(result: GraphQLResult<Query.Data>?, error: Error?), Error>) in
            do {
                let op = QueryOperation(
                    appSyncClient: self.appSyncClient,
                    logger: self.logger,
                    query: query,
                    dispatchQueue: queue,
                    cachePolicy: cachePolicy,
                    resultHandler: { (result, error) in
                        continuation.resume(returning: (result, error))
                    })
                try opQueue.addOperation(op)
            } catch {
                continuation.resume(throwing: error)
            }
        })
    }

    /// Subscribes to a GraphQL subscription.
    ///
    /// - Parameters:
    ///   - subscription: GraphQL subscription to subscribe to.
    ///   - queue: A dispatch queue on which the result handler will be called. Defaults to the main queue.
    ///   - statusChangeHandler: A closure that is called when the subscription status changes.
    ///   - resultHandler: A closure that is called when subscription results are available or when an error occurs.
    /// - Returns: A `AWSAppSyncSubscriptionWatcher` responsible for watching the subscription, and calling
    ///     the result handler with a new result whenever any of the data is published. It also normalizes the cache before giving the callback to customer.
    public func subscribe<Subscription: GraphQLSubscription>(
        subscription: Subscription,
        queue: DispatchQueue = DispatchQueue.main,
        statusChangeHandler: SubscriptionStatusChangeHandler? = nil,
        resultHandler: @escaping SubscriptionResultHandler<Subscription>
    ) async throws -> AWSAppSyncSubscriptionWatcher<Subscription>? {
        if let sudoUserClient = self.sudoUserClient {
            guard try await sudoUserClient.isSignedIn() else {
                throw ApiOperationError.notSignedIn
            }
        }

        return try self.appSyncClient.subscribe(subscription: subscription, queue: queue, statusChangeHandler: statusChangeHandler, resultHandler: resultHandler)
    }

    /// Clears AppSyncClient cache.
    ///
    /// - Parameter options: Options to determine whether or not query, mutation or subscription cache should be cleared.
    public func clearCaches(options: ClearCacheOptions = ClearCacheOptions(clearQueries: true, clearMutations: true, clearSubscriptions: true)) throws {
        try self.appSyncClient.clearCaches(options: options)
    }

    /// Returns the underlying `AWSAppSyncClient` instance.
    ///
    /// - Returns:`AWSAppSyncClient` instance.
    public func getAppSyncClient() -> AWSAppSyncClient {
        return self.appSyncClient
    }

}
