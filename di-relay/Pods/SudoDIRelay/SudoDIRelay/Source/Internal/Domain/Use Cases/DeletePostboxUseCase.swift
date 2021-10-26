//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSAppSync

/// Perform a mutation to delete a Postbox and corresponding messages.
class DeletePostboxUseCase {

    // MARK: - Properties

    let relayService: RelayService

    // MARK: - Lifecycle

    init(relayService: RelayService) {
        self.relayService = relayService
    }

    // MARK: - Methods

    func execute(withConnectionId connectionId: String, completion: @escaping ClientCompletion<Void>) {
        relayService.deletePostbox(withConnectionId: connectionId, completion: completion)
    }
}
