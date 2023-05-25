//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSAppSync
import SudoLogging

/// Operation to perform a GraphQL mutation.
class MutationOperation<Mutation: GraphQLMutation>: ApiOperation {

    private unowned let appSyncClient: AWSAppSyncClient

    private let mutation: Mutation
    private let dispatchQueue: DispatchQueue
    private let optimisticUpdate: OptimisticResponseBlock?
    private let conflictResolutionBlock: MutationConflictHandler<Mutation>?
    private var resultHandler: OperationResultHandler<Mutation>?
    private let operationTimeout: Int?

    /// Initializes an operation to perform a GraphQL mutation.
    ///
    /// - Parameters:
    ///   - appSyncClient: GraphQL client to use to interact with Sudo Platform  service.
    ///   - logger: Logger to use for logging.
    ///   - mutation: The mutation to perform.
    ///   - dispatchQueue: A dispatch queue on which the result handler will be called. Defaults to the main queue.
    ///   - optimisticUpdate: An optional closure which gets executed before making the network call, should be used to update local store using the `transaction` object.
    ///   - conflictResolutionBlock: An optional closure that is called when mutation results into a conflict.
    ///   - resultHandler: An optional closure that is called when mutation results are available or when an error occurs.
    ///   - operationTimeout: An optional operation timeout in seconds.
    init(
        appSyncClient: AWSAppSyncClient,
        logger: Logger = Logger.sudoApiClientLogger,
        mutation: Mutation,
        dispatchQueue: DispatchQueue = .main,
        optimisticUpdate: OptimisticResponseBlock? = nil,
        conflictResolutionBlock: MutationConflictHandler<Mutation>? = nil,
        resultHandler: OperationResultHandler<Mutation>? = nil,
        operationTimeout: Int? = nil
    ) {
        self.appSyncClient = appSyncClient
        self.mutation = mutation
        self.dispatchQueue = dispatchQueue
        self.optimisticUpdate = optimisticUpdate
        self.conflictResolutionBlock = conflictResolutionBlock
        self.resultHandler = resultHandler
        self.operationTimeout = operationTimeout
        super.init(logger: logger)
    }

    override func done() {
        super.done()
        self.resultHandler = nil
    }

    override func execute() {
        self.graphQLOperation = self.appSyncClient.perform(
            mutation: mutation,
            queue: self.dispatchQueue,
            optimisticUpdate: self.optimisticUpdate,
            conflictResolutionBlock: self.conflictResolutionBlock,
            resultHandler: { [weak self ] (result, error) in
                guard let self = self else {
                    return
                }

                defer {
                    self.done()
                }

                if let error = error {
                    self.resultHandler?(nil, ApiOperationError.fromAppSyncClientError(error: error))
                } else {
                    if let result = result {
                        if let error = result.errors?.first {
                            self.resultHandler?(nil, ApiOperationError.fromGraphQLError(error: error))
                        } else {
                            self.resultHandler?(result, nil)
                        }
                    } else {
                        self.resultHandler?(nil, nil)
                    }
                }
            })

        if let operationTimeout = self.operationTimeout {
            self.dispatchQueue.asyncAfter(deadline: .now() + DispatchTimeInterval.seconds(operationTimeout)) { [weak self] in
                guard let self = self else {
                    return
                }
                
                self.graphQLOperation?.cancel()
                self.resultHandler?(nil, ApiOperationError.timedOut)
                self.done()
            }
        }
    }

}
