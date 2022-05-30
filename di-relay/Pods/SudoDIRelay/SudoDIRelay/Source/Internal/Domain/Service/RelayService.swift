//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol RelayService: AnyObject {

    // MARK: - Methods

    /// Fetch a list of messages from the relay.
    /// - Parameters:
    ///    - connnectionId: Identifier of the postbox to retrieve messages from.
    /// - Throws: `SudoDIRelayError`
    /// - Returns: Array of messages from the relay.
    func listMessages(withConnectionId connectionId: String) async throws -> [RelayMessage]

    /// Create the postbox.
    /// - Parameters:
    ///   - connectionId: Identifier of the postbox to create.
    ///   - ownershipProofToken: Token attesting the user's ownership of the sudo.
    /// - Throws: `SudoDIRelayError`
    func createPostbox(withConnectionId connectionId: String, ownershipProofToken: String) async throws

    /// Store a message in the relay.
    /// - Parameters:
    ///   - connectionId: Identifier of the postbox to retrieve messages from.
    ///   - message: The message to store in the relay,
    /// - Returns: The stored message, `RelayMessage`, on success, `nil` on failure.
    /// - Throws: `SudoDIRelayError`
    func storeMessage(withConnectionId connectionId: String, message: String) async throws -> RelayMessage?

    /// Delete the postbox including the entire conversation thread.
    /// - Parameters:
    ///   - connectionId: Identifier of the postbox to retrieve messages from.
    /// - Throws: `SudoDIRelayError`
    func deletePostbox(withConnectionId connectionId: String) async throws

    /// Get HTTP endpoint of the postbox given the postbox identifier.
    /// - Returns: The postbox HTTP endpoint on success, or nil on failure.
    func getPostboxEndpoint(withConnectionId connectionId: String) -> URL?

    /// Get a list of postboxes that are associated with the given`sudoId`.
    /// - Returns: A list of postboxes on success.
    /// - Throws: `SudoDIRelayError`
    func listPostboxes(withSudoId sudoId: String) async throws -> [Postbox]

    /// Subscribe to messages received to the given postbox.
    /// - Parameters:
    ///   - connectionId: Identifier of the postbox to retrieve messages from.
    ///   - resultHandler: Returns the `RelayMessage` on success, or `Error` on failure.
    /// - Returns: Token to manage subscription.
    /// - Throws: `SudoDIRelayError`
    func subscribeToMessagesReceived(
        withConnectionId connectionId: String,
        resultHandler: @escaping ClientCompletion<RelayMessage>
    ) async throws -> SubscriptionToken

    /// Subscribe to a postbox deletion.
    /// - Parameters:
    ///   - connectionId: Identifier of the postbox to retrieve messages from.
    ///   - resultHandler: Returns `Status` on success, or `Error` on failure.
    /// - Returns: Token to manage subscription.
    /// - Throws: `SudoDIRelayError`
    func subscribeToPostboxDeleted(
        withConnectionId connectionId: String,
        resultHandler: @escaping ClientCompletion<Status>
    ) async throws -> SubscriptionToken
}
