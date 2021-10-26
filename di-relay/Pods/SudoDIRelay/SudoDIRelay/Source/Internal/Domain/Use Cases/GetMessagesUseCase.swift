//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSAppSync

/// Perform a query of the relay service to get messages in a Postbox corresponding to a connection identifier.
class GetMessagesUseCase {

    // MARK: - Properties

    let relayService: RelayService

    // MARK: - Lifecycle

    init(relayService: RelayService) {
        self.relayService = relayService
    }

    // MARK: - Methods

    func execute(withConnectionId connectionId: String, completion: @escaping ClientCompletion<[RelayMessage]>) {
        relayService.getMessages(withConnectionId: connectionId, completion: completion)
    }
}
