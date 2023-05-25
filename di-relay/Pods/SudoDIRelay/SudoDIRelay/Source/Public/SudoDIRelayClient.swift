//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SudoLogging

/// Generic type associated with API completion/closures. Generic type O is the expected output result in a success case.
public typealias ClientCompletion<O> = (Swift.Result<O, Error>) -> Void

/// Generic type associated with Subscription Status change completion/closures.
public typealias SudoSubscriptionStatusChangeHandler = (PlatformSubscriptionStatus) -> Void

/// Client used to interface with the Sudo Relay Platform service.
///
/// It is recommended to code to this interface, rather than the implementation class (`DefaultSudoDIRelayClient`) as
/// the implementation class is only meant to be used for initializing an instance of the client.
public protocol SudoDIRelayClient: AnyObject {

    // MARK: - Lifecycle

    /// Clear all locally cached apppsync data
    /// - Throws: ClearCacheError
    func reset() throws

    // MARK: - Queries

    /// Get a list of postboxes associated with the current user, ordered from oldest to newest.
    /// - Parameters:
    ///   - limit: The maximum number of postboxes to return from this query; if not supplied the service will determine an appropriate limit.
    ///   - nextToken: If more than `limit` postboxes are available, pass the value returned in a previous response to allow pagination.
    /// - Returns:
    ///   - Success: The list of postboxes.
    ///   - Failure: `SudoDIRelayError`
    func listPostboxes(limit: Int?, nextToken: String?) async throws -> ListOutput<Postbox>

    /// Get all messages from all postboxes associated with the current user, ordered from oldest to newest.
    /// - Parameters:
    ///   - limit: The maximum number of messages to return from this query; if not supplied the service will determine an appropriate limit.
    ///   - nextToken: If more than `limit` messages are available, pass the value returned in a previous response to allow pagination.
    /// - Returns:
    ///   - Success: The list of messages.
    ///   - Failure: `SudoDIRelayError`
    func listMessages(limit: Int?, nextToken: String?) async throws -> ListOutput<Message>

    // MARK: - Mutations

    /// Creates a Postbox associated with the given connection identifier.
    /// - Parameters:
    ///   - connectionId: The connection id, unique to the current sudo, with which to associate the postbox.
    ///   - ownershipProofToken: A token identifying the current sudo and its authorization to create a postbox.
    ///   - isEnabled: Whether the postbox should be created in an enabled state. If not supplied, the default is true.
    /// - Returns:
    ///   - Success:  The newly created postbox.
    ///   - Failure: `SudoDIRelayError`
    func createPostbox(withConnectionId connectionId: String, ownershipProofToken: String, isEnabled: Bool?) async throws -> Postbox

    /// Updates the Postbox associated with the given identifier.
    /// - Parameters:
    ///   - postboxId: The postbox id of the postbox to be updated.
    ///   - isEnabled: The new setting for the postbox isEnabled flag. If not supplied, no change will be made to the postbox setting.
    /// - Returns:
    ///   - Success:  The updated postbox.
    ///   - Failure: `SudoDIRelayError`
    func updatePostbox(withPostboxId postboxId: String, isEnabled: Bool?) async throws -> Postbox

    /// Deletes the postbox associated with the given postbox identifier, including all messages stored inside that postbox.
    /// - Parameters:
    ///   - postboxId: The identifier of the postbox to be deleted.
    /// - Returns:
    ///   - Success: identifier of deleted postbox
    ///   - Failure: `SudoDIRelayError`
    func deletePostbox(withPostboxId postboxId: String) async throws -> String

    /// Deletes the message associated with the given message identifier
    /// - Parameters:
    ///   - messageId: The identifier of the message to be deleted.
    /// - Returns:
    ///   - Success: identifier of deleted message
    ///   - Failure: `SudoDIRelayError`
    func deleteMessage(withMessageId messageId: String) async throws -> String

    // MARK: - Subscriptions

    /// Subscribe to message creation events for the current user. Subscription events will be delivered as long as the
    /// returned  token remains in scope and the connection status remains .connected.
    ///
    /// - Parameter statusChangeHandler: Optional handler for connection status change.
    /// - Parameter resultHandler: On success, the created message; on failure an error.
    ///
    /// - Returns: `SubscriptionToken` object to allow management of the subscription.
    func subscribeToMessageCreated(
            statusChangeHandler: SudoSubscriptionStatusChangeHandler?,
            resultHandler: @escaping ClientCompletion<Message>
    ) async throws -> SubscriptionToken?

    /// Unsubscribe from all subscriptions
    func unsubscribeAll()
}
