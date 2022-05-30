//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

///
/// A representation of a set of entitlements possessed by a user.
///
public struct EntitlementsSet: Equatable {
    
    // MARK: - Properties
    
    /// Name of the set of entitlements. This will often be a few words separated by dots like an internet domain.
    public var name: String

    /// Human readable description of the set of entitlements.
    public var description: String?

    /// The set of entitlement values.
    public var entitlements: [Entitlement]

    /// Version number of the user's entitlements. This is incremented every
    /// time there is a change of entitlements set or explicit entitlements
    /// for this user.
    ///
    /// For users entitled by entitlement set, the fractional part of this version
    /// specifies the version of the entitlements set itself.
    public var version: Double

    /// When the set of entitlements was created.
    public var created: Date

    /// When the set of entitlements was last updated.
    public var updated: Date

    // MARK: - Lifecycle
    
    public init(name: String, description: String? = nil, entitlements: [Entitlement], version: Double, created: Date, updated: Date) {
        self.name = name
        self.description = description
        self.entitlements = entitlements.map { e in Entitlement(e) }
        self.version = version
        self.created = created
        self.updated = updated
    }
    
    public init(_ original: EntitlementsSet) {
        self.name = original.name
        self.description = original.description
        self.entitlements = original.entitlements.map { e in Entitlement(e) }
        self.version = original.version
        self.created = original.created
        self.updated = original.updated
    }
}
