//
// Copyright © 2025 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine
import Foundation
import SudoEmail

enum SubscriptionError: Error {
    case connectionTimedOut
    case resultTimedOut
}

/// Utility to allow conveniently wait for a subscription to connect, and then wait for the
/// message notification to arrive.
///
/// ```swift
/// // First create the subscription
/// let updateSubscription = Subscription(client: sudoEmailClient, notificationType: .messageUpdated)
///
/// // Then perform the mutation
/// let updatedMessage = sudoEmailClient.updateMessage(...)
///
/// // Then wait for the result
/// updateSubscription.waitForMessage(withId: updatedMessage.id)
/// ```
class Subscription: SudoEmail.Subscriber {

    // MARK: - Properties

    let id = UUID().uuidString

    let notificationType: SubscriptionNotificationType

    weak var client: SudoEmailClient?

    let messagesSubject = CurrentValueSubject<[EmailMessage], SubscriptionError>([])

    let connectionStateSubject = CurrentValueSubject<SubscriptionConnectionState, SubscriptionError>(.disconnected)

    var connectionCancellable: AnyCancellable?

    var messageCancellable: AnyCancellable?

    // MARK: - Lifecycle

    /// Initializer which only returns once the requested subscription has connected.  If the connection times out,
    /// a `SubscriptionError.connectionTimedOut` error will be thrown.
    /// - Parameters:
    ///   - client: The `SudoEmailClient` to subscribe to.
    ///   - notificationType: The type of email message notification to subscribe to. Default: .messageCreated
    ///   - connectionTimeout: The max time to wait in seconds for the subscription to connect.  Default: 10.
    init(
        client: SudoEmailClient,
        notificationType: SubscriptionNotificationType = .messageCreated,
        connectionTimeout: TimeInterval = 10
    ) async throws {
        self.client = client
        self.notificationType = notificationType
        try await client.subscribe(id: id, notificationType: notificationType, subscriber: self)

        let _: Void = try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false
            connectionCancellable = connectionStateSubject
                .filter { $0 == .connected }
                .map { _ in }
                .timeout(.seconds(connectionTimeout), scheduler: DispatchQueue.global(), customError: {
                    return SubscriptionError.connectionTimedOut
                })
                .sink(
                    receiveCompletion: { [weak self] completion in
                        guard !hasResumed, let self else { return }
                        hasResumed = true
                        self.connectionCancellable = nil
                        switch completion {
                        case .finished:
                            continuation.resume(throwing: SudoEmailError.fatalError("Unexpected subscription completion"))
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    },
                    receiveValue: { [weak self] in
                        guard !hasResumed, let self else { return }
                        hasResumed = true
                        self.connectionCancellable = nil
                        continuation.resume(returning: ())
                    }
                )
        }
    }

    // MARK: - Methods

    @discardableResult
    func waitForMessage(withId id: String, timeout: TimeInterval = 20) async throws -> EmailMessage {
        return try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false
            messageCancellable = messagesSubject
                .filter { messages in
                    messages.contains(where: { $0.id == id })
                }
                .timeout(.seconds(timeout), scheduler: DispatchQueue.global(), customError: {
                    return SubscriptionError.resultTimedOut
                })
                .sink(
                    receiveCompletion: { [weak self] completion in
                        guard !hasResumed, let self else { return }
                        hasResumed = true
                        self.connectionCancellable = nil
                        switch completion {
                        case .finished:
                            continuation.resume(throwing: SudoEmailError.fatalError("Unexpected subscription completion"))
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    },
                    receiveValue: { [weak self] messages in
                        guard !hasResumed, let self else { return }
                        hasResumed = true
                        self.connectionCancellable = nil
                        if let message = messages.first(where: { $0.id == id }) {
                            continuation.resume(returning: message)
                        } else {
                            continuation.resume(throwing: SudoEmailError.fatalError("Unexpected message received."))
                        }
                    }
                )
        }
    }

    @discardableResult
    func waitForMessages(withIds ids: [String], timeout: TimeInterval = 20) async throws -> [EmailMessage] {
        return try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false
            let requiredIds = Set(ids)
            messageCancellable = messagesSubject
                .filter { messages in
                    let messageIds = Set(messages.map(\.id))
                    return messageIds.isSuperset(of: requiredIds)
                }
                .timeout(.seconds(timeout), scheduler: DispatchQueue.global(), customError: {
                    return SubscriptionError.resultTimedOut
                })
                .sink(
                    receiveCompletion: { [weak self] completion in
                        guard !hasResumed, let self else { return }
                        hasResumed = true
                        self.messageCancellable = nil
                        switch completion {
                        case .finished:
                            continuation.resume(throwing: SudoEmailError.fatalError("Unexpected subscription completion"))
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    },
                    receiveValue: { [weak self] messages in
                        guard !hasResumed, let self else { return }
                        hasResumed = true
                        self.messageCancellable = nil
                        let requiredMessages = requiredIds.compactMap { id in
                            messages.first(where: { $0.id == id })
                        }
                        continuation.resume(returning: requiredMessages)
                    }
                )
        }
    }

    // MARK: - Conformance: Subscriber

    func notify(notification: SudoEmail.SubscriptionNotification) {
        switch notification {
        case .messageCreated(let message), .messageUpdated(let message), .messageDeleted(let message):
            let existingMessages = messagesSubject.value
            messagesSubject.send(existingMessages + [message])
        }
    }

    func connectionStatusChanged(state: SudoEmail.SubscriptionConnectionState) {
        connectionStateSubject.send(state)
    }
}
