//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSAppSync
import SudoLogging
import SudoUser

/// Operation to perform a GraphQL query.
class QueryOperation<Query: GraphQLQuery>: ApiOperation {

    private unowned let appSyncClient: AWSAppSyncClient

    private let query: Query
    private let dispatchQueue: DispatchQueue
    private let cachePolicy: CachePolicy
    private let resultHandler: OperationResultHandler<Query>?

    /// Initializes an operation to perform a GraphQL query.
    ///
    /// - Parameters:
    ///   - appSyncClient: GraphQL client to use to interact with Sudo Platform  service.
    ///   - logger: Logger to use for logging.
    ///   - query: The query to fetch.
    ///   - dispatchQueue: A dispatch queue on which the result handler will be called. Defaults to the main queue.
    ///   - cachePolicy: A cache policy that specifies when results should be fetched from the server and when data should be loaded from the local cache.
    ///   - resultHandler: An optional closure that is called when query results are available or when an error occurs.
    init(
        appSyncClient: AWSAppSyncClient,
        logger: Logger = Logger.sudoApiClientLogger,
        query: Query,
        dispatchQueue: DispatchQueue = .main,
        cachePolicy: CachePolicy = .returnCacheDataElseFetch,
        resultHandler: OperationResultHandler<Query>? = nil
    ) {
        self.appSyncClient = appSyncClient
        self.query = query
        self.cachePolicy = cachePolicy
        self.dispatchQueue = dispatchQueue
        self.resultHandler = resultHandler
        super.init(logger: logger)
    }

    override func execute() {
        self.appSyncClient.fetch(
            query: self.query,
            cachePolicy: self.cachePolicy,
            queue: self.dispatchQueue,
            resultHandler: { (result, error) in
            if let error = error {
                self.resultHandler?(nil, ApiOperationError.fromAppSyncClientError(error: error))
                self.done()
            } else {
                if let result = result {
                    if let error = result.errors?.first {
                        self.resultHandler?(nil, ApiOperationError.fromGraphQLError(error: error))
                        self.done()
                    } else {
                        self.resultHandler?(result, nil)
                        // Don't mark the operation as done if cache policy is `returnCacheDataAndFetch`
                        // since it causes the result handler to be called twice: once for cached data
                        // and second time for remote data.
                        if !(result.source == .cache && self.cachePolicy == .returnCacheDataAndFetch) {
                            self.done()
                        }
                    }
                } else {
                    self.resultHandler?(nil, nil)
                    self.done()
                }
            }
        })
    }

}
