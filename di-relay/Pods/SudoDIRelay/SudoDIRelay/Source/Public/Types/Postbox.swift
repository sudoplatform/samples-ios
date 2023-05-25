//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
///
/// A postbox that stores messages in the relay.
///
public struct Postbox: Equatable {

    // MARK: - Properties

    /// The unique postbox identifier
    public var id: String

    // The timestamp at which the postbox was created
    public var createdAt: Date

    // The timestamp at which the postbox was last updated
    public var updatedAt: Date

    // The id of the owner identity (user)
    public var ownerId: String

    // The id of the sudo which owns this postbox
    public var sudoId: String

    // The connection id which is provided on postbox creation
    public var connectionId: String

    // Whether the postbox is enabled. An enabled postbox accepts messages
    public var isEnabled: Bool

    // The service endpoint which should be used to transmit messages to this postbox
    public var serviceEndpoint: String

    // MARK: - Lifecycle

    public init(id: String, createdAt: Date, updatedAt: Date, ownerId: String, sudoId: String, connectionId: String, isEnabled: Bool, serviceEndpoint: String) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.ownerId = ownerId
        self.sudoId = sudoId
        self.connectionId = connectionId
        self.isEnabled = isEnabled
        self.serviceEndpoint = serviceEndpoint
    }
}
