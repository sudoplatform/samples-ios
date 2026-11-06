//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// The ways a user can authenticate with the Sudo Platform. Raw values are persisted so the choice survives relaunches.
enum AuthenticationStrategy: String, CaseIterable, CustomStringConvertible, Identifiable {
    /// Uses the TEST registration key from the `config` directory.
    case test
    /// Uses Federated Single Sign-On.
    case fsso

    /// `UserDefaults` key the selected strategy is stored under.
    static let storageKey = "com.sudoplatform.registration-strategy"

    // MARK: - Conformance: Identifiable

    var id: Self { self }

    // MARK: - Conformance: CustomStringConvertible

    var description: String {
        switch self {
        case .test:
            return "Test Keys"
        case .fsso:
            return "Federated Sign In"
        }
    }
}
