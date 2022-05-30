//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Transformer for GraphQL types to output results of the SDK.
struct RelayTransformer {

    /// Transform the GraphQL result from the `GetMessage` query to an array of `RelayMessage`s
    static func transform(_ result: [GetMessagesQuery.Data.GetMessage?]) throws -> [RelayMessage] {
        let nonNilResults: [GetMessagesQuery.Data.GetMessage] = result.compactMap { $0 }
        return try transform(nonNilResults)
    }

    /// Transform the GraphQL result from the `StoreMessage` mutation to an optional `RelayMessage`
    /// - Throws: `SudoDIRelayError`
    static func transform(_ result: StoreMessageMutation.Data.StoreMessage?) throws -> RelayMessage? {
        guard let result = result else {
            return nil
        }
        return try transform(result)
    }

    /// Transform the GraphQL result from the `OnMessageCreated` subscription to a `RelayMessage` object.
    /// Throws: `SudoDIRelayError`
    static func transform(_ result: OnMessageCreatedSubscription.Data.OnMessageCreated) throws -> RelayMessage {
        return RelayMessage(
            messageId: result.messageId,
            connectionId: result.connectionId,
            cipherText: result.cipherText,
            direction: try transform(result.direction),
            timestamp: transform(timestamp: result.utcTimestamp)
        )
    }

    /// Transform the GraphQL result from the `listPostboxes` query to an array of `Postbox`s.
    static func transform(_ items: [ListPostboxesForSudoIdQuery.Data.ListPostboxesForSudoId?]) -> [Postbox] {
        let nonNilResults: [ListPostboxesForSudoIdQuery.Data.ListPostboxesForSudoId] = items.compactMap { $0 }

        return transform(nonNilResults)
    }

    /// Transform a `Status` returned from the service into `Status.ok`.
    /// Note that non-ok statuses are not implemented  in the service yet.
    static func transform(_ result: OnPostBoxDeletedSubscription.Data.OnPostBoxDeleted) -> Status {
        return Status.ok
    }

    /// Transform a GraphQL `Direction` into a `RelayMessage.Direction`.
    /// - Throws: `SudoDIRelayError`
    static func transform(_ graphQL: Direction) throws -> RelayMessage.Direction {
        switch graphQL {
        case .inbound:
            return .inbound
        case .outbound:
            return .outbound
        case let .unknown(direction):
            throw SudoDIRelayError.internalError("Unsupported relay message direction: \(direction)")
        }
    }

    /// Transform a `timestamp` formatted as E, d MMM yyyy HH:mm:ss zzz into a `Date` object.
    /// - Parameter timestamp: A timestamp from the relay.
    /// - Returns: `Date` representation of the timestamp
    static func transform(timestamp: Double) -> Date {
        return Date(millisecondsSince1970: timestamp)
    }

    // MARK: - Helpers

    /// Transform the GraphQL result from the `GetMessage` query to an array of `RelayMessage`s.
    /// - Throws: `SudoDIRelayError`
    private static func transform(_ items: [GetMessagesQuery.Data.GetMessage]) throws -> [RelayMessage] {
        do {
        let transformedMessages = try items.map {
            RelayMessage(
                messageId: $0.messageId,
                connectionId: $0.connectionId,
                cipherText: $0.cipherText,
                direction: try transform($0.direction),
                timestamp: transform(timestamp: $0.utcTimestamp)
            )
        }
        return transformedMessages.sorted(by: { $0.timestamp < $1.timestamp })
        } catch let error as SudoDIRelayError {
          throw error
        } catch {
          // Wrap all other errors as a SudoDIRelayError
          throw SudoDIRelayError.decodingError
        }

    }

    /// Transform the GraphQL result from the `StoreMessage` mutation to an `ArrayMessage`
    /// - Throws: `SudoDIRelayError`
    private static func transform(_ items: StoreMessageMutation.Data.StoreMessage) throws -> RelayMessage {
        return RelayMessage(
            messageId: items.messageId,
            connectionId: items.connectionId,
            cipherText: items.cipherText,
            direction: try transform(items.direction),
            timestamp: transform(timestamp: items.utcTimestamp)
        )
    }

    /// Transform the GraphQL result from the `listPostboxes` query to an array of `Postbox`s.
    private static func transform(_ items: [ListPostboxesForSudoIdQuery.Data.ListPostboxesForSudoId]) -> [Postbox] {
        let postboxes = items.map {
            Postbox(connectionId: $0.connectionId, userId: $0.owner, sudoId: $0.sudoId, timestamp: transform(timestamp: $0.utcTimestamp))
        }
        return postboxes.sorted(by: {$0.timestamp < $1.timestamp })
    }
}
