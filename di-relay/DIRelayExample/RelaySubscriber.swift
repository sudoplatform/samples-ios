//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoDIRelay

/// Helper relay subscriber which wraps callbacks for the sudodirelay's subscriber interface methods.
class RelaySubscriber: SudoDIRelay.Subscriber {
    let onNotify: (_ notification: SubscriptionNotification) -> ()
    let onConnectionStatusChanged: (_ state: SubscriptionConnectionState) -> ()
    
    init(
        onNotify: @escaping (_: SubscriptionNotification) -> Void,
        onConnectionStatusChanged: @escaping (_: SubscriptionConnectionState) -> Void
    ) {
        self.onNotify = onNotify
        self.onConnectionStatusChanged = onConnectionStatusChanged
    }
    
    func notify(notification: SubscriptionNotification) {
        self.onNotify(notification)
    }

    func connectionStatusChanged(state: SubscriptionConnectionState) {
        self.onConnectionStatusChanged(state)
    }
}
