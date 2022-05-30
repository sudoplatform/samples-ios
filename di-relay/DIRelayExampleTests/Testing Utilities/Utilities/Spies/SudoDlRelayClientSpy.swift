//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoDIRelay

class MockSubscriptionToken: SubscriptionToken {
    var cancelCallCount = 0
    func cancel() {
        cancelCallCount += 1
    }
}

class SudoDIRelayClientSpy: SudoDIRelayClient {
    var getPostboxEndpointCalled: Bool = false
    var getPostboxEndpointParameters: (String)?
    var getPostboxEndpointResult: URL?

    func getPostboxEndpoint(withConnectionId connectionId: String) -> URL? {
        getPostboxEndpointCalled = true
        getPostboxEndpointParameters = (connectionId)
        return getPostboxEndpointResult
    }

    var listMessagesCalled: Bool = false
    var listMessagesParameters: String? = nil
    var listMessagesResult: [RelayMessage]?
    var listMessagesError: Error?

    func listMessages(withConnectionId connectionId: String) async throws -> [RelayMessage] {
        listMessagesCalled = true
        listMessagesParameters = connectionId

        if let listMessagesError = listMessagesError {
            throw listMessagesError
        }
        if let listMessagesResult = listMessagesResult {
            return listMessagesResult
        }
        throw AnyError("Please add base result to `SudoDIRelayClientSpy.listMessages`")
    }

    var storeMessageCalled: Bool = false
    var storeMessageParameters: (withConnectionId: String, message: String)?
    var storeMessageResult: RelayMessage?
    var storeMessageError: Error?
    func storeMessage(withConnectionId connectionId: String, message: String) async throws -> RelayMessage? {
        storeMessageCalled = true
        storeMessageParameters = (connectionId, message)

        if let storeMessageError = storeMessageError {
            throw storeMessageError
        }
        return storeMessageResult
    }

    var createPostboxCalled: Bool = false
    var createPostboxParameters: String?
    var createPostboxError: Error?
    func createPostbox(withConnectionId connectionId: String, ownershipProofToken: String) async throws {
        createPostboxCalled = true
        createPostboxParameters = connectionId

        if let createPostboxError = createPostboxError {
             throw createPostboxError
        }
    }

    var deletePostboxCalled: Bool = false
    var deletePostboxParameters: String?
    var deletePostboxError: Error?
    func deletePostbox(withConnectionId connectionId: String) async throws {
        deletePostboxCalled = true
        deletePostboxParameters = connectionId
        if let deletePostboxError = deletePostboxError {
            throw deletePostboxError
        }
    }

    var subscribeToMessagesReceivedCalled: Bool = false
    var subscribeToMessagesReceivedParameters: (withConnectionId: String, completion: ClientCompletion<RelayMessage>)?
    var subscribeToMessagesReceivedResult: Result<RelayMessage, Error> = .failure(
        AnyError("Please add base result to `SudoDIRelayClientSpy.subscribeToMessagesReceived`")
    )
    func subscribeToMessagesReceived(
        withConnectionId connectionId: String,
        resultHandler: @escaping ClientCompletion<RelayMessage>
    ) -> SubscriptionToken? {
        subscribeToMessagesReceivedCalled = true
        subscribeToMessagesReceivedParameters = (connectionId, resultHandler)
        resultHandler(subscribeToMessagesReceivedResult)
        return MockSubscriptionToken()
    }

    var subscribeToPostboxDeletedCalled: Bool = false
    var subscribeToPostboxDeletedParameters: (withConnectionId: String, completion: ClientCompletion<Status>)?
    var subscribeToPostboxDeletedResult: Result<Status, Error> = .failure(
        AnyError("Please add base result to `SudoDIRelayClientSpy.subscribeToPostboxDeleted`")
    )
    func subscribeToPostboxDeleted(
        withConnectionId connectionId: String,
        resultHandler: @escaping ClientCompletion<Status>
    ) -> SubscriptionToken? {
        subscribeToPostboxDeletedCalled = true
        subscribeToPostboxDeletedParameters = (connectionId, resultHandler)
        resultHandler(subscribeToPostboxDeletedResult)
        return MockSubscriptionToken()
    }

    var listPostboxesCalled: Bool = false
    var listPostboxesParameters: String? = nil
    var listPostboxesResult: [Postbox]?
    var listPostboxesError: Error?

    func listPostboxes(withSudoId sudoId: String) async throws -> [Postbox] {
        listPostboxesCalled = true
        listPostboxesParameters = sudoId

        if let listPostboxesError = listPostboxesError {
            throw listPostboxesError
        }

        if let listPostboxesResult = listPostboxesResult {
            return listPostboxesResult
        }

        throw AnyError("Please add base result to `SudoDIRelayClientSpy.listPostboxesForSudoIdResult`")
    }

    var resetCalled: Bool = false
    func reset() throws {
        resetCalled = true
    }
}
