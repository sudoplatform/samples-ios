//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

struct Message {
    let date: Date
    let body: String
}

protocol MessageTransport {

    func messages(pairwiseDid: String) -> AnyPublisher<[Message], Never>
    func sendMessage(pairwiseDid: String, body: String)
}

class FirebaseMessageTransport: MessageTransport {

    var firestore: Firestore = Firestore.firestore()
    var auth: Auth = Auth.auth()
    var pairwiseData: CollectionReference { firestore.collection("pairwiseData") }
    let transformer = Transformer()

    func messages(pairwiseDid: String) -> AnyPublisher<[Message], Never> {
        let pairwiseData = self.pairwiseData
        let transformer = self.transformer
        return AnyPublisher.create { observer in

            let request = pairwiseData.document(pairwiseDid)
                .collection("messages")
                .order(by: "createdAt", descending: true)

            var sub: ListenerRegistration?
            sub = request.addSnapshotListener { [weak sub] (snapshot, error) in
                if let error = error {
                    print("Error retrieving messages: \(error)")
                    sub?.remove()
                }
                let documents: [QueryDocumentSnapshot] = snapshot?.documents ?? []
                observer.send(documents.compactMap(transformer.transform))
            }
            return Disposable { sub?.remove() }
        }
    }

    func sendMessage(pairwiseDid: String, body: String) {
        pairwiseData.document(pairwiseDid)
            .collection("messages")
            .addDocument(data: transformer.transform(body: body))
    }

    struct Transformer {

        var auth: Auth = Auth.auth()

        func transform(document: QueryDocumentSnapshot) -> Message? {
            let data = document.data(with: .estimate)
            guard let body = data["body"] as? String,
                let createTime = data["createdAt"] as? Timestamp
                else {
                    print("Unable to parse message \(data)")
                    return nil
            }
            return Message(date: createTime.dateValue(),
                           body: body)
        }

        func transform(body: String) -> [String: Any] {
            return [
                "createdAt": FieldValue.serverTimestamp(),
                "body": body
            ]
        }
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
