//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Transformer for GraphQL types to output results of the SDK.
struct RelayTransformer {
    struct Constants {
        /// Issuer of sudos
        static let sudoServiceOwnerIssuer: String = "sudoplatform.sudoservice"
    }

    /// Transform the GraphQL result from the `ListRelayMessages` query to a ListOutput of Messages
    static func transform(_ result: ListRelayMessagesQuery.Data.ListRelayMessage) throws -> ListOutput<Message> {
        do {
            let transformedMessages = try result.items.map { (graphQlMessage) -> Message in
                guard let sudoOwner = graphQlMessage.owners.first(where: {$0.issuer == Constants.sudoServiceOwnerIssuer}) else {
                    throw SudoDIRelayError.invalidMessage
                }
                return Message(
                        id: graphQlMessage.id,
                        createdAt: transform(timestamp: graphQlMessage.createdAtEpochMs),
                        updatedAt: transform(timestamp: graphQlMessage.updatedAtEpochMs),
                        ownerId: graphQlMessage.owner,
                        sudoId: sudoOwner.id,
                        postboxId: graphQlMessage.postboxId,
                        message: graphQlMessage.message
                )
            }
            return ListOutput<Message>(items: transformedMessages, nextToken: result.nextToken)
        } catch let error as SudoDIRelayError {
            throw error
        } catch {
            // Wrap all other errors as a SudoDIRelayError
            throw SudoDIRelayError.decodingError
        }
    }

    /// Transform the GraphQL result from the `OnRelayMessageCreated` subscription to a `Message` object.
    /// Throws: `SudoDIRelayError`
    static func transform(_ result: OnRelayMessageCreatedSubscription.Data.OnRelayMessageCreated) throws -> Message {
        guard let sudoOwner = result.owners.first(where: {$0.issuer == Constants.sudoServiceOwnerIssuer}) else {
            throw SudoDIRelayError.invalidMessage
        }
        return Message(
                id: result.id,
                createdAt: transform(timestamp: result.createdAtEpochMs),
                updatedAt: transform(timestamp: result.updatedAtEpochMs),
                ownerId: result.owner,
                sudoId: sudoOwner.id,
                postboxId: result.postboxId,
                message: result.message
        )
    }

    /// Transform the GraphQL result from the `DeleteRelayMessage` query to the deleted id string
    static func transform(_ result: DeleteRelayMessageMutation.Data.DeleteRelayMessage) throws -> String {
        return result.id
    }

    /// Transform the GraphQL result from the `ListRelayPostboxes` query to a ListOutput of Postboxes
    /// Throws: `SudoDIRelayError`
    static func transform(_ result: ListRelayPostboxesQuery.Data.ListRelayPostbox) throws -> ListOutput<Postbox> {
        do {
            let transformedPostboxes = try result.items.map { (graphQlPostbox) -> Postbox in
                guard let sudoOwner = graphQlPostbox.owners.first(where: {$0.issuer == Constants.sudoServiceOwnerIssuer}) else {
                    throw SudoDIRelayError.invalidPostbox
                }
                return Postbox(
                        id: graphQlPostbox.id,
                        createdAt: transform(timestamp: graphQlPostbox.createdAtEpochMs),
                        updatedAt: transform(timestamp: graphQlPostbox.updatedAtEpochMs),
                        ownerId: graphQlPostbox.owner,
                        sudoId: sudoOwner.id,
                        connectionId: graphQlPostbox.connectionId,
                        isEnabled: graphQlPostbox.isEnabled,
                        serviceEndpoint: graphQlPostbox.serviceEndpoint
                )
            }
            return ListOutput<Postbox>(items: transformedPostboxes, nextToken: result.nextToken)
        } catch let error as SudoDIRelayError {
            throw error
        } catch {
            // Wrap all other errors as a SudoDIRelayError
            throw SudoDIRelayError.decodingError
        }
    }

    /// Transform the GraphQL result from the `DeleteRelayPostbox` query to the deleted id string
    static func transform(_ result: DeleteRelayPostboxMutation.Data.DeleteRelayPostbox) throws -> String {
        return result.id
    }

    /// Transform the GraphQL result from the `CreateRelayPostbox` mutation to a `Postbox` object.
    /// Throws: `SudoDIRelayError`
    static func transform(_ postbox: CreateRelayPostboxMutation.Data.CreateRelayPostbox) throws -> Postbox {
        guard let sudoOwner = postbox.owners.first(where: {$0.issuer == Constants.sudoServiceOwnerIssuer}) else {
            throw SudoDIRelayError.invalidPostbox
        }
        return Postbox(
                id: postbox.id,
                createdAt: transform(timestamp: postbox.createdAtEpochMs),
                updatedAt: transform(timestamp: postbox.updatedAtEpochMs),
                ownerId: postbox.owner,
                sudoId: sudoOwner.id,
                connectionId: postbox.connectionId,
                isEnabled: postbox.isEnabled,
                serviceEndpoint: postbox.serviceEndpoint
        )
    }

    /// Transform the GraphQL result from the `UpdateRelayPostbox` mutation to a `Postbox` object.
    /// Throws: `SudoDIRelayError`
    static func transform(_ postbox: UpdateRelayPostboxMutation.Data.UpdateRelayPostbox) throws -> Postbox {
        guard let sudoOwner = postbox.owners.first(where: {$0.issuer == Constants.sudoServiceOwnerIssuer}) else {
            throw SudoDIRelayError.invalidPostbox
        }
        return Postbox(
                id: postbox.id,
                createdAt: transform(timestamp: postbox.createdAtEpochMs),
                updatedAt: transform(timestamp: postbox.updatedAtEpochMs),
                ownerId: postbox.owner,
                sudoId: sudoOwner.id,
                connectionId: postbox.connectionId,
                isEnabled: postbox.isEnabled,
                serviceEndpoint: postbox.serviceEndpoint
        )
    }

    /// Transform a `timestamp` formatted as E, d MMM yyyy HH:mm:ss zzz into a `Date` object.
    /// - Parameter timestamp: A timestamp from the relay.
    /// - Returns: `Date` representation of the timestamp
    static func transform(timestamp: Double) -> Date {
        Date(millisecondsSince1970: timestamp)
    }

    // MARK: - Helpers
}
