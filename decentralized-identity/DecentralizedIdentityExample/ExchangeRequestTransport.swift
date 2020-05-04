//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

protocol ExchangeRequestTransport {

    func sendExchangeRequest(
        at invitationId: String,
        request: Data,
        callback: @escaping (Result<Void, Error>) -> Void)

    func waitForExchangeRequest(
        at invitationId: String,
        callback: @escaping (Result<Data, Error>) -> Void)

    func sendExchangeResponse(
        at invitationId: String,
        response: Data,
        callback: @escaping (Result<Void, Error>) -> Void)

    func waitForExchangeResponse(
        at invitationId: String,
        callback: @escaping (Result<Data, Error>) -> Void)
}

class FirebaseExchangeRequestTransport: ExchangeRequestTransport {

    var firestore: Firestore = Firestore.firestore()
    var auth: Auth = Auth.auth()

    var invitations: CollectionReference { firestore.collection("invitations") }

    func sendExchangeRequest(
        at invitationId: String,
        request: Data,
        callback: @escaping (Result<Void, Error>) -> Void) {

        invitations.document(invitationId)
            .setData([
                "request": request,
                "inviteeId": self.auth.currentUser?.uid ?? ""
            ], merge: true) { (error) in
                DispatchQueue.main.async {
                    if let e = error {
                        callback(.failure(e))
                    }
                    else {
                        callback(.success(()))
                    }
                }
        }
    }

    func waitForExchangeRequest(
        at invitationId: String,
        callback: @escaping (Result<Data, Error>) -> Void) {

        DispatchQueue.global(qos: .background).async {
            do {
                // create initial document to observe
                try wait { fn in
                    let data = ["inviterId": self.auth.currentUser?.uid ?? ""]
                    self.invitations.document(invitationId)
                        .setData(data, merge: false) { (error) in
                            if let error = error { fn(.failure(error)) }
                            else { fn(.success(())) }
                    }
                }

                // wait for exchange request (with timeout)
                let result: Data = try wait(timeoutAfter: 3600) { fn in
                    var handle: ListenerRegistration?
                    handle = self.invitations.document(invitationId)
                        .addSnapshotListener { (snapshot, error) in
                            if let error = error {
                                fn(.failure(error))
                            }
                            else if let data = snapshot?.data(),
                                let request = data["request"] as? Data {
                                handle?.remove()
                                fn(.success(request))
                            }
                    }
                }
                DispatchQueue.main.async {
                    callback(.success(result))
                }
            }
            catch {
                DispatchQueue.main.async {
                    callback(.failure(error))
                }
            }
        }
    }

    func sendExchangeResponse(
        at invitationId: String,
        response: Data,
        callback: @escaping (Result<Void, Error>) -> Void) {

        invitations.document(invitationId)
            .setData(["response": response], merge: true) { (error) in
                DispatchQueue.main.async {
                    if let e = error {
                        callback(.failure(e))
                    }
                    else {
                        callback(.success(()))
                    }
                }
        }
    }

    func waitForExchangeResponse(
        at invitationId: String,
        callback: @escaping (Result<Data, Error>) -> Void) {

        DispatchQueue.global(qos: .background).async {
            do {
                let result: Data = try wait(timeoutAfter: 300) { fn in
                    var handle: ListenerRegistration?
                    handle = self.invitations.document(invitationId)
                        .addSnapshotListener { (snapshot, error) in
                            if let error = error {
                                fn(.failure(error))
                            }
                            else if let data = snapshot?.data(),
                                let request = data["response"] as? Data {
                                handle?.remove()
                                fn(.success(request))
                            }
                    }
                }
                DispatchQueue.main.async {
                    callback(.success(result))
                }
            }
            catch {
                DispatchQueue.main.async {
                    callback(.failure(error))
                }
            }
        }
    }
}
