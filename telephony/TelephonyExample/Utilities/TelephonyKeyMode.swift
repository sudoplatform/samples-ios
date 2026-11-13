//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// How phone numbers are keyed, chosen on the sign in screen. The choice is persisted so it survives relaunches, and applies to
/// the telephony client created when the user signs in.
enum TelephonyKeyMode {

    /// `UserDefaults` key for whether every phone number shares one key pair, i.e.
    /// `SudoTelephonyClientConfig.enforceSingletonKeyPair`.
    static let enforceSingletonKeyPairStorageKey = "com.sudoplatform.enforce-singleton-key-pair"

    /// Describes the mode for display.
    static func description(enforceSingletonKeyPair: Bool) -> String {
        enforceSingletonKeyPair ? "Single key for phone numbers" : "Key per phone number"
    }
}
