//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSAppSync
import SudoLogging
import SudoApiClient

class DefaultEntitlementsRepository: EntitlementsRepository {

    /// GraphQL client for peforming operations against the entitlements service.
    var graphQLClient: SudoApiClient

    /// Used to log diagnostic and error information.
    var logger: Logger

    init(graphQLClient: SudoApiClient, logger: Logger = .entitlementsSDKLogger) {
        self.graphQLClient = graphQLClient
        self.logger = logger
    }

    func reset() {
    }
    
    /// Get the users current set of entitlements
    func getEntitlementsConsumption() async throws -> EntitlementsConsumption {
        let (graphQLResult, graphQLError) = try await self.graphQLClient.fetch(
                query: GetEntitlementsConsumptionQuery(),
                cachePolicy: .fetchIgnoringCacheData)

        guard let result = graphQLResult?.data else {
                guard let error = graphQLError else {
                    throw SudoEntitlementsError.fatalError("neither result nor error is non-nil after GetEntitlementsConsumption query")
                }
                throw SudoEntitlementsError.fromApiOperationError(error: error)
            }
            
        let transformer = EntitlementsTransformer()
        return transformer.transform(result.getEntitlementsConsumption)
    }

    /// Get the users external ID
    func getExternalId() async throws -> String {
        let (graphQLResult, graphQLError) = try await self.graphQLClient.fetch(
                query: GetExternalIdQuery(),
                cachePolicy: .fetchIgnoringCacheData)

        guard let result = graphQLResult?.data else {
                guard let error = graphQLError else {
                    throw SudoEntitlementsError.fatalError("neither result nor error is non-nil after GetExternalId query")
                }
                throw SudoEntitlementsError.fromApiOperationError(error: error)
            }
        
        return result.getExternalId
    }

    /// Redeem the entitlements the user is allowed
    func redeemEntitlements() async throws -> EntitlementsSet {
        let (graphQLResult, graphQLError) = try await self.graphQLClient.perform(
                mutation: RedeemEntitlementsMutation())

        guard let result = graphQLResult?.data else {
                guard let error = graphQLError else {
                    throw SudoEntitlementsError.fatalError("neither result nor error is non-nil after RedeemEntitlements mutation")
                }
                throw SudoEntitlementsError.fromApiOperationError(error: error)
            }

        let transformer = EntitlementsTransformer()
        return transformer.transform(result.redeemEntitlements)
    }

    /// Consume boolean entitlements
    func consumeBooleanEntitlements(entitlementNames: [String]) async throws {
        let mutation = ConsumeBooleanEntitlementsMutation(entitlementNames: entitlementNames)

        let (graphQLResult, graphQLError) = try await self.graphQLClient.perform(mutation: mutation)

        guard graphQLResult != nil else {
                guard let error = graphQLError else {
                    throw SudoEntitlementsError.fatalError("neither result nor error is non-nil after ConsumeBooleanEntitlements mutation")
                }
                throw SudoEntitlementsError.fromApiOperationError(error: error)
            }
    }
}
