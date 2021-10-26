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

    var getMessagesCalled: Bool = false
    var getMessagesParameters: (withConnectionId: String, completion: ClientCompletion<[RelayMessage]>)?
    var getMessagesResult: Result<[RelayMessage], Error> = .failure(
        AnyError("Please add base result to `SudoDIRelayClientSpy.getMessages`")
    )
    func getMessages(
        withConnectionId connectionId: String,
        completion: @escaping ClientCompletion<[RelayMessage]>
    ) {
        getMessagesCalled = true
        getMessagesParameters = (connectionId, completion)
        completion(getMessagesResult)
    }

    var storeMessageCalled: Bool = false
    var storeMessageParameters: (withConnectionId: String, message: String, completion: ClientCompletion<RelayMessage?>)?
    var storeMessageResult: Result<RelayMessage?, Error> = .failure(
        AnyError("Please add base result to `SudoDIRelayClientSpy.storeMessage`")
    )
    func storeMessage(
        withConnectionId connectionId: String,
        message: String,
        completion: @escaping ClientCompletion<RelayMessage?>
    ) {
        storeMessageCalled = true
        storeMessageParameters = (connectionId, message, completion)
        completion(storeMessageResult)
    }

    var createPostboxCalled: Bool = false
    var createPostboxParameters: (withConnectionId: String, completion: ClientCompletion<Void>)?
    var createPostboxResult: Result<Void, Error> = .failure(
        AnyError("Please add base result to `SudoDIRelayClientSpy.createPostbox`")
    )
    func createPostbox(
        withConnectionId connectionId: String,
        completion: @escaping ClientCompletion<Void>
    ) {
        createPostboxCalled = true
        createPostboxParameters = (connectionId, completion)
        completion(createPostboxResult)
    }

    var deletePostboxCalled: Bool = false
    var deletePostboxParameters: (withConnectionId: String, completion: ClientCompletion<Void>)?
    var deletePostboxResult: Result<Void, Error> = .failure(
        AnyError("Please add base result to `SudoDIRelayClientSpy.deletePostbox`")
    )
    func deletePostbox(
        withConnectionId connectionId: String,
        completion: @escaping ClientCompletion<Void>
    ) {
        deletePostboxCalled = true
        deletePostboxParameters = (connectionId, completion)
        completion(deletePostboxResult)
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

    var resetCalled: Bool = false
    func reset() throws {
        resetCalled = true
    }
}
