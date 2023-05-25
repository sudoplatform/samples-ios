//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
///
/// A message retrieved from the Relay Service
///
public struct Message: Equatable {
    // MARK: - Properties

    /// The unique message identifier
    public var id: String

    // The timestamp at which the message was created
    public var createdAt: Date

    // The timestamp at which the message was last updated
    public var updatedAt: Date

    // The id of the owner identity
    public var ownerId: String

    // The id of the sudo which owns this message
    public var sudoId: String

    /// Identifier of the owning postbox
    public var postboxId: String

    /// The message text.
    public var message: String

    // MARK: - Lifecycle

    public init(id: String, createdAt: Date, updatedAt: Date, ownerId: String, sudoId: String, postboxId: String, message: String) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.ownerId = ownerId
        self.sudoId = sudoId
        self.postboxId = postboxId
        self.message = message
    }
}
