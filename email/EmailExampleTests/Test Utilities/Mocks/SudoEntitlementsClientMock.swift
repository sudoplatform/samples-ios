//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoEntitlements

class SudoEntitlementsClientMock: SudoEntitlementsClient {
    func reset() throws {
        // no-op
    }

    var getEntitlementsConsumptionResult: EntitlementsConsumption?
    var getEntitlementsConsumptionError = AnyError("Please add base result to `SudoEntitlementsClientMock.getEntitlementsConsumption`")
    func getEntitlementsConsumption() async throws -> EntitlementsConsumption {
        if getEntitlementsConsumptionResult != nil {
            return getEntitlementsConsumptionResult!
        }
        throw getEntitlementsConsumptionError
    }

    var getExternalIdResult: String?
    var getExternalIdError = AnyError("Please add base result to `SudoEntitlementsClientMock.getExternalId`")
    func getExternalId() async throws -> String {
        if getExternalIdResult != nil {
            return getExternalIdResult!
        }
        throw getExternalIdError
    }

    var redeemEntitlementsResult: EntitlementsSet?
    var redeemEntitlementsError = AnyError("Please add base result to `SudoEntitlementsClientMock.redeemEntitlements`")
    func redeemEntitlements() async throws -> EntitlementsSet {
        if redeemEntitlementsResult != nil {
            return redeemEntitlementsResult!
        }
        throw redeemEntitlementsError
    }

    var consumeBooleanEntitlementsFail = false
    var consumeBooleanEntitlementsError = AnyError("Please add base result to `SudoEntitlementsClientMock.consumeBooleanEntitlements`")
    func consumeBooleanEntitlements(entitlementNames: [String]) async throws {
        if consumeBooleanEntitlementsFail {
            throw consumeBooleanEntitlementsError
        }
    }

}
