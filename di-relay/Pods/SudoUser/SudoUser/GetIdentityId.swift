//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoLogging

// Operation to retrieve the identity ID associated with the user.
class GetIdentityId: UserOperation {

    private unowned let credentialsProvider: CredentialsProvider

    /// Initializes and returns a `GetIdentityId` operation.
    ///
    /// - Parameters:
    ///   - credentialsProvider: Credentials provider to use for retrieving the identity ID from the identity pool.
    ///   - logger: Logger used for logging.
    init(credentialsProvider: CredentialsProvider,
         logger: Logger = Logger.sudoUserLogger) {
        self.credentialsProvider = credentialsProvider
        super.init(logger: logger)
    }

    override func execute() {
        do {
            try self.credentialsProvider.getIdentityId { (result) in
                defer {
                    self.done()
                }

                switch result {
                case .success:
                    break
                case let .failure(cause):
                    self.error = cause
                }
            }
        } catch {
            self.error = error
            self.done()
        }
    }

}
