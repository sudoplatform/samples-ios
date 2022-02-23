//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSAppSync

/// Get the HTTP endpoint of a postbox in the relay.
class GetPostboxEndpointUseCase {

    // MARK: - Properties

    let relayService: RelayService

    // MARK: - Lifecycle

    init(relayService: RelayService) {
        self.relayService = relayService
    }

    // MARK: - Methods

    func execute(withConnectionId connectionId: String) -> URL? {
        return relayService.getPostboxEndpoint(withConnectionId: connectionId)
    }
}
