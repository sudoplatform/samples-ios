//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// https://github.com/hyperledger/aries-rfcs • f20e6b129951a1d77735d76aed56762dac3333f2
// 0302: Aries Interop Profile
// 0003: Protocols
// \- 0005: DIDComm
// |  \- 0021: DIDComm Message Anatomy
// |  |  \- 0020: Message Types
// |  |  |- 0047: JSON-LD Compatibility
// |  |     \- 0249: Aries Rich Schema Contexts
// |  |  |- 0011: Decorators
// |  |  |- 0008: Message ID and Threading
// |  |  |- 0234: Signature Decorator
// |  |  |- 0043: L10n
// |  |  |- 0019: Encryption Envelope
// |  |  |- 0044: DIDComm File and MIME Types
// |  |- 0025: Agent Transports
// |  |- 0094: Cross Domain Messaging
// |  |  \- 0067: DIDComm DIDDoc Conventions
// |  |     \- https://w3c-ccg.github.io/did-spec/#service-endpoints
// |- 0160: Connection Protocol / 0023: DID Exchange
// |- 0095: Basic Messaging
// |- 0035: Report Problem
// |- 0434: Out of Band

// MARK: 0021, 0020, 0011, 0008

public protocol Decorator: Codable {}

public protocol DIDCommMessage: Codable {
    var type: String { get }
    var id: String { get }

    static var messageType: String { get }
    static var messageTypes: Set<String> { get }
}

public struct DIDCommMessageBase: Codable {
    public let type: String
    public let id: String
    public let thread: ThreadDecorator?

    public enum CodingKeys: String, CodingKey {
        case type = "@type"
        case id = "@id"
        case thread = "~thread"
    }

    public init(type: String, id: String, thread: ThreadDecorator?) {
        self.type = type
        self.id = id
        self.thread = thread
    }
}

// MARK: 0008

public struct ThreadDecorator: Decorator {
    public let thid: String
    public let pthid: String?
    public let senderOrder: Int?
    public let receivedOrders: [String: Int]?

    public enum CodingKeys: String, CodingKey {
        case thid, pthid
        case senderOrder = "sender_order"
        case receivedOrders = "received_orders"
    }
}
