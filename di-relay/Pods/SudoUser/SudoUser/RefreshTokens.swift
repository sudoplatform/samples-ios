//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SudoLogging

/// Operation for refreshing the authentication tokens.
class RefreshTokens: UserOperation {

    private unowned let identityProvider: IdentityProvider

    private unowned let sudoUserClient: SudoUserClient

    private let refreshToken: String

    var tokens: AuthenticationTokens?

    /// Initializes and returns a `RefreshTokens` operation.
    ///
    /// - Parameters:
    ///
    ///   - identityProvider: Identity provider to use for refreshing tokens.
    ///   - sudoUserClient: `SudoUserClient` used to store the refreshed tokens.
    ///   - refreshToken: Refresh token.
    ///   - logger: Logger used for logging.
    init(identityProvider: IdentityProvider,
         sudoUserClient: SudoUserClient,
         refreshToken: String,
         logger: Logger = Logger.sudoUserLogger) {
        self.identityProvider = identityProvider
        self.sudoUserClient = sudoUserClient
        self.refreshToken = refreshToken
        super.init(logger: logger)
    }

    override func execute() {
        do {
            try self.identityProvider.refreshTokens(refreshToken: refreshToken) { (result) in
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
