//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSAppSync
import SudoLogging

// Registers a federated ID in the identity pool and binds it to the user.
class RegisterFederatedId: UserOperation {

    private unowned let apiClient: AWSAppSyncClient

    private let idToken: String

    /// Initializes and returns a `RegisterFederatedId` operation.
    ///
    /// - Parameters:
    ///   - apiClient: GraphQL client used for calling Identity Service API.
    ///   - idToken: ID token used to perform the federated sign in.
    ///   - logger: Logger used for logging.
    init(apiClient: AWSAppSyncClient,
         idToken: String,
         logger: Logger = Logger.sudoUserLogger) {
        self.apiClient = apiClient
        self.idToken = idToken
        super.init(logger: logger)
    }

    override func execute() {
        let input = RegisterFederatedIdInput(idToken: self.idToken)
        self.apiClient.perform(mutation: RegisterFederatedIdMutation(input: input), queue: self.queue, resultHandler: { (result, error) in
            defer {
                self.done()
            }

            if let error = error as? AWSAppSyncClientError {
                self.error = GraphQLClientError.graphQLError(cause: [error])
            } else {
                if let errors = result?.errors {
                    self.error = GraphQLClientError.graphQLError(cause: errors)
                }
            }
        })
    }

}
