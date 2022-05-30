//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSAppSync
import SudoLogging
import SudoApiClient

/// Typealias for a closure used for performing any optimistic cleanup on a mutation.
typealias OptimisticCleanupBlock = (ApolloStore.ReadWriteTransaction) throws -> Void

/// Typealias for a closure used for transforming a GraphQLError into a suitable consumer Error.
typealias ServiceErrorTransformationCompletion = (GraphQLError) -> Error?

struct GraphQLHelper {

    /// Queue to handle the result events from AWS.
    private static let dispatchQueue = DispatchQueue(label: "com.sudoplatform.mutation-result-handler-queue"
    )

    static func performMutation<Mutation: GraphQLMutation>(
        graphQLClient: SudoApiClient,
        serviceErrorTransformations: [ServiceErrorTransformationCompletion]? = nil,
        mutation: Mutation,
        optimisticUpdate: OptimisticResponseBlock? = nil,
        optimisticCleanup: OptimisticCleanupBlock? = nil,
        logger: Logger
    ) async throws -> Mutation.Data {
        do {
            let (result, error) = try await graphQLClient.perform(
                mutation: mutation,
                queue: dispatchQueue,
                optimisticUpdate: optimisticUpdate)

            if let error = error {
                switch error {
                case ApiOperationError.graphQLError(let cause):
                    if
                        let serviceErrorTransformations = serviceErrorTransformations,
                        let serviceError = serviceErrorTransformations.compactMap({$0(cause)}).first {
                        throw serviceError
                    } else {
                        throw SudoDIRelayError(graphQLError: cause)
                    }
                default:
                    throw SudoDIRelayError.fromApiOperationError(error: error)
                }
            }

            if let optimisticCleanup = optimisticCleanup {
                _ = graphQLClient.getAppSyncClient().store?.withinReadWriteTransaction(optimisticCleanup)
            }
            guard let data = result?.data else {
                throw SudoDIRelayError.internalError("No data from API call")
            }
            return data
        } catch let error as ApiOperationError {
            throw SudoDIRelayError.fromApiOperationError(error: error)
        }
    }

    static func performQuery<Query: GraphQLQuery>(
        graphQLClient: SudoApiClient,
        query: Query,
        serviceErrorTransformations: [ServiceErrorTransformationCompletion]? = nil,
        cachePolicy: CachePolicy,
        logger: Logger
    ) async throws -> Query.Data? {
        let cachePolicy = self.toAWSCachePolicy(cachePolicy)
        do {
            let (result, error) = try await graphQLClient.fetch(
                query: query,
                cachePolicy: cachePolicy,
                queue: dispatchQueue)
            if let error = error {
                switch error {
                case ApiOperationError.graphQLError(let cause):
                    if let serviceErrorTransformations = serviceErrorTransformations,
                       let serviceError = serviceErrorTransformations.compactMap({$0(cause)}).first {
                        throw serviceError
                    } else {
                        throw SudoDIRelayError(graphQLError: cause)
                    }
                default:
                    throw SudoDIRelayError.fromApiOperationError(error: error)
                }
            }
            return result?.data
        } catch let error as ApiOperationError {
            throw SudoDIRelayError.fromApiOperationError(error: error)
        }
    }

    private static func toAWSCachePolicy(_ cachePolicy: CachePolicy) -> AWSAppSync.CachePolicy {
        switch cachePolicy {
        case .cacheOnly:
            return AWSAppSync.CachePolicy.returnCacheDataDontFetch
        case .remoteOnly:
            return AWSAppSync.CachePolicy.fetchIgnoringCacheData
        }
    }
}
