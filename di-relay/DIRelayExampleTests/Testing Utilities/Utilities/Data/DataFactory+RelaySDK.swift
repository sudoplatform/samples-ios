//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoDIRelay

extension DataFactory {

    enum RelaySDK {

        static func randomConnectionId() -> String {
            return UUID().uuidString
        }

        static func randomEmailAddress() -> String {
            return  "\(UUID().uuidString)@\(UUID().uuidString)"
        }

        static func randomDate() -> Date {
            return Date(timeIntervalSince1970: Double.random(in: Range(uncheckedBounds: (1, 1000))))
        }

        static func generateRelayMessage(
            connectionId: String = UUID().uuidString,
            messageId: String = UUID().uuidString,
            timestamp: Date = randomDate(),
            updated: Date = randomDate(),
            direction: RelayMessage.Direction = .inbound,
            cipherText: String = "Test Subject"
        ) -> RelayMessage {
            return RelayMessage(
                messageId: messageId,
                connectionId: connectionId,
                cipherText: cipherText,
                direction: direction,
                timestamp: timestamp
            )
        }
    }
}
