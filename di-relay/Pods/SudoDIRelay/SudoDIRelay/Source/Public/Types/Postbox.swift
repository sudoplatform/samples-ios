//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
///
/// A postbox that stores messages in the relay.
///
public struct Postbox: Equatable {

    // MARK: - Properties

    /// Postbox identifier.
    public let connectionId: String

    /// Identifier of the user that owns postbox.
    public let userId: String

    /// Identifier of the sudo that owns the postbox.
    public let sudoId: String

    /// The day and time which the postbox was created.
    public let timestamp: Date

    // MARK: - Lifecycle

    public init(connectionId: String, userId: String, sudoId: String, timestamp: Date) {
        self.connectionId = connectionId
        self.userId = userId
        self.sudoId = sudoId
        self.timestamp = timestamp
    }
}
