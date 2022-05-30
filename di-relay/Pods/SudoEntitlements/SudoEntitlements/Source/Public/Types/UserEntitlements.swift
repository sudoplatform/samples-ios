//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

///
/// A representation of the entitlements of a user and how they are assigned
///
public struct UserEntitlements: Equatable {
    
    // MARK: - Properties
    
    /// Version number of the user's entitlements. This is incremented every
    /// time there is a change of entitlements set or explicit entitlements
    /// for this user.
    ///
    /// For users entitled by entitlement set, the fractional part of this version
    /// specifies the version of the entitlements set itself.
    ///
    /// See also:
    ///     `Constants.entitlementsSetVersionScalingFactor`
    ///     `splitUserEntitlementsVersion`
    public var version: Double

    /// Name of the entitlement set assigned to the user or undefined if the user's
    /// entitlements are assigned directly.
    public var entitlementsSetName: String?

    /// The full set of entitlements assigned to the user.
    public var entitlements: [Entitlement]

    // MARK: - Lifecycle
    
    public init(version: Double, entitlementsSetName: String? = nil, entitlements: [Entitlement]) {
        self.version = version
        self.entitlementsSetName = entitlementsSetName
        self.entitlements = entitlements.map { e in Entitlement(e) }
    }
    
    public init(_ original: UserEntitlements) {
        self.version = original.version
        self.entitlementsSetName = original.entitlementsSetName
        self.entitlements = original.entitlements.map { e in Entitlement(e) }
    }
}
