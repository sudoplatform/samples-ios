//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
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

    /// Client used to interact with the GraphQL endpoint of the virtual cards service.
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
        static let cachePolicy: CachePolicy = .remoteOnly
    }

    // MARK: - Lifecycle

    init(
        sudoApiClient: SudoApiClient,
        appSyncClientHelper: AppSyncClientHelper,
        logger: Logger = .relaySDKLogger
    ) {
        self.sudoApiClient = sudoApiClient
        self.appSyncClientHelper = appSyncClientHelper
        self.logger = logger
    }

    // MARK: - Conformance: RelayService

    func listMessages(withConnectionId connectionId: String) async throws -> [RelayMessage] {
        let input = IdAsInput(connectionId: connectionId)
        let query = GetMessagesQuery(input: input)

        let data = try await GraphQLHelper.performQuery(graphQLClient: sudoApiClient, query: query, cachePolicy: Constants.cachePolicy, logger: logger)
        guard let messageList = data?.getMessages else {
            return []
        }
        return try RelayTransformer.transform(messageList)
    }

    func createPostbox(withConnectionId connectionId: String, ownershipProofToken: String) async throws {
        let input = CreatePostboxInput(connectionId: connectionId, ownershipProofTokens: [ownershipProofToken])
        let mutation = SendInitMutation(input: input)
        _ = try await GraphQLHelper.performMutation(graphQLClient: sudoApiClient, mutation: mutation, logger: logger)
    }

    func storeMessage(withConnectionId connectionId: String, message: String) async throws -> RelayMessage? {
        let input = createWriteToRelayInput(
            messageId: UUID().uuidString,
            connectionId: connectionId,
            cipherText: message,
            direction: Direction.outbound)
        let mutation = StoreMessageMutation(input: input)
        let data = try await GraphQLHelper.performMutation(graphQLClient: sudoApiClient, mutation: mutation, logger: logger)
        return try RelayTransformer.transform(data.storeMessage)
    }

    func deletePostbox(withConnectionId connectionId: String) async throws {
        let input = IdAsInput(connectionId: connectionId)
        let mutation = DeletePostBoxMutation(input: input)
        _ = try await GraphQLHelper.performMutation(graphQLClient: sudoApiClient, mutation: mutation, logger: logger)
    }

    func subscribeToMessagesReceived(
        withConnectionId connectionId: String,
        resultHandler: @escaping ClientCompletion<RelayMessage>
    ) async throws -> SubscriptionToken {
        let subscriptionId = UUID().uuidString
        let onMessageCreatedGraphQlSubscription = OnMessageCreatedSubscription(
            connectionId: connectionId,
            direction: Direction.inbound
        )
        let subscriptionStatusChangeHandler = constructStatusChangeHandlerWithSubscriptionId(
            subscriptionId,
            resultHandler: resultHandler
        )
        let subscriptionResultHandler = constructSubscriptionResultHandler(
            type: OnMessageCreatedSubscription.self,
            transform: { graphQL in
                guard let message = graphQL.onMessageCreated else {
                    return nil
                }
                return try RelayTransformer.transform(message)
            },
            resultHandler: resultHandler
        )
        guard let subscriptionToken = await subscribe(
            withId: subscriptionId,
            subscription: onMessageCreatedGraphQlSubscription,
            withStatusChangeHandler: subscriptionStatusChangeHandler,
            resultHandler: subscriptionResultHandler
        ) else {
            throw SudoDIRelayError.internalError(
                "No SubscriptionToken object returned from subscription"
            )
        }
        return subscriptionToken
    }

    func subscribeToPostboxDeleted(
        withConnectionId connectionId: String,
        resultHandler: @escaping ClientCompletion<Status>
    ) async throws -> SubscriptionToken {
        let subscriptionId = UUID().uuidString
        let onMessageCreatedGraphQlSubscription = OnPostBoxDeletedSubscription(connectionId: connectionId)
        let subscriptionStatusChangeHandler = constructStatusChangeHandlerWithSubscriptionId(
            subscriptionId,
            resultHandler: resultHandler
        )
        let subscriptionResultHandler = constructSubscriptionResultHandler(
            type: OnPostBoxDeletedSubscription.self,
            transform: { graphQL in
                guard let status = graphQL.onPostBoxDeleted else {
                    return nil
                }
                return RelayTransformer.transform(status)
            },
            resultHandler: resultHandler
        )
        guard let subscriptionToken = await subscribe(
            withId: subscriptionId,
            subscription: onMessageCreatedGraphQlSubscription,
            withStatusChangeHandler: subscriptionStatusChangeHandler,
            resultHandler: subscriptionResultHandler
        ) else {
            throw SudoDIRelayError.internalError(
                "No SubscriptionToken object returned from subscription"
            )
        }
        return subscriptionToken
    }

    func getPostboxEndpoint(withConnectionId connectionId: String) -> URL? {
        return URL(string: appSyncClientHelper.getHttpEndpoint() + "/" + connectionId)
    }

    func listPostboxes(withSudoId sudoId: String) async throws -> [Postbox] {
        let input = ListPostboxesForSudoIdInput(sudoId: sudoId)
        let query = ListPostboxesForSudoIdQuery(input: input)

        let data = try await GraphQLHelper.performQuery(graphQLClient: sudoApiClient, query: query, cachePolicy: Constants.cachePolicy, logger: logger)
        guard let postboxes = data?.listPostboxesForSudoId else {
            throw SudoDIRelayError.serviceError
        }
        return RelayTransformer.transform(postboxes)
    }

    // MARK: - Helpers

    /// Subscribe to transaction update events. This includes creation of new transactions.
    ///
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
    /// Transforms the graphQL data to a `RelayMessage` via the input `transform` function. If the result of `transform` is `nil`, then a log will be
    /// warned, but nothing else will happen. If the `transform` function throws an error, the resultant error will be returned via the `resultHandler`.
    /// - Parameters:
    ///   - type: Type of the subscription that the result handler is being constructed for.
    ///   - transform: Transformation function to transform the result data of the
    ///   - resultHandler: Result handler from the called method, inverted from the API layer via the core layer.
    /// - Returns: Subscription result handler to call the graphql appsync subscription with.
    func constructSubscriptionResultHandler<S: GraphQLSubscription, T>(
        type: S.Type,
        transform: @escaping (S.Data) throws -> T?,
        resultHandler: @escaping ClientCompletion<T>
    ) -> SubscriptionResultHandler<S> {
        return { [weak self] result, _, error in
            guard let weakSelf = self else { return }
            let graphQLResultWorker = GraphQLResultWorker()
            let result = graphQLResultWorker.convertToResult(result, error: error)
            switch result {
            case .success(let data):
                do {
                    guard let entity = try transform(data) else {
                        weakSelf.logger.warning("Relay subscription received with no data")
                        return
                    }
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

    /// Construct the status change handler for a subscription.
    /// - Parameters:
    ///   - subscriptionId: Identifier of the subscription.
    ///   - resultHandler: Result handler of the
    /// - Returns: Result handler from the called method, inverted from the API layer via the core layer.
    func constructStatusChangeHandlerWithSubscriptionId<T>(
        _ subscriptionId: String,
        resultHandler: @escaping ClientCompletion<T>
    ) -> SudoSubscriptionStatusChangeHandler {
        return { [weak self] status in
            switch status {
            case let .error(cause):
                if let err = cause as? GraphQLError {
                    let error = SudoDIRelayError(graphQLError: err)
                    resultHandler(.failure(error))
                    return
                }
                let err = SudoDIRelayError.internalError(String(reflecting: cause))
                resultHandler(.failure(err))
            case .disconnected:
                self?.subscriptionManager.removeSubscription(withId: subscriptionId)
            default:
                break
            }
        }
    }

    /// Construct a WriteToRelayInput
    func createWriteToRelayInput(messageId: String, connectionId: String, cipherText: String, direction: Direction) -> WriteToRelayInput {
        let timestamp = Date().millisecondsSince1970.rounded()
        return WriteToRelayInput(
            messageId: messageId,
            connectionId: connectionId,
            cipherText: cipherText,
            direction: direction,
            utcTimestamp: timestamp
        )
    }
}
