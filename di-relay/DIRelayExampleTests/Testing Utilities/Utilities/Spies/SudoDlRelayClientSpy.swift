//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
import SudoDIRelay

class MockSubscriptionToken: SubscriptionToken {
    var cancelCallCount = 0
    func cancel() {
        cancelCallCount += 1
    }
}

class SudoDIRelayClientSpy: SudoDIRelayClient {
    
    var resetCalled: Bool = false
    func reset() throws {
        resetCalled = true
    }
    
    var listPostboxesCalled: Bool = false
    var listPostboxesParameters: (Int?, String?)?
    var listPostboxesResult: ListOutput<Postbox>?
    var listPostboxesError: Error?
    func listPostboxes(limit: Int?, nextToken: String?) async throws -> SudoDIRelay.ListOutput<SudoDIRelay.Postbox> {
        listPostboxesCalled = true
        listPostboxesParameters = (limit, nextToken)
        
        if let listPostboxesError = listPostboxesError {
            throw listPostboxesError
        }
        if let listPostboxesResult = listPostboxesResult {
            return listPostboxesResult
        }
        throw AnyError("Please add base result to `SudoDIRelayClientSpy.listPostboxes`")
    }
    
    
    var listMessagesCalled: Bool = false
    var listMessagesParameters: (Int?, String? )? = nil
    var listMessagesResult: ListOutput<Message>?
    var listMessagesError: Error?

    func listMessages(limit: Int?, nextToken: String? ) async throws -> ListOutput<Message> {
        listMessagesCalled = true
        listMessagesParameters = (limit, nextToken)

        if let listMessagesError = listMessagesError {
            throw listMessagesError
        }
        if let listMessagesResult = listMessagesResult {
            return listMessagesResult
        }
        throw AnyError("Please add base result to `SudoDIRelayClientSpy.listMessages`")
    }
    
    var createPostboxCalled: Bool = false
    var createPostboxParameters: (String, String, Bool?)?
    var createPostboxResult: Postbox?
    var createPostboxError: Error?
    func createPostbox(withConnectionId connectionId: String, ownershipProofToken: String, isEnabled: Bool?) async throws -> SudoDIRelay.Postbox {
        createPostboxCalled = true
        createPostboxParameters = (connectionId, ownershipProofToken, isEnabled)
        
        if let createPostboxError = createPostboxError {
            throw createPostboxError
        }
        if let createPostboxResult = createPostboxResult {
            return createPostboxResult
        }
        throw AnyError("Please add base result to `SudoDIRelayClientSpy.createPostbox`")
    }
    
    var updatePostboxCalled: Bool = false
    var updatePostboxParameters: (String, Bool?)?
    var updatePostboxResult: Postbox?
    var updatePostboxError: Error?
    func updatePostbox(withPostboxId postboxId: String, isEnabled: Bool?) async throws -> SudoDIRelay.Postbox {
        updatePostboxCalled = true
        updatePostboxParameters = (postboxId, isEnabled)
        
        if let updatePostboxError = updatePostboxError {
            throw updatePostboxError
        }
        if let updatePostboxResult = updatePostboxResult {
            return updatePostboxResult
        }
        throw AnyError("Please add base result to `SudoDIRelayClientSpy.updatePostbox`")
    }
    
    var deletePostboxCalled: Bool = false
    var deletePostboxParameters: String?
    var deletePostboxResult: String?
    var deletePostboxError: Error?
    func deletePostbox(withPostboxId postboxId: String) async throws -> String {
        deletePostboxCalled = true
        deletePostboxParameters = postboxId
        
        if let deletePostboxError = deletePostboxError {
            throw deletePostboxError
        }
        if let deletePostboxResult = deletePostboxResult {
            return deletePostboxResult
        }
        throw AnyError("Please add base result to `SudoDIRelayClientSpy.deletePostbox`")
    }
    
    var deleteMessageCalled: Bool = false
    var deleteMessageParameters: String?
    var deleteMessageResult: String?
    var deleteMessageError: Error?
    func deleteMessage(withMessageId messageId: String) async throws -> String {
        deleteMessageCalled = true
        deleteMessageParameters = messageId
        
        if let deleteMessageError = deleteMessageError {
            throw deleteMessageError
        }
        if let deleteMessageResult = deleteMessageResult {
            return deleteMessageResult
        }
        throw AnyError("Please add base result to `SudoDIRelayClientSpy.deleteMessage`")
    }
    
    var subscribeToMessageCreatedCalled: Bool = false
    var subscribeToMessageCreatedParameters: (statusChangeHandler: SudoSubscriptionStatusChangeHandler?, completion: ClientCompletion<Message>)?
    var subscribeToMessageCreatedResult: Result<Message, Error> = .failure(
        AnyError("Please add base result to `SudoDIRelayClientSpy.subscribeToMessageCreated`")
    )
    func subscribeToMessageCreated(statusChangeHandler: SudoDIRelay.SudoSubscriptionStatusChangeHandler?, resultHandler: @escaping SudoDIRelay.ClientCompletion<SudoDIRelay.Message>) async throws -> SudoDIRelay.SubscriptionToken? {
        subscribeToMessageCreatedCalled = true
        subscribeToMessageCreatedParameters = (statusChangeHandler, resultHandler)
        resultHandler(subscribeToMessageCreatedResult)
        return MockSubscriptionToken()
    }
    
    
    
    var unsubscribeAllCalled = false
    func unsubscribeAll() {
        unsubscribeAllCalled = true
    }
}
