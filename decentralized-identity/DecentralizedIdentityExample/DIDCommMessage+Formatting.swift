//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// this would not be in the Protocols folder

import SudoDecentralizedIdentity

protocol PreviewableDIDCommMessage: DIDCommMessage {
    var typeDescription: String { get }
    var preview: String { get }
    var detailFields: [(key: String, value: String)] { get }
}

extension BasicMessage: PreviewableDIDCommMessage {
    var typeDescription: String {
        return "Basic Message 1.0"
    }

    var preview: String {
        return content
    }

    var detailFields: [(key: String, value: String)] {
        return [
            ("Content", content),
            ("Sent At", DateFormatter.localizedString(
                from: sent,
                dateStyle: .short,
                timeStyle: .long
            )),
        ]
    }
}

extension ExchangeResponse: PreviewableDIDCommMessage {
    var typeDescription: String {
        return "Connections Response 1.0"
    }

    var preview: String {
        return "(Exchange Response from \(connection.did))"
    }

    var detailFields: [(key: String, value: String)] {
        return [
            ("DID", connection.did),
        ]
        + connection.didDoc.publicKey
            .enumerated()
            .map { i, publicKey in
                [
                    ("Public Key \(i) ID", publicKey.id),
                    ("Public Key \(i) Specifier", publicKey.specifier),
                ]
            }
            .joined()
        + connection.didDoc.service
            .enumerated()
            .map { i, service in
                [
                    ("Service \(i) ID", service.id),
                    ("Service \(i) Endpoint", service.endpoint),
                    ("Service \(i) Recipients", service.recipientKeys
                        .joined(separator: ", ")),
                    ("Service \(i) Routing", service.routingKeys
                        .joined(separator: ", ")),
                ]
            }
            .joined()
    }
}

extension SignedExchangeResponse: PreviewableDIDCommMessage {
    var typeDescription: String {
        return "Connections Response 1.0 (Signed)"
    }

    var preview: String {
        return "(Signed Exchange Response from \(signedConnection.signer))"
    }

    var detailFields: [(key: String, value: String)] {
        return [
            ("Signer", self.signedConnection.signer),
            ("Signature Type", self.signedConnection.type),
            ("Signature", self.signedConnection.signature),
            ("Signed Data", self.signedConnection.signedData),
            // TODO: Show decoded exchange response details.
        ]
    }
}
