//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSAppSync
import SudoOperations
import SudoLogging

class OperationFactory {

    // MARK: - Methods

    func generateQueryOperation<Query: GraphQLQuery>(
        query: Query,
        appSyncClient: AWSAppSyncClient,
        cachePolicy: CachePolicy = CachePolicy.remoteOnly,
        logger: Logger
    ) -> PlatformQueryOperation<Query> {
        return PlatformQueryOperation(
            appSyncClient: appSyncClient,
            serviceErrorTransformations: [SudoDIRelayError.init(graphQLError:)],
            query: query,
            cachePolicy: cachePolicy.toSudoOperationsCachePolicy(),
            logger: logger)
    }

    func generateMutationOperation<Mutation: GraphQLMutation>(
        mutation: Mutation,
        optimisticUpdate: OptimisticResponseBlock? = nil,
        optimisticCleanup: OptimisticCleanupBlock? = nil,
        appSyncClient: AWSAppSyncClient,
        logger: Logger
    ) -> PlatformMutationOperation<Mutation> {
        return PlatformMutationOperation(
            appSyncClient: appSyncClient,
            serviceErrorTransformations: [SudoDIRelayError.init(graphQLError:)],
            mutation: mutation,
            optimisticUpdate: optimisticUpdate,
            optimisticCleanup: optimisticCleanup,
            logger: logger)
    }

}
