//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol EntitlementsRepository: AnyObject, Resetable {

    /// Get the users current set of entitlements and their consumption
    func getEntitlementsConsumption() async throws -> EntitlementsConsumption

    /// Get the users external ID
    func getExternalId() async throws -> String

    /// Redeem the entitlements the user is allowed
    func redeemEntitlements() async throws -> EntitlementsSet

    /// Record boolean entitlements as consumed
    func consumeBooleanEntitlements(entitlementNames: [String]) async throws
}
