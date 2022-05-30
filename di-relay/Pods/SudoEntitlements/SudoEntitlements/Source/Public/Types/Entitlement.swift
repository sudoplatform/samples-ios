//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

///
/// A representation of a single entitlement possessed by a user.
///
public struct Entitlement: Equatable {

    // MARK: - Properties
    
    /// Name of the entitlement.
    public var name: String

    /// Human readable description of the entitlement.
    public var description: String?

    /// The quantity of the entitlement.
    public var value: Int

    // MARK: - Lifecycle

    public init(name: String, description: String? = nil, value: Int) {
        self.name = name
        self.description = description
        self.value = value
    }
    
    public init(_ original: Entitlement) {
        self.name = original.name
        self.description = original.description
        self.value = original.value
    }
}
