//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSAppSync

/// Manages subscriptions for a specific GraphQL subscription.
class SubscriptionManager<T: GraphQLSubscription> {

    /// Subscribers.
    var subscribers: [String: SudoSubscriber] = [:]

    /// AppSync subscription watcher associated with this subscription.
    var watcher: Cancellable?

    /// Queue to use for serialized access to subscribers list.
    private let queue = DispatchQueue(label: "com.sudoplatform.sudoprofiles.subscription.manager")

    /// Adds or replaces a subscriber with the specified ID.
    ///
    /// - Parameters:
    ///   - id: Subscriber ID.
    ///   - subscriber: Subscriber.
    func replaceSubscriber(id: String, subscriber: SudoSubscriber) {
        self.queue.sync {
            self.subscribers[id] = subscriber
        }
    }

    /// Removes the subscriber with the specified ID.
    ///
    /// - Parameter id: Subscriber ID.
    func removeSubscriber(id: String) {
        self.queue.sync {
            _ = self.subscribers.removeValue(forKey: id)

            if self.subscribers.isEmpty {
                self.watcher?.cancel()
                self.watcher = nil
            }
        }
    }

    /// Removes all subscribers.
    func removeAllSubscribers() {
        self.queue.sync {
            self.subscribers.removeAll()
            self.watcher?.cancel()
            self.watcher = nil
        }
    }

    /// Notifies  subscribers of a new, updated or deleted Sudo.
    ///
    /// - Parameter changeType: Change type. Please refer to `SudoChangeType`.
    /// - Parameter sudo: New, updated or deleted Sudo.
    func sudoChanged(changeType: SudoChangeType, sudo: Sudo) {
        var subscribersToNotify: [SudoSubscriber] = []
        self.queue.sync {
            subscribersToNotify = Array(self.subscribers.values)
        }

        for subscriber in subscribersToNotify {
            subscriber.sudoChanged(changeType: changeType, sudo: sudo)
        }
    }

    /// Processes AppSync subscription connection status change..
    ///
    /// - Parameter status: Connection status.
    func connectionStatusChanged(status: AWSAppSyncSubscriptionWatcherStatus) {
        var connectionState: SubscriptionConnectionState
        switch status {
        case .connected:
            connectionState = .connected
        case .disconnected, .error:
            connectionState = .disconnected
        default:
            // All other status are transient so no need to report this to the consumer.
            return
        }

        // To avoid deadlocks the subscribers should be notified on a queue that isn't
        // being used to access the subscriber list.
        var subscribersToNotify: [SudoSubscriber] = []

        self.queue.sync {
            subscribersToNotify = Array(self.subscribers.values)

            // If the subscription is disconnected then invalid all subscriptions. The consumer
            // can decide to either re-subscribe causing the subscription to connect again or
            // not bother retrying since the disconnection was expected.
            if connectionState == .disconnected {
                self.subscribers.removeAll()
                self.watcher?.cancel()
                self.watcher = nil
            }
        }

        // Notify after the subscriber list is done being manipulated so if a consumer
        // tries to re-subscribe they don't re-subscribe before the list is potentially cleared.
        for subscriber in subscribersToNotify {
            subscriber.connectionStatusChanged(state: connectionState)
        }
    }
}
