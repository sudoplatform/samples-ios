//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoEntitlements

class MockSudoEntitlementsClient: SudoEntitlementsClient {
    func reset() throws {
        throw AnyError("Not implemented")
    }

    func getEntitlementsConsumption() async throws -> EntitlementsConsumption {
        throw AnyError("Not implemented")
    }

    func getExternalId() async throws -> String {
        throw AnyError("Not implemented")
    }

    func getEntitlements() async throws -> EntitlementsSet? {
        throw AnyError("Not implemented")
    }

    func consumeBooleanEntitlements(entitlementNames: [String]) async throws {
        throw AnyError("Not implemented")
    }

    static var defaultEntitlementsSet: EntitlementsSet = EntitlementsSet(
        name: "mock-entitlements-set",
        entitlements: [
            Entitlement(name: "sudoplatform.max.sudo", value: 3)
        ],
        version: 1.0,
        created: Date(),
        updated: Date()
    )

    var redeemEntitlementsResult: Result<EntitlementsSet, Error> = .success(defaultEntitlementsSet)
    var redeemEntitlementsCalled: Bool = false
    func redeemEntitlements() async throws -> EntitlementsSet {
        redeemEntitlementsCalled = true
        switch redeemEntitlementsResult {
        case .success(let entitlementsSet):
            return entitlementsSet
        case .failure(let error):
            throw error
        }
    }
}
