//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Firebase
import Combine

/// An implementation of the "Relay" communication primitive that uses Firebase to provision
/// an HTTPS endpoint for receiving envelopes, and retrieves said envelopes via Firestore.
///
/// # Reference
/// [Aries RFC 0046: Mediators and Relays](https://github.com/hyperledger/aries-rfcs/tree/master/concepts/0046-mediators-and-relays)
class FirebaseRelay {
    let app: FirebaseApp

    init(app: FirebaseApp) {
        self.app = app
    }

    /// Provisions a publicly-accessible HTTPS endpoint.
    ///
    /// - Parameter postboxId: A postbox ID can be explicitly provided.
    ///   A unique ID should be provided so that the resulting endpoint will not be easily guessable.
    /// - Returns: The provisioned service endpoint.
    func serviceEndpoint(forPostboxId postboxId: String) -> String {
        let projectId = app.options.projectID!

        let region = "us-central1"
        let functionName = "endpoint"
        let url = "https://\(region)-\(projectId).cloudfunctions.net/\(functionName)?p=\(postboxId)"

        return url
    }

    /// Retrieves the postbox ID from the provisioned service endpoint.
    /// The provided service endpoint must have been created by this relay.
    ///
    /// - Parameter serviceEndpoint: A service endpoint in the format created by `serviceEndpoint(forPostboxId:)`
    /// - Returns: The extracted postbox ID if preconditions are met.
    func postboxId(fromServiceEndpoint serviceEndpoint: String) -> String? {
        return URLComponents(string: serviceEndpoint)?
            .queryItems?
            .first(where: { $0.name == "p" })?
            .value
    }

    // MARK: Exchange Request / Response

    /// Waits for the first message to arrive at the endpoint corresponding to the provided postbox.
    ///
    /// - Parameter postboxId: The postbox ID provided to `serviceEndpoint(forPostboxId:)`
    /// - Parameter timeout: Timeout with an error after this delay.
    /// - Parameter callback: Called when the message arrives, connection fails, or the wait times out.
    func waitForMessage(
        atPostboxId postboxId: String,
        timeout: TimeInterval,
        callback: @escaping (Result<Data, Error>) -> Void) {

        queue(callback) {
            // sign up at this Firebase endpoint if needed
            let currentUser = try wait(timeoutAfter: 120) { fn in
                self.registerIfNeeded(completion: fn)
            }

            // wait for message (with timeout)
            var subscriptionHandle: ListenerRegistration?
            let result: Data
            do {
                defer { subscriptionHandle?.remove() }

                result = try wait(timeoutAfter: timeout) { fn in
                    subscriptionHandle = Firestore.firestore(app: self.app)
                        .collection("postboxes")
                        .document(postboxId)
                        .collection("messages")
                        .addSnapshotListener { (snapshot, error) in
                            if let error = error {
                                fn(.failure(error))
                            }
                            else if let doc = snapshot?.documents.first,
                                let message = RelayedMessage(queryDocumentSnapshot: doc) {
                                fn(.success(message.body))
                            }
                        }
                }
            }

            return result
        }
    }

    /// Waits for the first message to arrive at the endpoint corresponding to the provided postbox.
    ///
    /// - Parameter postboxId: The postbox ID provided to `serviceEndpoint(forPostboxId:)`
    /// - Parameter timeout: Timeout with an error after this delay.
    /// - Parameter callback: Called when the message arrives, connection fails, or the wait times out.
    /// - Returns: Subscription to messages.
    func subscribeToMessages(
        atPostboxId postboxId: String) -> AnyPublisher<[RelayedMessage], Never> {
        return Future { completion in
            self.registerIfNeeded(completion: completion)
        }
        .flatMap { appAndUser -> AnyPublisher<[RelayedMessage], Error> in
            let document = Firestore.firestore(app: self.app)
                .collection("postboxes")
                .document(postboxId)

            return AnyPublisher.create { observer in
                let request = document
                    .collection("messages")
                    .order(by: "createdAt", descending: true)

                var sub: ListenerRegistration?
                sub = request.addSnapshotListener { [weak sub] (snapshot, error) in
                    if let error = error {
                        NSLog("Error retrieving messages: \(error)")
                        sub?.remove()
                    }

                    let messages = (snapshot?.documents ?? [])
                        .compactMap(RelayedMessage.init)

                    observer.send(messages)
                }
                return Disposable { sub?.remove() }
            }
        }
        .replaceError(with: [])
        .eraseToAnyPublisher()
    }

    // MARK: Authentication

    private func registerIfNeeded(completion: @escaping (Result<User, Error>) -> Void) {
        let auth = Auth.auth(app: app)

        if let currentUser = auth.currentUser {
            NSLog("Already registered with Firebase \(app.options.googleAppID): User \(currentUser.uid)")
            return completion(.success(currentUser))
        }

        struct AuthenticationReturnedNoUserError: Error {}

        auth.signInAnonymously { authResult, error in
            if let error = error {
                NSLog("Failed to register with Firebase: \(error)")
                return completion(.failure(error))
            }

            guard let user = authResult?.user else {
                NSLog("Failed to register with Firebase: no user")
                return completion(.failure(AuthenticationReturnedNoUserError()))
            }

            NSLog("Registered with Firebase \(self.app.options.googleAppID): User \(user.uid)")
            completion(.success(user))
        }
    }

    /// Queues a block for dispatch which can execute synchronously.
    /// This allows the caller to execute synchronous logic, preventing nested callback handlers.
    ///
    /// - Parameter: The handler which will be called from the queue upon result or error from `execute`
    /// - Parameter: The synchronous closure which should return the requisite value or throw
    private func queue<T>(_ completion: @escaping (Result<T, Error>) -> Void,
                  actions: @escaping () throws -> T) {
        DispatchQueue.global(qos: .default).async {
            do {
                completion(.success(try actions()))
            } catch let error {
                completion(.failure(error))
            }
        }
    }
}

struct RelayedMessage {
    /// The relay-specific record ID. This is not the same as the ID of the encrypted message.
    let id: String

    /// The date at which the relay received the data.
    let date: Date

    /// The data received by the relay.
    let body: Data
}

fileprivate extension RelayedMessage {
    init?(queryDocumentSnapshot document: QueryDocumentSnapshot) {
        let data = document.data(with: .estimate)
        guard let body = data["message"] as? Data,
            let createTime = data["createdAt"] as? Timestamp
            else {
                NSLog("Unable to parse message \(data)")
                return nil
        }

        self.id = document.documentID
        self.body = body
        self.date = createTime.dateValue()
    }
}

struct AnyObserver<Output, Failure: Error> {
    let send: ((Output) -> Void)
    let error: ((Failure) -> Void)
    let complete: (() -> Void)
}

struct Disposable {
    let dispose: () -> Void
}

extension AnyPublisher {
    static func create(subscribe: @escaping (AnyObserver<Output, Failure>) -> Disposable) -> Self {
        let subject = PassthroughSubject<Output, Failure>()
        var disposable: Disposable?
        return subject
            .handleEvents(receiveSubscription: { subscription in
                disposable = subscribe(AnyObserver(
                    send: { output in subject.send(output) },
                    error: { failure in subject.send(completion: .failure(failure)) },
                    complete: { subject.send(completion: .finished) }
                ))
            }, receiveCancel: { disposable?.dispose() })
            .eraseToAnyPublisher()
    }
}
