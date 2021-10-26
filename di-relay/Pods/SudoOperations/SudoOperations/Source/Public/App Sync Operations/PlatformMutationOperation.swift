//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSAppSync
import SudoLogging

/// Queue to handle the result events from AWS.
private let dispatchQueue = DispatchQueue(label: "com.sudoplatform.mutation-result-handler-queue")

/// Typealias for a closure used for performing any optimistic cleanup on a mutation.
public typealias OptimisticCleanupBlock = (ApolloStore.ReadWriteTransaction) throws -> Void

/// Typealias for a closure used for transforming a GraphQLError into a suitable consumer Error.
public typealias ServiceErrorTransformationCompletion = (GraphQLError) -> Error?

/// Perform an App Sync Mutation as an operation.
///
/// ** Generic Types **
///  - Mutation: GraphQLMutation subclass that is to be performed by the operation.
open class PlatformMutationOperation<Mutation: GraphQLMutation>: PlatformOperation {

    // MARK: - Properties

    /// Result of the operation. This will return the `Data` of the `Mutation`.
    open var result: Mutation.Data?

    /// Mutation performed by the operation.
    public let mutation: Mutation

    /// AppSync client instance to perform the mutation, as well as optimistic cleanup.
    private unowned let appSyncClient: AWSAppSyncClient

    /// Function used to perform service context specific error transformation of the mutation result for a service specific error.
    private let serviceErrorTransformations: [ServiceErrorTransformationCompletion]?

    /// Optimistic update block. Used to define the behavior of performing any logic before a network call is made for the mutation.
    /// This is useful for performing a write to the database to allow for offline data.
    private let optimisticUpdate: OptimisticResponseBlock?

    /// Optimistic cleanup block. Used to define the behavior of performing any logic after a successful result has been returned.
    /// This is useful (and recommended if using an optimistic update) to cleanup any previous optimstic data written.
    private let optimisticCleanup: OptimisticCleanupBlock?

    // MARK: - Lifecycle

    /// Initialize a Platform Mutation operation.
    public init(
        appSyncClient: AWSAppSyncClient,
        serviceErrorTransformations: [ServiceErrorTransformationCompletion]? = nil,
        mutation: Mutation,
        optimisticUpdate: OptimisticResponseBlock? = nil,
        optimisticCleanup: OptimisticCleanupBlock? = nil,
        logger: Logger
    ) {
        self.appSyncClient = appSyncClient
        self.serviceErrorTransformations = serviceErrorTransformations
        self.mutation = mutation
        self.optimisticUpdate = optimisticUpdate
        self.optimisticCleanup = optimisticCleanup
        super.init(logger: logger)
    }

    // MARK: - Overrides

    open override func execute() {
        _ = appSyncClient.perform(
            mutation: mutation,
            queue: dispatchQueue,
            optimisticUpdate: optimisticUpdate,
            conflictResolutionBlock: nil,
            resultHandler: { [weak self] (mutationResult, error) in
                guard let self = self else {
                    return
                }
                if let error = error {
                    self.finishWithError(error)
                    return
                }
                if let errors = mutationResult?.errors, let error = errors.first {
                    if let serviceErrorTransformations = self.serviceErrorTransformations,
                        let serviceError = serviceErrorTransformations.compactMap({$0(error)}).first {
                        self.finishWithError(serviceError)
                        return
                    } else {
                        self.finishWithError(SudoPlatformError(error))
                        return
                    }
                }
                if let optimisticCleanup = self.optimisticCleanup {
                    _ = self.appSyncClient.store?.withinReadWriteTransaction(optimisticCleanup)
                }
                self.result = mutationResult?.data
                self.finish()
            }
        )
    }
}
