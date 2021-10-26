//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol RelayService: AnyObject, Resetable {

    // MARK: - Methods

    /// Get list of messages.
    /// - Parameters:
    ///   - connectionId: Identifier of the postbox to retrieve messages from.
    ///   - completion: Returns an array of `RelayMessage`s on success, and `Error` on failure.
    func getMessages(withConnectionId connectionId: String, completion: @escaping ClientCompletion<[RelayMessage]>)

    /// Create the postbox.
    /// - Parameters:
    ///   - connectionId: Identifier of the postbox to retrieve messages from.
    ///   - completion: Returns `Void` on success, and `Error` on failure.
    func createPostbox(withConnectionId connectionId: String, completion: @escaping ClientCompletion<Void>)

    /// Store a message in the relay.
    /// - Parameters:
    ///   - connectionId: Identifier of the postbox to retrieve messages from.
    ///   - message: The message to store in the relay,
    ///   - completion: Returns the stored `RelayMessage` on success, `nil` on failure.
    func storeMessage(withConnectionId connectionId: String, message: String, completion: @escaping ClientCompletion<RelayMessage?>)

    /// Delete the postbox including the entire conversation thread.
    /// - Parameters:
    ///   - connectionId: Identifier of the postbox to retrieve messages from.
    ///   - completion: Returns `Void` on success, and `Error` on failure.
    func deletePostbox(withConnectionId connectionId: String, completion: @escaping ClientCompletion<Void>)

    /// Subscribe to messages received to the given postbox.
    /// - Parameters:
    ///   - connectionId: Identifier of the postbox to retrieve messages from.
    ///   - resultHandler: Returns the `RelayMessage` on success, or `Error` on failure.
    func subscribeToMessagesReceived(withConnectionId connectionId: String, resultHandler: @escaping ClientCompletion<RelayMessage>) throws -> SubscriptionToken

    /// Subscribe to a postbox deletion.
    /// - Parameters:
    ///   - connectionId: Identifier of the postbox to retrieve messages from.
    ///   - resultHandler: Returns `Status` on success, or `Error` on failure.
    func subscribeToPostboxDeleted(withConnectionId connectionId: String, resultHandler: @escaping ClientCompletion<Status>) throws -> SubscriptionToken

}
