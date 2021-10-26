//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SudoLogging

/// Operation to sign in with a key.
class SignInWithKey: UserOperation {

    private unowned let identityProvider: IdentityProvider

    private unowned let sudoUserClient: SudoUserClient

    private let uid: String

    private let parameters: [String: Any]

    var tokens: AuthenticationTokens?

    /// Initializes and returns a `SignInWithKey` operation.
    ///
    /// - Parameters:
    ///
    ///   - identityProvider: Identity provider to use for signing in.
    ///   - sudoUserClient: `SudoUserClient` used to store the authentication tokens.
    ///   - logger: Logger used for logging.
    init(identityProvider: IdentityProvider,
         sudoUserClient: SudoUserClient,
         uid: String,
         parameters: [String: Any],
         logger: Logger = Logger.sudoUserLogger) {
        self.identityProvider = identityProvider
        self.sudoUserClient = sudoUserClient
        self.uid = uid
        self.parameters = parameters
        super.init(logger: logger)
    }

    override func execute() {
        do {
            try self.identityProvider.signIn(uid: self.uid, parameters: self.parameters) { (result) in
                defer {
                    self.done()
                }

                switch result {
                case let .success(tokens):
                    self.tokens = tokens
                    do {
                        try self.sudoUserClient.storeTokens(tokens: tokens)
                    } catch {
                        self.error = error
                    }
                case let .failure(cause):
                    switch cause {
                    case IdentityProviderError.notAuthorized:
                        self.error = SudoUserClientError.notAuthorized
                    default:
                        self.error = cause
                    }
                }
            }
        } catch {
            self.error = error
            self.done()
        }
    }

}
