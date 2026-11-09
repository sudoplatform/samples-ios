//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@preconcurrency import SudoTelephony
@preconcurrency import SudoTelephonyCommon

/// An open subscription: the token that ends it and the subscriber receiving it. The SDK holds subscribers weakly, so the
/// subscriber is kept here alongside its token for as long as the subscription is wanted.
struct ActiveSubscription {

    let token: SubscriptionToken

    let subscriber: Subscriber

    func cancel() {
        token.cancel()
    }
}

/// Passes phone number updates and connection changes to closures. One subscriber per subscription, so a connection change is
/// always about this subscription.
final class PhoneNumberUpdatesSubscriber: PhoneNumberSubscriber {

    private let onUpdate: @Sendable (PhoneNumber) -> Void

    private let onConnectionChange: @Sendable (SubscriptionConnectionState) -> Void

    init(
        onUpdate: @escaping @Sendable (PhoneNumber) -> Void,
        onConnectionChange: @escaping @Sendable (SubscriptionConnectionState) -> Void
    ) {
        self.onUpdate = onUpdate
        self.onConnectionChange = onConnectionChange
    }

    func phoneNumberUpdated(_ phoneNumber: PhoneNumber) {
        onUpdate(phoneNumber)
    }

    func connectionStatusChanged(_ state: SubscriptionConnectionState) {
        onConnectionChange(state)
    }
}

/// Passes phone message events and connection changes to closures. One subscriber per subscription, so a connection change is
/// always about this subscription.
final class PhoneMessageEventsSubscriber: PhoneMessageSubscriber {

    private let onEvent: @Sendable (PhoneMessageEvent) -> Void

    private let onConnectionChange: @Sendable (SubscriptionConnectionState) -> Void

    init(
        onEvent: @escaping @Sendable (PhoneMessageEvent) -> Void,
        onConnectionChange: @escaping @Sendable (SubscriptionConnectionState) -> Void
    ) {
        self.onEvent = onEvent
        self.onConnectionChange = onConnectionChange
    }

    func phoneMessageEvent(_ event: PhoneMessageEvent) {
        onEvent(event)
    }

    func connectionStatusChanged(_ state: SubscriptionConnectionState) {
        onConnectionChange(state)
    }
}
