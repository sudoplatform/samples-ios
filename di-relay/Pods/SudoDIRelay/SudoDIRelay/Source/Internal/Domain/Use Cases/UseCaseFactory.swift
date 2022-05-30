//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Utility class for generating use cases from the core level of the SDK in the consumer/API level.
class UseCaseFactory {

    // MARK: - Properties

    private let relayService: RelayService

    // MARK: - Lifecycle

    init(relayService: RelayService) {
        self.relayService = relayService
    }

    // MARK: - Methods

    func generateListMessages() -> ListMessagesUseCase {
        return ListMessagesUseCase(relayService: relayService)
    }

    func generateCreatePostbox() -> CreatePostboxUseCase {
        return CreatePostboxUseCase(relayService: relayService)
    }

    func generateStoreMessage() -> StoreMessageUseCase {
        return StoreMessageUseCase(relayService: relayService)
    }

    func generateDeletePostbox() -> DeletePostboxUseCase {
        return DeletePostboxUseCase(relayService: relayService)
    }

    func generateSubscribeToMessagesReceived() -> SubscribeToMessagesReceivedUseCase {
        return SubscribeToMessagesReceivedUseCase(relayService: relayService)
    }

    func generateSubscribeToPostboxDeleted() -> SubscribeToPostboxDeletedUseCase {
        return SubscribeToPostboxDeletedUseCase(relayService: relayService)
    }

    func generateGetPostboxEndpoint() -> GetPostboxEndpointUseCase {
        return GetPostboxEndpointUseCase(relayService: relayService)
    }

    func generateListPostboxes() -> ListPostboxesUseCase {
        return ListPostboxesUseCase(relayService: relayService)
    }
}
