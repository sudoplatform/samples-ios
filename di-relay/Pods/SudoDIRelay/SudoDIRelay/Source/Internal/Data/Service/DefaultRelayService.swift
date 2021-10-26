//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSAppSync
import SudoLogging
import SudoOperations

class DefaultRelayService: RelayService {

    // MARK: - Properties

    /// App sync client for peforming operations against the relay service.
    var appSyncClient: AWSAppSyncClient

    /// Used to log diagnostic and error information.
    var logger: Logger

    /// Utility factory class to generate mutation and query operations.
    var operationFactory: OperationFactory = OperationFactory()

    /// Operation queue for enqueuing asynchronous tasks.
    var queue = PlatformOperationQueue()

    /// Utility class to manage subscriptions.
    var subscriptionManager: SubscriptionManager = DefaultSubscriptionManager()

    // MARK: - Lifecycle

    init(appSyncClient: AWSAppSyncClient, logger: Logger = .relaySDKLogger) {
        self.appSyncClient = appSyncClient
        self.logger = logger
    }

    // MARK: - Methods

    func reset() {
        queue.cancelAllOperations()
    }

    // MARK: - Conformance: RelayService

    func getMessages(withConnectionId connectionId: String, completion: @escaping ClientCompletion<[RelayMessage]>) {
        let input = IdAsInput(id: connectionId)
        let query = GetMessagesQuery(input: input)
        let operation = operationFactory.generateQueryOperation(query: query, appSyncClient: appSyncClient, logger: logger)
        let completionObserver = PlatformBlockObserver(finishHandler: { [weak self, unowned operation] _, errors in
            if let error = errors.first {
                completion(.failure(error))
                return
            }
            guard let graphQLResult = operation.result?.getMessages else {
                completion(.failure(SudoDIRelayError.serviceError))
                return
            }
            do {
                var result = try RelayTransformer.transform(graphQLResult)
                result.sort { $0.timestamp > $1.timestamp }
                completion(.success(result))
            } catch let error {
                self?.logger.error(error.localizedDescription)
                completion(.failure(error))
                return
            }
        })
        operation.addObserver(completionObserver)
        queue.addOperation(operation)
    }

    func createPostbox(withConnectionId connectionId: String, completion: @escaping ClientCompletion<Void>) {
        let input = createWriteToRelayInput(
            messageId: "init",
            connectionId: connectionId,
            cipherText: "",
            direction: Direction.inbound
        )
        let mutation = SendInitMutation(input: input)
        let operation = operationFactory.generateMutationOperation(mutation: mutation, appSyncClient: appSyncClient, logger: logger)
        let completionObserver = PlatformBlockObserver(finishHandler: { [weak self, unowned operation] _, errors in
            if let error = errors.first {
                self?.logger.error(error.localizedDescription)
                completion(.failure(SudoDIRelayError.invalidInitMessage))
                return
            }

            guard operation.result?.sendInit != nil else {
                completion(.failure(SudoDIRelayError.serviceError))
                return
            }
            completion(.success(()))
        })
        operation.addObserver(completionObserver)
        queue.addOperation(operation)
    }

    func storeMessage(withConnectionId connectionId: String, message: String, completion: @escaping ClientCompletion<RelayMessage?>) {
        let input = createWriteToRelayInput(
            messageId: UUID().uuidString,
            connectionId: connectionId,
            cipherText: message,
            direction: Direction.outbound)
        let mutation = StoreMessageMutation(input: input
        )
        let operation = operationFactory.generateMutationOperation(mutation: mutation, appSyncClient: appSyncClient, logger: logger)
        let completionObserver = PlatformBlockObserver(finishHandler: { [weak self, unowned operation] _, errors in
            if let error = errors.first {
                completion(.failure(error))
                return
            }
            guard let graphQLResult = operation.result?.storeMessage else {
                completion(.failure(SudoDIRelayError.serviceError))
                return
            }
            do {
                let result = try RelayTransformer.transform(graphQLResult)
                completion(.success(result))
            } catch let error {
                self?.logger.error(error.localizedDescription)
                completion(.failure(SudoDIRelayError.serviceError))
            }
        })
        operation.addObserver(completionObserver)
        queue.addOperation(operation)
    }

    func deletePostbox(withConnectionId connectionId: String, completion: @escaping ClientCompletion<Void>) {
        let input = IdAsInput(id: connectionId)
        let mutation = DeletePostBoxMutation(input: input)
        let operation = operationFactory.generateMutationOperation(mutation: mutation, appSyncClient: appSyncClient, logger: logger)
        let completionObserver = PlatformBlockObserver(finishHandler: { _, errors in
            if let error = errors.first {
                completion(.failure(error))
                return
            }
            guard operation.result?.deletePostBox != nil else {
                completion(.failure(SudoDIRelayError.serviceError))
                return
            }
            completion(.success(()))
        })
        operation.addObserver(completionObserver)
        queue.addOperation(operation)
    }

    func subscribeToMessagesReceived(
        withConnectionId connectionId: String,
        resultHandler: @escaping ClientCompletion<RelayMessage>
    ) throws -> SubscriptionToken {
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
        return try subscribeWithId(
            subscriptionId,
            subscription: onMessageCreatedGraphQlSubscription,
            statusChangeHandler: subscriptionStatusChangeHandler,
            resultHandler: subscriptionResultHandler
        )
    }

    func subscribeToPostboxDeleted(
        withConnectionId connectionId: String,
        resultHandler: @escaping ClientCompletion<Status>
    ) throws -> SubscriptionToken {
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
        return try subscribeWithId(
            subscriptionId,
            subscription: onMessageCreatedGraphQlSubscription,
            statusChangeHandler: subscriptionStatusChangeHandler,
            resultHandler: subscriptionResultHandler
        )
    }

    // MARK: - Helpers

    func subscribeWithId<S: GraphQLSubscription>(
        _ subscriptionId: String,
        subscription: S,
        statusChangeHandler: @escaping SubscriptionStatusChangeHandler,
        resultHandler: @escaping SubscriptionResultHandler<S>
    ) throws -> SubscriptionToken {
        do {
            let optionalCancellable = try appSyncClient.subscribe(
                subscription: subscription,
                statusChangeHandler: statusChangeHandler,
                resultHandler: resultHandler
            )
            guard let cancellable = optionalCancellable else {
                throw SudoDIRelayError.internalError(
                    "No Cancellable object returned from subscription"
                )
            }
            return RelaySubscriptionToken(id: subscriptionId, cancellable: cancellable, manager: subscriptionManager)
        } catch {
            throw SudoDIRelayError.internalError(error.localizedDescription)
        }
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
    ) -> SubscriptionStatusChangeHandler {
        return { [weak self] status in
            switch status {
            case .error(let cause):
                let error = SudoDIRelayError.internalError(cause.errorDescription)
                resultHandler(.failure(error))
            case .disconnected:
                self?.subscriptionManager.removeSubscription(withId: subscriptionId)
            default:
                break
            }
        }
    }

    /// Construct a WriteToRelayInput
    func createWriteToRelayInput(messageId: String, connectionId: String, cipherText: String, direction: Direction) -> WriteToRelayInput {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E, d MMM yyyy HH:mm:ss zzz"
        let timestamp = dateFormatter.string(from: Date())
        return WriteToRelayInput(
            messageId: messageId,
            connectionId: connectionId,
            cipherText: cipherText,
            direction: direction,
            utcTimestamp: timestamp
        )
    }
}
