//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSAppSync
import SudoLogging
import SudoApiClient
import SudoUser

class DefaultRelayService: RelayService {

    // MARK: - Properties

    /// Used to determine if the user is signed in and access the user owner ID.
    /// Unowned used since this should always outlive the lifetime of this class.
    private unowned let userClient: SudoUserClient

    /// Client used to interact with the GraphQL endpoint of the di relay.
    unowned var sudoApiClient: SudoApiClient

    /// Helper for the AppSync client.
    var appSyncClientHelper: AppSyncClientHelper

    /// Used to log diagnostic and error information.
    var logger: Logger

    /// Utility class to manage subscriptions.
    var subscriptionManager: SubscriptionManager = DefaultSubscriptionManager()

    // MARK: - Supplementary

    struct Constants {
        /// Cache policy when fetching  data.
        static let cachePolicy: CachePolicy = .fetchIgnoringCacheData
    }

    // MARK: - Lifecycle

    init(
         userClient: SudoUserClient,
         sudoApiClient: SudoApiClient,
         appSyncClientHelper: AppSyncClientHelper,
         logger: Logger = .relaySDKLogger
    ) {
        self.userClient = userClient
        self.sudoApiClient = sudoApiClient
        self.appSyncClientHelper = appSyncClientHelper
        self.logger = logger
    }

    // MARK: - Conformance: RelayService

    func listMessages(limit: Int? = nil, nextToken: String? = nil) async throws -> ListOutput<Message> {
        let query = ListRelayMessagesQuery(limit: limit, nextToken: nextToken)

        let data = try await GraphQLHelper.performQuery(graphQLClient: sudoApiClient, query: query, cachePolicy: Constants.cachePolicy, logger: logger)
        guard let messageList = data?.listRelayMessages else {
            throw SudoDIRelayError.requestFailed(response: nil, cause: nil)
        }
        return try RelayTransformer.transform(messageList)
    }

    func listPostboxes(limit: Int? = nil, nextToken: String? = nil) async throws -> ListOutput<Postbox> {
        let query = ListRelayPostboxesQuery(limit: limit, nextToken: nextToken)

        let data = try await GraphQLHelper.performQuery(graphQLClient: sudoApiClient, query: query, cachePolicy: Constants.cachePolicy, logger: logger)
        guard let postboxList = data?.listRelayPostboxes else {
            throw SudoDIRelayError.requestFailed(response: nil, cause: nil)
        }
        return try RelayTransformer.transform(postboxList)
    }

    func createPostbox(withConnectionId connectionId: String, ownershipProofToken: String, isEnabled: Bool? = true) async throws -> Postbox {
        let input = CreateRelayPostboxInput(ownershipProof: ownershipProofToken, connectionId: connectionId, isEnabled: isEnabled ?? true)
        let mutation = CreateRelayPostboxMutation(input: input)
        let data = try await GraphQLHelper.performMutation(graphQLClient: sudoApiClient, mutation: mutation, logger: logger)

        return try RelayTransformer.transform(data.createRelayPostbox)
    }

    func updatePostbox(withPostboxId postboxId: String, isEnabled: Bool?) async throws -> Postbox {
        let input = UpdateRelayPostboxInput(postboxId: postboxId, isEnabled: isEnabled)
        let mutation = UpdateRelayPostboxMutation(input: input)
        let data = try await GraphQLHelper.performMutation(graphQLClient: sudoApiClient, mutation: mutation, logger: logger)

        return try RelayTransformer.transform(data.updateRelayPostbox)
    }

    func deletePostbox(withPostboxId postboxId: String) async throws -> String {
        let input = DeleteRelayPostboxInput(postboxId: postboxId)
        let mutation = DeleteRelayPostboxMutation(input: input)
        _ = try await GraphQLHelper.performMutation(graphQLClient: sudoApiClient, mutation: mutation, logger: logger)

        return postboxId
    }

    func deleteMessage(withMessageId messageId: String) async throws -> String {
        let input = DeleteRelayMessageInput(messageId: messageId)
        let mutation = DeleteRelayMessageMutation(input: input)
        _ = try await GraphQLHelper.performMutation(graphQLClient: sudoApiClient, mutation: mutation, logger: logger)

        return messageId
    }

    @discardableResult func subscribeToMessageCreated(
            statusChangeHandler: SudoSubscriptionStatusChangeHandler?,
            resultHandler: @escaping ClientCompletion<Message>
    ) async throws -> SubscriptionToken? {
        guard let owner = try? userClient.getSubject() else {
            throw SudoDIRelayError.notSignedIn
        }
        let subscriptionId = UUID().uuidString
        let graphQlSubscription = OnRelayMessageCreatedSubscription(
                owner: owner
        )
        let subscriptionResultHandler = constructSubscriptionResultHandler(
                type: OnRelayMessageCreatedSubscription.self,
                transform: { graphQL in
                    guard let message = graphQL.onRelayMessageCreated else {
                        throw SudoDIRelayError.internalError(
                                "Invalid message object returned from subscription"
                        )
                    }
                    return try RelayTransformer.transform(message)
                },
                resultHandler: resultHandler
        )
        guard let subscriptionToken = await subscribe(
                withId: subscriptionId,
                subscription: graphQlSubscription,
                withStatusChangeHandler: statusChangeHandler,
                resultHandler: subscriptionResultHandler
        )
        else {
            throw SudoDIRelayError.internalError(
                    "No SubscriptionToken object returned from subscription"
            )
        }
        return subscriptionToken
    }

    func unsubscribeAll() {
        subscriptionManager.removeAllSubscriptions()
    }

    // MARK: - Helpers

    /// Subscribe to message creation events
    ///
    /// - Parameter subscriptionId: unique subscription identifier
    /// - Parameter subscription: graphql subscription type
    /// - Parameter statusChangeHandler: Connection status change.
    /// - Parameter resultHandler: Updated transaction event.
    /// - Returns: `Cancellable` object to cancel the subscription.
    func subscribe<S: GraphQLSubscription>(
            withId subscriptionId: String,
            subscription: S,
            withStatusChangeHandler statusChangeHandler: SudoSubscriptionStatusChangeHandler?,
            resultHandler: @escaping SubscriptionResultHandler<S>
    ) async -> RelaySubscriptionToken? {
        let discard = try? await sudoApiClient.subscribe(
                subscription: subscription,
                statusChangeHandler: { status in
                    let platformStatus = PlatformSubscriptionStatus(status: status)
                    statusChangeHandler?(platformStatus)
                },
                resultHandler: resultHandler
        )
        guard let cancellable = discard else {
            return nil
        }
        return RelaySubscriptionToken(id: subscriptionId, cancellable: cancellable, manager: subscriptionManager)
    }

    /// Construct the result handler for a subscription that returns a relay message object that can be transformed to `RelayMessage`.
    ///
    /// Transforms the graphQL data to a `Message` via the input `transform` function. If the result of `transform` is `nil`, then a log will be
    /// warned, but nothing else will happen. If the `transform` function throws an error, the resultant error will be returned via the `resultHandler`.
    /// - Parameters:
    ///   - type: Type of the subscription that the result handler is being constructed for.
    ///   - transform: Transformation function to transform the result data of the
    ///   - resultHandler: Result handler from the called method, inverted from the API layer via the core layer.
    /// - Returns: Subscription result handler to call the graphql appsync subscription with.
    func constructSubscriptionResultHandler<S: GraphQLSubscription, T>(
            type: S.Type,
            transform: @escaping (S.Data) throws -> T,
            resultHandler: @escaping ClientCompletion<T>
    ) -> SubscriptionResultHandler<S> {
        { [weak self] result, _, error in
            guard let weakSelf = self else {
                return
            }
            let graphQLResultWorker = GraphQLResultWorker()
            let result = graphQLResultWorker.convertToResult(result, error: error)
            switch result {
            case .success(let data):
                do {
                    let entity = try transform(data)
                    resultHandler(.success(entity))
                } catch {
                    weakSelf.logger.error(error.localizedDescription)
                    resultHandler(.failure(error))
                }
            case .failure(let error):
                weakSelf.logger.error(error.localizedDescription)
                resultHandler(.failure(error))
            }
        }
    }
}
