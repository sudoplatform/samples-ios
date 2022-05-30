//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Represents an entitlement related to using Sudo service APIs. Currently only entitlement that's used
/// in Sudo service is "sudoplatform.sudo.max" to represent the maximum number of Sudos each user
/// is allowed to provision.
public struct Entitlement {

    /// Entitlement name, e.g "sudoplatform.sudo.max" for maximum number of Sudos.
    public let name: String

    /// Entitlement value.
    public let value: Int

    /// Default memberwise initializer.
    ///
    /// - Parameters:
    ///   - name: Entitlement name.
    ///   - value: Entitlement value.
    public init(name: String, value: Int) {
        self.name = name
        self.value = value
    }

}
