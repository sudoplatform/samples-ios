//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Observation
import SudoLogging
@preconcurrency import SudoEntitlements
import UIKit

@Observable
@MainActor
final class AuthenticationViewModel {

    // MARK: - Properties

    /// True while a sign in is underway.
    var isLoading = false

    /// True once the user is signed in and entitlements have been redeemed.
    var isSignedIn = false

    /// True if `errorMessage` should be presented to the user.
    var showError = false

    var errorMessage = ""

    @ObservationIgnored private let dependencies: AppDependencies

    // MARK: - Lifecycle

    init(dependencies: AppDependencies = AppDelegate.dependencies) {
        self.dependencies = dependencies
    }

    // MARK: - Actions

    /// Skips straight to the home screen if a previous session is still valid, without presenting the FSSO UI again.
    ///
    /// - Parameter enforceSingletonKeyPair: Whether every phone number shares one key pair, for the telephony client.
    func didAppear(enforceSingletonKeyPair: Bool) async {
        isLoading = true
        defer { isLoading = false }
        do {
            guard try await dependencies.authenticator.isSignedIn() else { return }
            try dependencies.startTelephony(enforceSingletonKeyPair: enforceSingletonKeyPair)
            try await dependencies.prepareTelephonyKeys()
            isSignedIn = true
        } catch {
            Logger.sampleLogger.error("Failed to check sign in state: \(error)")
        }
    }

    /// Registers and signs the user in, then creates the clients that depend on the choices made on the sign in screen.
    ///
    /// - Parameters:
    ///   - strategy: How to sign in.
    ///   - enforceSingletonKeyPair: Whether every phone number shares one key pair, for the telephony client.
    func didTapStart(strategy: AuthenticationStrategy, enforceSingletonKeyPair: Bool) async {
        Logger.sampleLogger.info("Signing in with \(strategy)...")
        isLoading = true
        defer { isLoading = false }
        do {
            switch strategy {
            case .test:
                try await signInWithTestKeys()
            case .fsso:
                try await dependencies.authenticator.federatedSignIn(presentationAnchor: UIApplication.shared.presentationAnchor)
            }
            // Before preparing for the user, so a different user's phone number keys are removed along with their other data.
            try dependencies.startTelephony(enforceSingletonKeyPair: enforceSingletonKeyPair)
            try await dependencies.prepareForSignedInUser()
            // After preparing for the user, which removes a different user's keys, including a shared phone number key.
            try await dependencies.prepareTelephonyKeys()
            _ = try await dependencies.entitlementsClient.redeemEntitlements()
            isSignedIn = true
        } catch {
            Logger.sampleLogger.error("Failed to sign in: \(error)")
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    // MARK: - Helpers

    private func signInWithTestKeys() async throws {
        let authenticator = dependencies.authenticator
        if !(try await authenticator.isRegistered()) {
            try await authenticator.register()
        }
        if !(try await authenticator.isSignedIn()) {
            try await authenticator.signInWithKey()
        }
    }
}
