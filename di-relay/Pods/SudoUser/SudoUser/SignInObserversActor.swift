//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Actor for managing sign in observers.
actor SignInObserversActor {

    /// List of sign in status observers.
    private var signInStatusObservers: [String: SignInStatusObserver] = [:]

    /// Registers an observer for sign in status changes.
    ///
    /// - Parameters:
    ///     - id: unique ID to associate with the observer.
    ///     - observer: sign in status observer to register.
    func registerSignInStatusObserver(id: String, observer: SignInStatusObserver) {
        self.signInStatusObservers[id] = observer
    }

    /// Deregisters an existing sign in status observer.
    ///
    /// - Parameter id: ID of the observer to deregister.
    func deregisterSignInStatusObserver(id: String) {
        _ = self.signInStatusObservers.removeValue(forKey: id)
    }

    /// Notify observers of sign in status change.
    ///
    /// - Parameter status: New sign in status.
    func notifyObservers(status: SignInStatus) {
        self.signInStatusObservers.values.forEach { (observer) in
            observer.signInStatusChanged(status: status)
        }
    }

}
