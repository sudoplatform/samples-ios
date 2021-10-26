//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSAppSync

/// Use case representation of  an operation to subscribe to the creation of an inbound message.
class SubscribeToMessagesReceivedUseCase {

    // MARK: - Properties

    let relayService: RelayService

    // MARK: - Lifecycle

    init(relayService: RelayService) {
        self.relayService = relayService
    }

    // MARK: - Methods

    func execute(withConnectionId connectionId: String, completion: @escaping ClientCompletion<RelayMessage>) -> SubscriptionToken? {
        do {
            return try relayService.subscribeToMessagesReceived(withConnectionId: connectionId, resultHandler: completion)
        } catch let error {
            completion(.failure(error))
            return nil
        }
    }
}
