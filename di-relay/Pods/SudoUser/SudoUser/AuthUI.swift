//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoLogging
import AWSMobileClient

/// Responsible for managing the authentication flow for browser based federated sign in.
public protocol AuthUI: AnyObject {

    /// Presents the sign in UI for federated sign in using an external identity provider.
    ///
    /// - Parameters:
    ///   - presentationAnchor: Window to act as the anchor for this UI.
    /// - Returns: Authentication tokens.
    func presentFederatedSignInUI(presentationAnchor: ASPresentationAnchor) async throws -> AuthenticationTokens

    /// Presents the sign out UI for federated sign in using an external identity provider.
    ///
    /// - Parameters:
    ///   - presentationAnchor: Window to act as the anchor for this UI.
    func presentFederatedSignOutUI(presentationAnchor: ASPresentationAnchor) async throws

    /// Processes federated sign in redirect URL to obtain the authentication tokens required for API access..
    ///
    /// - Parameters:
    ///   - url: Federated sign in URL passed into the app via URL scheme.
    /// - Returns: Boolean indicating whether or not the FSSO token was processed successfully.
    func processFederatedSignInTokens(url: URL) -> Bool

    /// Resets any internal state.
    func reset()

}

/// AuthUI implemented that uses Cognito Auth UI.
public class CognitoAuthUI: AuthUI {

    /// Configuration parameter names.
    public struct Config {

        struct FederatedSignIn {
            // ID of the app client configured for federated sign in in Cognito user pool.
            static let appClientId = "appClientId"
            // Web domain configured for the hosted UI in Cognito user pool.
            static let webDomain = "webDomain"
            // URL to redirect to after sign in.
            static let signInRedirectUri = "signInRedirectUri"
            // URL to redirect to after sign ou.
            static let signOutRedirectUri = "signOutRedirectUri"
        }

    }

    private struct Constants {

        struct Auth {
            static let cognitoAuthKey = "com.sudoplatform.id.cognito.auth"
        }

    }

    /// Default logger for SudoUserClient.
    private let logger: Logger

    /// Cognito Hosted UI authentication.
    private var cognitoAuth: AWSCognitoAuth

    /// Intializes a new `CognitoAuthUI` instance.
    ///
    /// - Parameters:
    ///   - config: Configuration parameters.
    ///   - logger: A logger to use for logging messages. If none provided then use a default logger.
    ///
    /// - Returns: A new initialized `CognitoAuthUI` instance.
    public init(config: [String: Any], logger: Logger? = nil) throws {
        guard let appClientId = config[Config.FederatedSignIn.appClientId] as? String,
            let webDomain = config[Config.FederatedSignIn.webDomain] as? String,
            let signInRedirectUri = config[Config.FederatedSignIn.signInRedirectUri] as? String,
            let signOutRedirectUri = config[Config.FederatedSignIn.signOutRedirectUri] as? String else {
                throw SudoUserClientError.invalidConfig
        }

        let logger = logger ?? Logger.sudoUserLogger
        self.logger = logger

        let cognitoAuthConfig: AWSCognitoAuthConfiguration = AWSCognitoAuthConfiguration.init(appClientId: appClientId,
                                                                                              appClientSecret: nil,
                                                                                              scopes: ["openid"],
                                                                                              signInRedirectUri: signInRedirectUri,
                                                                                              signOutRedirectUri: signOutRedirectUri,
                                                                                              webDomain: "https://\(webDomain)",
                                                                                              identityProvider: nil,
                                                                                              idpIdentifier: nil,
                                                                                              signInUri: nil,
                                                                                              signOutUri: nil,
                                                                                              tokensUri: nil,
                                                                                              signInUriQueryParameters: nil,
                                                                                              signOutUriQueryParameters: nil,
                                                                                              tokenUriQueryParameters: nil,
                                                                                              userPoolServiceConfiguration: nil,
                                                                                              signInPrivateSession: true)

        AWSCognitoAuth.registerCognitoAuth(with: cognitoAuthConfig, forKey: Constants.Auth.cognitoAuthKey)

        self.cognitoAuth = AWSCognitoAuth(forKey: Constants.Auth.cognitoAuthKey)
    }

    public func presentFederatedSignInUI(presentationAnchor: ASPresentationAnchor) async throws -> AuthenticationTokens {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<AuthenticationTokens, Error>) in
            self.cognitoAuth.getSessionWithWebUI(presentationAnchor) { (session, error) in
                if let error = error {
                    if let error = error as? ASWebAuthenticationSessionError {
                        switch error.errorCode {
                        case ASWebAuthenticationSessionError.canceledLogin.rawValue:
                            return continuation.resume(throwing: SudoUserClientError.signInCanceled)
                        default:
                            return continuation.resume(throwing: error)
                        }
                    } else {
                        return continuation.resume(throwing: error)
                    }
                }

                guard let session = session,
                      let idToken = session.idToken?.tokenString,
                      let username = session.username,
                      let accessToken = session.accessToken?.tokenString,
                      let refreshToken = session.refreshToken?.tokenString,
                      let expirationTime = session.expirationTime else {
                          return continuation.resume(throwing: SudoUserClientError.fatalError(description: "Required tokens not found."))
                      }

                let lifetime = Int(expirationTime.timeIntervalSince1970 - Date().timeIntervalSince1970)

                continuation.resume(returning: AuthenticationTokens(idToken: idToken, accessToken: accessToken, refreshToken: refreshToken, lifetime: lifetime, username: username))
            }
        })
    }

    public func presentFederatedSignOutUI(presentationAnchor: ASPresentationAnchor) async throws {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Void, Error>) in
            self.cognitoAuth.signOut(withWebUI: presentationAnchor) { (error) in
                if let error = error {
                    if let error = error as? ASWebAuthenticationSessionError {
                        switch error.errorCode {
                        case ASWebAuthenticationSessionError.canceledLogin.rawValue:
                            continuation.resume(throwing: SudoUserClientError.signInCanceled)
                        default:
                            continuation.resume(throwing: error)
                        }
                    } else {
                        return continuation.resume(throwing: error)
                    }
                } else {
                    continuation.resume()
                }
            }
        })
    }

    public func processFederatedSignInTokens(url: URL) -> Bool {
        return self.cognitoAuth.application(UIApplication.shared, open: url, options: [:])
    }

    public func reset() {
        self.cognitoAuth.signOutLocallyAndClearLastKnownUser()
    }

}
