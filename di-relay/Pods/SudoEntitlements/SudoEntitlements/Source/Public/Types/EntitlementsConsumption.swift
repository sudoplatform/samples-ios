//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

///
/// Entitlements consumption information for the user
///
public struct EntitlementsConsumption: Equatable {
    
    // MARK: - Properties
    
    /// The user's current assigned entitlements
    public var entitlements: UserEntitlements

    /// Consumption information for consumed entitlements.
    ///
    /// Absence of an element in this array for a particular entitlement
    /// indicates that the entitlement has not been consumed at all.
    ///
    /// For sub-user level resource consumption, absence of an element in this
    /// array for a particular potential consumer indicates that the entitlement
    /// has not be consumed at all by that consumer.
    public var consumption: [EntitlementConsumption]

    // MARK: - Lifecycle
    
    public init(entitlements: UserEntitlements, consumption: [EntitlementConsumption]) {
        self.entitlements = UserEntitlements(entitlements)
        self.consumption = consumption.map { consumption in EntitlementConsumption(consumption) }
    }
}
