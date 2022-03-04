//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoUser
import SudoKeyManager
import UIKit
import SafariServices
import AuthenticationServices

enum AuthenticatorError: LocalizedError {
    case registerFailed
    case alreadyRegistered
    case missingTestKey
    case missingTestKeyId

    var errorDescription: String? {
        switch self {
        case .registerFailed: return "Something went wrong while trying to register, inspect the logs for details"
        case .alreadyRegistered: return "Already registered"
        case .missingTestKey: return "Missing registration TEST key. Please follow instructions in the README"
        case .missingTestKeyId: return "Missing registration TEST key ID. Please follow instructions in the README"
        }
    }
}

class Authenticator {

    let userClient: SudoUserClient
    let keyManager: SudoKeyManager

    // Keep track of the last method used to sign in.  It helps know what kind of UI to show and actions to perform to get back to a clean state.
    @UserDefaultsBackedWithDefault(key: "lastSignInMethod", defaultValue: ChallengeType.unknown.rawValue)
    private var _lastSignInMethod: String

    var lastSignInMethod: ChallengeType {
        get {
            return ChallengeType(rawValue: _lastSignInMethod) ?? .unknown
        }
        set {
            _lastSignInMethod = newValue.rawValue
        }
    }

    init(userClient: SudoUserClient, keyManager: SudoKeyManager) {
        self.userClient = userClient
        self.keyManager = keyManager
    }

    func authenticationProvider() throws -> TESTAuthenticationProvider {
        guard let testKeyPath = Bundle.main.path(forResource: "register_key", ofType: "private") else {
            throw AuthenticatorError.missingTestKey
        }

        guard let testKeyIdPath = Bundle.main.path(forResource: "register_key", ofType: "id") else {
            throw AuthenticatorError.missingTestKeyId
        }

        do {
            let testKey = try String(contentsOfFile: testKeyPath)
            let testKeyId = try String(contentsOfFile: testKeyIdPath).trimmingCharacters(in: .whitespacesAndNewlines)
            return try TESTAuthenticationProvider(
                name: "testRegisterAudience",
                key: testKey,
                keyId: testKeyId,
                keyManager: keyManager
            )
        } catch {
            fatalError("Authentication error: \(error)")
        }
    }

    func register() async throws {
        do {
            if try await userClient.isRegistered() { throw AuthenticatorError.alreadyRegistered }
            let provider = try authenticationProvider()
            _ = try await userClient.registerWithAuthenticationProvider(authenticationProvider: provider,
                                                                        registrationId: UUID().uuidString)
        } catch {
            NSLog("Pre-registration Failure: \(error)")
        }
    }

    func doFSSOSignOut(from nav: UINavigationController) async throws {
        do {
            let client = Clients.userClient!

            // Present the federated sign out screen.  This will likely trigger a "do you want to allow access" alert.
            try await Clients.userClient!.presentFederatedSignOutUI(presentationAnchor: nav.view.window!)
            // After federated sign out succeeds, perform global sign out.
            try await client.globalSignOut()
            // If global sign out succeeds, we still have to launch this `SFAuthenticationSession` to really
            // clear the auth cookies.  This will trigger another alert, and the user will have to close the blank
            // page that shows up when the logout page loads.
            // If global sign out fails we still want to complete the sign out locally, otherwise we can be left in a bad
            // state where the auth cookies cannot be cleared.
            try await self.clearASWebAuthCookies()
        } catch let error {
            throw error
        }
    }

    private func clearASWebAuthCookies() async throws {
        self.authSession?.start()
        self.authSession = ASWebAuthenticationSession(url: URL(string: "https://dev-98hbdgse.auth0.com/v2/logout")!,
                                                      callbackURLScheme: nil,
                                                      completionHandler: { (_, _) in
            // The only option for the user is to cancel to dismiss the webpage, so there will be an error.
            // that we need to ignore.
            self.lastSignInMethod = .unknown
        })
    }

    var authSession: ASWebAuthenticationSession?

    func registerAndSignIn(from nav: UINavigationController,
                           signInMethod: ChallengeType) async throws {
        let userClient: SudoUserClient = Clients.userClient

        func signIn() async throws {
            if try await !userClient.isSignedIn() {
                _ = try await userClient.signInWithKey()
                self.lastSignInMethod = .test
            }
        }

        switch signInMethod {
        case .fsso:
            _ = try await userClient.presentFederatedSignInUI(presentationAnchor: nav.view.window!)
            self.lastSignInMethod = .fsso
        case .test:
            if try await !userClient.isRegistered() {
                try await self.register()
            }
            try await signIn()
        default:
            break
        }
    }

    func deregister() async throws -> String {
        let deregisteredUserId = try await self.userClient.deregister()
        self.lastSignInMethod = .unknown
        return deregisteredUserId
    }
}
