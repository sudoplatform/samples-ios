//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSAppSync
import SudoLogging

/// Perform a mutation of the entitlements service to redeem the users set of entitlements
class RedeemEntitlementsUseCase {

    let repository: EntitlementsRepository

    init(repository: EntitlementsRepository) {
        self.repository = repository
    }

    func execute() async throws -> EntitlementsSet {
        return try await repository.redeemEntitlements()
    }
}
