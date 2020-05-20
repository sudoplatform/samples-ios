//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SudoDecentralizedIdentity

struct DIDExchangeFeature {
    static func register(to container: inout FeaturesContainer) {
        container.register(message: Invitation.self)
        container.register(message: ExchangeRequest.self)
        container.register(message: ExchangeResponse.self)
        container.register(message: SignedExchangeResponse.self)
        container.register(message: Acknowledgement.self)
    }
}

extension Invitation: DIDCommMessage {
    public static let messageType = "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/connections/1.0/invitation"
    public static let messageTypes: Set = [
        messageType,
        "https://didcomm.org/connections/1.0/invitation",
        "https://didcomm.org/didexchange/1.0/invitation",
    ]
}

extension ExchangeRequest: DIDCommMessage {
    public static let messageType = "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/connections/1.0/request"
    public static let messageTypes: Set = [
        messageType,
        "https://didcomm.org/connections/1.0/request",
        "https://didcomm.org/didexchange/1.0/request",
    ]
}

extension ExchangeResponse: DIDCommMessage {
    public static let messageType = "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/connections/1.0/response"
    public static let messageTypes: Set = [
        messageType,
        "https://didcomm.org/connections/1.0/response",
        "https://didcomm.org/didexchange/1.0/response",
    ]
}

extension SignedExchangeResponse: DIDCommMessage {
    public static let messageType = ExchangeResponse.messageType
    public static let messageTypes = ExchangeResponse.messageTypes
}

// TODO: "complete" message
extension Acknowledgement: DIDCommMessage {
    public static let messageType = "https://didcomm.org/didexchange/1.0/complete"
    public static let messageTypes: Set = [
        messageType,
    ]
}
