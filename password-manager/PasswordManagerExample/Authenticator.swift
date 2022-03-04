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
import SudoEntitlements

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
    let entitlementsClient: SudoEntitlementsClient

    // Keep track of the last method used to sign in.  It helps know what kind of UI to show and actions to perform to get back to a clean state.
    @UserDefaultsBackedWithDefault(key: "lastSignInMethod", defaultValue: ChallengeType.unknown.rawValue)
    private var _lastSignInMethod: String

    internal private(set) var lastSignInMethod: ChallengeType {
        get {
            return ChallengeType(rawValue: _lastSignInMethod) ?? .unknown
        }
        set {
            _lastSignInMethod = newValue.rawValue
        }
    }


    init(userClient: SudoUserClient, keyManager: SudoKeyManager, entitlementsClient: SudoEntitlementsClient) {
        self.userClient = userClient
        self.keyManager = keyManager
        self.entitlementsClient = entitlementsClient
    }

    private func register() async throws {
        if try await userClient.isRegistered() {
            throw AuthenticatorError.alreadyRegistered
        }

        guard let testKeyPath = Bundle.main.path(forResource: "register_key", ofType: "private") else {
            throw AuthenticatorError.missingTestKey
        }

        guard let testKeyIdPath = Bundle.main.path(forResource: "register_key", ofType: "id") else {
            throw AuthenticatorError.missingTestKeyId
        }

        let testKey = try String(contentsOfFile: testKeyPath)
        let testKeyId = try String(contentsOfFile: testKeyIdPath).trimmingCharacters(in: .whitespacesAndNewlines)
        let provider = try TESTAuthenticationProvider(
            name: "testRegisterAudience",
            key: testKey,
            keyId: testKeyId,
            keyManager: keyManager
        )
        _ = try await userClient.registerWithAuthenticationProvider(
            authenticationProvider: provider,
            registrationId: UUID().uuidString)
    }


    func doFSSOSignOut(from anchor: UIWindow) async throws {
        // Present the federated sign out screen.  This will likely trigger a "do you want to allow access" alert.
        try await Clients.userClient!.presentFederatedSignOutUI(presentationAnchor: anchor)
        self.lastSignInMethod = .unknown
        // There is no way to tap into the authentication session's UI dismissal, so we have issues
        // dismissing view controllers after sign out.  As a general fix we can delay the completion handler
        // for one second to let things settle.
        //
        //https://developer.apple.com/forums/thread/123667
        try await Task.sleep(nanoseconds: 1)
    }

    func registerAndSignIn(from anchor: UIWindow, signInMethod: ChallengeType) async throws {
        let userClient: SudoUserClient = Clients.userClient

        func signInWithTestKey() async throws {
                if try await userClient.isSignedIn() {
                    _ = try await self.entitlementsClient.redeemEntitlements()
                    return
                }

                _ = try await userClient.signInWithKey()
                self.lastSignInMethod = .test
                _ = try await self.entitlementsClient.redeemEntitlements()
        }

        switch signInMethod {
        case .fsso:
            _ = try await userClient.presentFederatedSignInUI(presentationAnchor: anchor)
            self.lastSignInMethod = .fsso
            _ = try await self.entitlementsClient.redeemEntitlements()
        case .test:
            if try await userClient.isRegistered() {
                try await signInWithTestKey()
            } else {
                try await self.register()
                try await signInWithTestKey()
            }
        default:
            break
        }
    }

    func deregister() async throws -> String {
        defer {
            self.lastSignInMethod = .unknown
        }
        return try await self.userClient.deregister()
    }
}
