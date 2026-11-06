//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@preconcurrency import SudoKeyManager
@preconcurrency import SudoUser
import UIKit

enum AuthenticatorError: LocalizedError {
    case alreadyRegistered
    case missingTestKey
    case missingTestKeyId

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        case .alreadyRegistered: return "Already registered"
        case .missingTestKey: return "Missing registration TEST key. Please follow instructions in the README"
        case .missingTestKeyId: return "Missing registration TEST key ID. Please follow instructions in the README"
        }
    }
}

protocol Authenticator: Sendable {

    func isRegistered() async throws -> Bool

    func isSignedIn() async throws -> Bool

    // MARK: TEST keys

    func register() async throws

    func signInWithKey() async throws

    func deregister() async throws

    // MARK: FSSO

    func federatedSignIn(presentationAnchor: UIWindow) async throws

    func federatedSignOut(presentationAnchor: UIWindow) async throws

    // MARK: General

    func reset() async throws
}

final class DefaultAuthenticator: Authenticator, @unchecked Sendable {

    // MARK: - Properties

    let fileReadable: FileReadable

    unowned let userClient: SudoUserClient

    let keyManager: SudoKeyManager

    // MARK: - Lifecycle

    init(userClient: SudoUserClient, keyManager: SudoKeyManager, fileReadable: FileReadable = DefaultFileReadable()) {
        self.userClient = userClient
        self.keyManager = keyManager
        self.fileReadable = fileReadable
    }

    // MARK: - Conformance: Authenticator

    func isRegistered() async throws -> Bool {
        try await userClient.isRegistered()
    }

    func isSignedIn() async throws -> Bool {
        try await userClient.isSignedIn()
    }

    /// Registers a new user using the TEST registration key bundled from the `config` directory.
    func register() async throws {
        if try await userClient.isRegistered() {
            throw AuthenticatorError.alreadyRegistered
        }
        guard let testKeyPath = fileReadable.path(forResource: "register_key", ofType: "private") else {
            throw AuthenticatorError.missingTestKey
        }
        guard let testKeyIdPath = fileReadable.path(forResource: "register_key", ofType: "id") else {
            throw AuthenticatorError.missingTestKeyId
        }
        let testKey = try fileReadable.contentsOfFile(forPath: testKeyPath)
        let testKeyId = try fileReadable.contentsOfFile(forPath: testKeyIdPath).trimmingCharacters(in: .whitespacesAndNewlines)
        let provider = try TESTAuthenticationProvider(
            name: "testRegisterAudience",
            key: testKey,
            keyId: testKeyId,
            keyManager: keyManager
        )
        _ = try await userClient.registerWithAuthenticationProvider(
            authenticationProvider: provider,
            registrationId: UUID().uuidString
        )
    }

    func signInWithKey() async throws {
        _ = try await userClient.signInWithKey()
    }

    /// Deregisters the TEST key user, signing in first if required as deregistration needs a valid session.
    func deregister() async throws {
        if !(try await userClient.isSignedIn()) {
            try await userClient.signOut()
            _ = try await userClient.signInWithKey()
        }
        try await userClient.deregister()
    }

    /// Presents the federated sign in UI, which registers the user on first sign in.
    func federatedSignIn(presentationAnchor: UIWindow) async throws {
        _ = try await userClient.presentFederatedSignInUI(presentationAnchor: presentationAnchor)
    }

    /// Ends the federated session with the identity provider so the next sign in prompts for credentials.
    func federatedSignOut(presentationAnchor: UIWindow) async throws {
        try await userClient.presentFederatedSignOutUI(presentationAnchor: presentationAnchor)
    }

    func reset() async throws {
        try await userClient.reset()
    }
}
