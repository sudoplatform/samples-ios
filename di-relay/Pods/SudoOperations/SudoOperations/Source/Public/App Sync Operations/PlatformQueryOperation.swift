//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSAppSync
import SudoLogging

/// Queue to handle the result events from AWS.
private let dispatchQueue = DispatchQueue(label: "com.sudoplatform.query-result-handler-queue")

/// Perform an App Sync Query as an operation.
///
/// ** Generic Types **
///  - Query: GraphQLQuery subclass that is to be performed by the operation.
open class PlatformQueryOperation<Query: GraphQLQuery>: PlatformOperation {

    // MARK: - Properties

    /// Result of the operation. This will return the `Data` of the `Query`.
    open var result: Query.Data?

    /// Query performed by the operation.
    public let query: Query

    /// Cache Policy of the operation.
    public let cachePolicy: CachePolicy

    /// AppSync client instance to perform the query.
    private unowned let appSyncClient: AWSAppSyncClient

    /// Function used to perform service context specific error transformation of the mutation result for a service specific error.
    private let serviceErrorTransformations: [ServiceErrorTransformationCompletion]?

    // MARK: - Lifecycle

    /// Initialize a PlatformQueryOperation.
    public init(
        appSyncClient: AWSAppSyncClient,
        serviceErrorTransformations: [ServiceErrorTransformationCompletion]? = nil,
        query: Query,
        cachePolicy: CachePolicy,
        logger: Logger
    ) {
        self.appSyncClient = appSyncClient
        self.serviceErrorTransformations = serviceErrorTransformations
        self.query = query
        self.cachePolicy = cachePolicy
        super.init(logger: logger)
    }

    // MARK: - Overrides

    open override func execute() {
        let cachePolicy = self.cachePolicy.toAWSCachePolicy()
        appSyncClient.fetch(query: query, cachePolicy: cachePolicy, queue: dispatchQueue) { [weak self] (queryResult, error) in
            guard let self = self else {
                return
            }
            if let error = error {
                self.finishWithError(error)
                return
            }
            if let errors = queryResult?.errors, let error = errors.first {
                if let serviceErrorTransformations = self.serviceErrorTransformations,
                    let serviceError = serviceErrorTransformations.compactMap({$0(error)}).first {
                    self.finishWithError(serviceError)
                    return
                } else {
                    self.finishWithError(SudoPlatformError(error))
                    return
                }
            }

            self.result = queryResult?.data
            self.finish()
        }
    }

}
