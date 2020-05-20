//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SudoDecentralizedIdentity

/// https://github.com/hyperledger/aries-rfcs/tree/master/features/0067-didcomm-diddoc-conventions#message-preparation-conventions
func encryptForRoutingKeys(
    walletId: String,
    message: PackedMessage,
    to: String,
    routingKeys: ArraySlice<String>,
    completion: @escaping (Result<PackedMessage, Error>) -> Void
) {
    guard let currentRoutingKey = routingKeys.first else {
        // empty list of routing keys - done
        return completion(.success(message))
    }

    // avoid potentially large stack space
    if routingKeys.count > 100 {
        struct TooManyRoutingKeysError: Error {}
        return completion(.failure(TooManyRoutingKeysError()))
    }

    struct ForwardMessage: Codable {
        let type = "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/routing/1.0/forward"
        let id: String
        let to: String
        let message: PackedMessage

        enum CodingKeys: String, CodingKey {
            case type = "@type"
            case id = "@id"
            case to
            case message = "msg"
        }
    }

    let routingMessage = ForwardMessage(
        id: UUID().uuidString,
        to: to,
        message: message
    )

    let routingMessageJson: Data
    do {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .withoutEscapingSlashes
        routingMessageJson = try encoder.encode(routingMessage)
    } catch let error {
        return completion(.failure(error))
    }

    Dependencies.sudoDecentralizedIdentityClient.packMessage(
        walletId: walletId,
        message: routingMessageJson,
        recipientVerkeys: [currentRoutingKey],
        senderVerkey: nil // anoncrypt
    ) { result in
        switch result {
        case .success(let packedMessage):
            encryptForRoutingKeys(
                walletId: walletId,
                message: packedMessage,
                to: currentRoutingKey,
                routingKeys: routingKeys.dropFirst(),
                completion: completion
            )
        case .failure(let error):
            completion(.failure(error))
        }
    }
}

func createPairwise(walletId: String, label: String,
                    myDid: String, myDidDoc: DidDoc, theirDid: String, theirDidDoc: DidDoc,
                    onSuccess: @escaping (Pairwise) -> Void, onFailure: @escaping (String, Error?) -> Void) {
    do {
        try KeychainDIDDocStorage().store(doc: myDidDoc, for: myDid)
        try KeychainDIDDocStorage().store(doc: theirDidDoc, for: theirDid)
    } catch let error {
        onFailure("Failed to persist DID doc", error)
        return
    }

    // Attempt to find a public key from the sender's DID Doc.
    // TODO: We may need to be smarter about finding the right key in the future.
    guard let recipientVerkey: String = theirDidDoc.publicKey
        .first(where: { key in
            if case .ed25519VerificationKey2018 = key.type {
                return true
            }
            return false
        })?.specifier else {
            onFailure("No verkey found in recipient's DID Doc", nil)
            return
    }

    Dependencies.sudoDecentralizedIdentityClient.createPairwise(
        walletId: walletId,
        theirDid: theirDid,
        theirVerkey: recipientVerkey,
        label: label,
        myDid: myDid
    ) { result in
        switch result {
        case .success:
            Dependencies.sudoDecentralizedIdentityClient.listPairwise(walletId: walletId) { result in
                switch result {
                case .success(let pairwiseConnections):
                    guard let pairwiseConnection = pairwiseConnections.first(where: {
                        $0.myDid == myDid && $0.theirDid == theirDid
                    }) else {
                        onFailure("Failed to retrieve pairwise connection", nil)
                        return
                    }

                    onSuccess(pairwiseConnection)
                case .failure(let error):
                    onFailure("Failed to retrieve pairwise connection", error)
                }
            }
        case .failure(let error):
            onFailure("Failed to create pairwise connection", error)
        }
    }
}
