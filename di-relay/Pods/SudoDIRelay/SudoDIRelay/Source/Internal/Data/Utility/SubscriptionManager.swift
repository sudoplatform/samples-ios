//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Utility class for mananging subscription in the SDK to the service.
protocol SubscriptionManager: AnyObject {

    // MARK: - Methods

    /// Add a subscription to the manager.
    /// - Parameter subscription: The subscription token associated with the subscription.
    func addSubscription(_ subscription: RelaySubscriptionToken)

    /// Remove a subscription which matches `id`.
    /// - Parameter id: Identifier of the subscription to remove.
    func removeSubscription(withId id: String)

    /// Remove all subscriptions from the manager.
    func removeAllSubscriptions()
}

/// Weak instance of a `WeakRelaySubscriptionToken`.
class WeakRelaySubscriptionToken: Hashable {

    // MARK: - Properties

    /// Internal weak reference to the token.
    weak var value: RelaySubscriptionToken?

    /// Reference identifier.
    let id: String

    // MARK: - Lifecycle

    /// Initialize a Weak `RelaySubscriptionToken`.
    /// - Parameter value: The subscription token associated with the subscription.
    init(_ value: RelaySubscriptionToken) {
        self.id = value.id
        self.value = value
    }

    // MARK: - Methods

    /// If possible, cancels the internal weak reference. If the reference has already been lost, nothing will happen.
    func cancel() {
        value?.cancel()
    }

    // MARK: - Conformance: Equatable

    static func == (lhs: WeakRelaySubscriptionToken, rhs: WeakRelaySubscriptionToken) -> Bool {
        return lhs.value == rhs.value
    }

    // MARK: - Conformance: Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

}

/// Concrete implementation of the `SubscriptionManager`.
class DefaultSubscriptionManager: SubscriptionManager {

    // MARK: - Properties

    /// Queue to handle the mutation of `subscriptions` to avoid race conditions.
    let subscriptionQueue = DispatchQueue(label: "com.sudoplatform.DefaultSubscriptionManager")

    /// Set of unique subscriptions that are managed by this class.
    private(set) var subscriptions = Set<WeakRelaySubscriptionToken>()

    // MARK: - SubscriptionManager

    func addSubscription(_ subscription: RelaySubscriptionToken) {
        let weakSubscription = WeakRelaySubscriptionToken(subscription)
        subscriptionQueue.sync {
            _ = subscriptions.insert(weakSubscription)
        }
    }

    func removeSubscription(withId id: String) {
        subscriptionQueue.sync {
            guard let index = subscriptions.firstIndex(where: { $0.id == id }) else {
                return
            }
            let subscription = subscriptions.remove(at: index)
            subscription.cancel()
        }
    }

    func removeAllSubscriptions() {
        subscriptionQueue.sync {
            for subscription in subscriptions {
                subscription.cancel()
            }
            subscriptions.removeAll()
        }
    }
}
