//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SudoDecentralizedIdentity

// Aries RFC 0095: Basic Message Protocol 1.0

struct BasicMessageFeature {
    static func register(to container: inout FeaturesContainer) {
        container.register(message: BasicMessage.self)
    }
}

public struct BasicMessage: DIDCommMessage, Codable {
    public static let messageType = "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/basicmessage/1.0/message"
    public static let messageTypes: Set = [
        messageType,
        "https://didcomm.org/basicmessage/1.0/message"
    ]

    public struct L10n: Decorator, Codable {
        public let locale: String

        public init(locale: String) { self.locale = locale }
    }

    private let base: DIDCommMessageBase

    public let type: String = messageType
    public var id: String { base.id }
    public var thread: ThreadDecorator? { base.thread }

    public let sent: Date
    public let content: String
    public let l10n: L10n?

    public init(
        id: String,
        thread: ThreadDecorator?,
        content: String,
        sent: Date,
        l10n: L10n?
    ) {
        self.base = DIDCommMessageBase(
            type: BasicMessage.messageType,
            id: id,
            thread: thread
        )
        self.sent = sent
        self.content = content
        self.l10n = l10n
    }

    public enum CodingKeys: String, CodingKey {
        case content
        case sent = "sent_time"
        case l10n = "~l10n"
    }

    public enum DecodingError: Error {
        case messageTypeMismatch
    }

    public init(from decoder: Decoder) throws {
        base = try DIDCommMessageBase(from: decoder)

        if !BasicMessage.messageTypes.contains(base.type) {
            throw DecodingError.messageTypeMismatch
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        sent = try container.decode(Date.self, forKey: .sent)
        content = try container.decode(String.self, forKey: .content)
        l10n = try container.decodeIfPresent(L10n.self, forKey: .l10n)
    }

    public func encode(to encoder: Encoder) throws {
        try base.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sent, forKey: .sent)
        try container.encode(content, forKey: .content)
        try container.encodeIfPresent(l10n, forKey: .l10n)
    }
}

// MARK: Aries RFC 0043: L10n

public struct L10nDecorator: Decorator {
    let locale: String?
}
