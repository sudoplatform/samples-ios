//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol RelayService: AnyObject {

    // MARK: - Queries

    /// Get all messages from all postboxes associated with the current user.
    /// - Returns:
    ///   - Success: The list of messages.
    ///   - Failure: `SudoDIRelayError`
    func listMessages(limit: Int?, nextToken: String?) async throws -> ListOutput<Message>

    /// Get a list of postboxes associated with the current user
    /// - Returns:
    ///   - Success: The list of postboxes.
    ///   - Failure: `SudoDIRelayError`
    func listPostboxes(limit: Int?, nextToken: String?) async throws -> ListOutput<Postbox>

    // MARK: - Mutations

    /// Creates a Postbox associated with the given connection identifier.
    /// - Parameters:
    ///   - connectionId: The connection id, unique to the current sudo, with which to associate the postbox.
    ///   - ownershipProofToken: A token identifying the current sudo and its authorization to create a postbox.
    ///   - isEnabled: Whether the postbox should be created in an enabled state. If not supplied, the default is true.
    /// - Returns:
    ///   - Success:  Newly created Postbox.
    ///   - Failure: `SudoDIRelayError`
    func createPostbox(withConnectionId connectionId: String, ownershipProofToken: String, isEnabled: Bool?) async throws -> Postbox

    /// Updates the Postbox associated with the given postbox identifier,
    /// with the provided isEnabled value, if any.
    /// - Parameters:
    ///   - postboxId: The postbox id of the postbox to be updated.
    ///   - isEnabled: The new setting for the postbox isEnabled flag. If not supplied, no change will be made to the postbox setting. 
    /// - Returns:
    ///   - Success: newly updated Postbox
    ///   - Failure: `SudoDIRelayError`
    func updatePostbox(withPostboxId postboxId: String, isEnabled: Bool?) async throws -> Postbox

    /// Deletes the Postbox associated with the given postbox identifier,
    /// including all messages stored inside that Postbox.
    /// - Parameters:
    ///   - postboxId: The identifier of the postbox to be deleted.
    /// - Returns:
    ///   - Success: identifier of deleted postbox
    ///   - Failure: `SudoDIRelayError`
    func deletePostbox(withPostboxId postboxId: String) async throws -> String

    /// Deletes the Message associated with the given message identifier.
    /// - Parameters:
    ///   - messageId: The identifier of the message to be deleted.
    /// - Returns:
    ///   - Success: identifier of deleted message
    ///   - Failure: `SudoDIRelayError`
    func deleteMessage(withMessageId messageId: String) async throws -> String

    /// Subscribe to messages received to all postboxes for the current user.
    /// - Parameters:
    ///   - statusChangeHandler: Connection status change.
    ///   - resultHandler: Returns the `RelayMessage` on success, or `Error` on failure.
    /// - Returns: Token to manage subscription.
    /// - Throws: `SudoDIRelayError`
    func subscribeToMessageCreated(
            statusChangeHandler: SudoSubscriptionStatusChangeHandler?,
            resultHandler: @escaping ClientCompletion<Message>
    ) async throws -> SubscriptionToken?

    /// Unsubscribe from all relay subscriptions
    func unsubscribeAll()
}
