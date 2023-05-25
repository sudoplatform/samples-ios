//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoUser

/// Keeps track of the current registration mode.
struct RegistrationMode {

    /// Current registration method used to register user.
    private static var registrationMode: ChallengeType = .unknown

    /// Previous registration method. Allows different sign in methods to be chosen
    private static var previousRegistrationMode: ChallengeType = .unknown

    static func getRegistrationMode() -> ChallengeType {
        return registrationMode
    }

    static func getPreviousRegistrationMode() -> ChallengeType {
        return previousRegistrationMode
    }

    static func setRegistrationMode(_ mode: ChallengeType) {
        previousRegistrationMode = registrationMode
        registrationMode = mode
    }
}
