//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Utility class for generating use cases from the core level of the SDK in the consumer/API level.
class UseCaseFactory {
    
    private var repository: EntitlementsRepository
    
    init(repository: EntitlementsRepository) {
        self.repository = repository
    }

    func generateRedeemEntitlementsUseCase() -> RedeemEntitlementsUseCase {
        return RedeemEntitlementsUseCase(repository: repository)
    }

    func generateConsumeBooleanEntitlementsUseCase() -> ConsumeBooleanEntitlementsUseCase {
        return ConsumeBooleanEntitlementsUseCase(repository: repository)
    }

    func generateGetEntitlementsConsumptionUseCase() -> GetEntitlementsConsumptionUseCase {
        return GetEntitlementsConsumptionUseCase(repository: repository)
    }

    func generateGetExternalIdUseCase() -> GetExternalIdUseCase {
        return GetExternalIdUseCase(repository: repository)
    }
}
