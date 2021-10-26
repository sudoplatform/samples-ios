//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSAppSync

/// Perform a mutation to create a Postbox.
class CreatePostboxUseCase {

    // MARK: - Properties

    let relayService: RelayService

    // MARK: - Lifecycle

    init(relayService: RelayService) {
        self.relayService = relayService
    }

    // MARK: - Methods

    func execute(withConnectionId connectionId: String, completion: @escaping ClientCompletion<Void>) {
        relayService.createPostbox(withConnectionId: connectionId, completion: completion)
    }
}
