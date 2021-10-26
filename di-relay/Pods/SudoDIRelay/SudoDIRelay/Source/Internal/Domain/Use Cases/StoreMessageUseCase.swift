//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSAppSync

/// Perform a mutation to store a message in a Postbox.
class StoreMessageUseCase {

    // MARK: - Properties

    let relayService: RelayService

    // MARK: - Lifecycle

    init(relayService: RelayService) {
        self.relayService = relayService
    }

    // MARK: - Methods

    func execute(withConnectionId connectionId: String, message: String, completion: @escaping ClientCompletion<RelayMessage?>) {
        relayService.storeMessage(withConnectionId: connectionId, message: message, completion: completion)
    }
}
