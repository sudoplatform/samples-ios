//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

///
/// A representation of the sub-user level consuming resource of an entitlement
///
public struct EntitlementConsumer: Equatable {
    
    // MARK: - Properties
    
    /// ID of the resource consuming an entitlement
    public var id: String

    /// Issuer of the ID of the consumer. For example `sudoplatform.sudoservice` for a Sudo ID
    public var issuer: String

    // MARK: - Lifecycle
    
    public init(id: String, issuer: String) {
        self.id = id
        self.issuer = issuer
    }
    
    public init(_ original: EntitlementConsumer) {
        self.id = original.id
        self.issuer = original.issuer
    }
}
