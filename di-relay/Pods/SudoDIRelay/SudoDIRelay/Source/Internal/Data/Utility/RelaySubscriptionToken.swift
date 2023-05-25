//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSAppSync

/// Internal subscription token for handling the state of a subscription.
class RelaySubscriptionToken: SubscriptionToken, Hashable {

    // MARK: - Properties

    /// Unique identifier of the subscription. Used to cancel/remove from the manager.
    let id: String

    /// Strong reference of AWSAppSync subscription cancellable.
    private(set) var subscriptionReference: Cancellable?

    /// Reference to the manager to remove itself on cancel/deinitialization.
    weak var manager: SubscriptionManager?

    // MARK: - Lifecycle

    /// Initialize an instance of `RelaySubscriptionToken`.
    init(id: String = UUID().uuidString, cancellable: Cancellable, manager: SubscriptionManager) {
        self.id = id
        self.subscriptionReference = cancellable
        self.manager = manager
        manager.addSubscription(self)
    }

    /// Remove and cancel subscription on deinitialization.
    deinit {
        manager?.removeSubscription(withId: id)
        cancel()
    }

    // MARK: - SubscriptionToken

    func cancel() {
        subscriptionReference?.cancel()
        subscriptionReference = nil
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // MARK: - Equatable

    static func == (lhs: RelaySubscriptionToken, rhs: RelaySubscriptionToken) -> Bool {
        return lhs.id == rhs.id
    }
}
