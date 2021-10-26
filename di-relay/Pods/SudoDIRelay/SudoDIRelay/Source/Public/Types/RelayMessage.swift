//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
///
/// A DIDComm message in the relay
///
public struct RelayMessage: Equatable {

    // MARK: - Supplementary

    /// Direction of a DIDComm message.
    public enum Direction: Equatable {
        /// Message is inbound to the user - message has been received by the user.
        case inbound
        /// Message is outbound to the user - message has been sent by the user.
        case outbound
    }

    // MARK: - Properties

    /// The user's message identifier
    public var messageId: String

    /// Identifier of the DIDComm connection
    public var connectionId: String

    /// The text contained in the DIDComm mesasge
    public var cipherText: String

    /// Direction of the DIDComm message
    public var direction: Direction

    /// The day and time which the message was created
    public var timestamp: Date

    // MARK: - Lifecycle

    public init(messageId: String, connectionId: String, cipherText: String, direction: Direction, timestamp: Date ) {
        self.messageId = messageId
        self.connectionId = connectionId
        self.cipherText = cipherText
        self.direction = direction
        self.timestamp = timestamp
    }
}
