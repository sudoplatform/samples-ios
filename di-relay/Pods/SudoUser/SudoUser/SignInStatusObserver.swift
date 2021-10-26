//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// List of possible values for sign in status.
/// - signingIn: sign in or token refresh is currently in progress.
/// - signedIn: sign in completed
/// - notSignedIn: sign in failed due to an error.
public enum SignInStatus {
    case signingIn
    case signedIn
    case notSignedIn(cause: Error)
}

/// Protocol for sign in status observer. If you wish to observe the the changes to the progress
/// of sign in or refresh token operation then you must implement this protocol.
public protocol SignInStatusObserver {

    /// Notifies the changes to the sign in or refresh token operation.
    ///
    /// - Parameter status: new sign in status.
    func signInStatusChanged(status: SignInStatus)

}
