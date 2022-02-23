//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SudoLogging

/// Generic type associated with API completion/closures. Generic type O is the expected output result in a success case.
public typealias ClientCompletion<O> = (Swift.Result<O, Error>) -> Void

/// Client used to interface with the Sudo Relay Platform service.
///
/// It is recommended to code to this interface, rather than the implementation class (`DefaultSudoDIRelayClient`) as
/// the implementation class is only meant to be used for initializing an instance of the client.
public protocol SudoDIRelayClient: AnyObject {

    // MARK: - Lifecycle

    /// Clear all locally cached data
    func reset() throws

    // MARK: - Queries

    /// Get all messages from the Postbox associated with the given connection identifier.
    /// - Returns:
    ///   - Success: The list of messages the given connection.
    ///   - Failure: `SudoDIRelayError`
    func getMessages(withConnectionId connectionId: String, completion: @escaping ClientCompletion<[RelayMessage]>)

    // MARK: - Mutations

    /// Stores a message the Postbox associated with the given connection identifier.
    /// - Returns:
    ///   - Success: The stored message.
    ///   - Failure: `SudoDIRelayError`
    func storeMessage(withConnectionId connectionId: String, message: String, completion: @escaping ClientCompletion<RelayMessage?>)

    /// Creates a Postbox associated with the given connection identifier.
    /// - Returns:
    ///   - Success:  Void is returned on a success result.
    ///   - Failure: `SudoDIRelayError`
    func createPostbox(withConnectionId connectionId: String, completion: @escaping ClientCompletion<Void>)

    /// Deletes the Postbox associated with the given connection identifier, including all messages stored inside that Postbox.
    /// - Returns:
    ///   - Success: Void is returned on a success result.
    ///   - Failure: `SudoDIRelayError`
    func deletePostbox(withConnectionId connectionId: String, completion: @escaping ClientCompletion<Void>)

    // MARK: - Subscriptions

    /// Subscribe to messages inbound to the Postbox associated with the connection identifier.
    /// - Returns:
    ///   - Success:  The relay message.
    ///   - Failure: `SudoDIRelayError`
    func subscribeToMessagesReceived(withConnectionId connectionId: String, resultHandler: @escaping ClientCompletion<RelayMessage>) -> SubscriptionToken?

    /// Subscribe to a Postbox deletion.
    /// Subscribe to messages inbound to the Postbox associated with the connection identifier.
    /// - Returns:
    ///   - Success:  nil
    ///   - Failure: `SudoDIRelayError`
    func subscribeToPostboxDeleted(withConnectionId connectionId: String, resultHandler: @escaping ClientCompletion<Status>) -> SubscriptionToken?

    // MARK: - Helpers

    /// Get HTTP endpoint of the provided postbox.
    /// - Returns: Postbox HTTP endpoint on success, or nil on failure
    func getPostboxEndpoint(withConnectionId connectionId: String) -> URL?
}
