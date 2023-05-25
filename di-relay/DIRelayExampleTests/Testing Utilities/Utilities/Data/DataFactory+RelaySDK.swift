//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoDIRelay

extension DataFactory {

    enum RelaySDK {

        static func randomId() -> String {
            return UUID().uuidString
        }

        static func randomDate() -> Date {
            return Date(timeIntervalSince1970: Double.random(in: Range(uncheckedBounds: (1, 1000))))
        }
        
        static func fromMessageId(messageId: String) -> Message {
            let now = Date()
            return Message(
                id: messageId,
                createdAt: now,
                updatedAt: now,
                ownerId: randomId(),
                sudoId: randomId(),
                postboxId: randomId(),
                message: "This is a test message"
            )
        }
        
        static func fromPostboxId(postboxId: String) -> Postbox {
            let now = Date()
            return Postbox (
                id: postboxId,
                createdAt: now,
                updatedAt: now,
                ownerId: randomId(),
                sudoId: randomId(),
                connectionId: randomId(),
                isEnabled: true,
                serviceEndpoint: "https://service.endpoint.com/di-relay"
            )
        }
        static func randomPostbox() -> Postbox {
            return fromPostboxId(postboxId: randomId())
        }
    }
}
