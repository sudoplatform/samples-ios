//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSAppSync

/// Perform a query of the relay service to get messages in a Postbox corresponding to a connection identifier.
class ListMessagesUseCase {

    // MARK: - Properties

    let relayService: RelayService

    // MARK: - Lifecycle

    init(relayService: RelayService) {
        self.relayService = relayService
    }

    // MARK: - Methods

    func execute(withConnectionId connectionId: String) async throws -> [RelayMessage] {
        return try await relayService.listMessages(withConnectionId: connectionId)
    }
}
