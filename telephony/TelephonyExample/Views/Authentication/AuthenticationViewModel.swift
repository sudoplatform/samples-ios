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
    func didAppear() async {
        isLoading = true
        defer { isLoading = false }
        do {
            isSignedIn = try await dependencies.authenticator.isSignedIn()
        } catch {
            Logger.sampleLogger.error("Failed to check sign in state: \(error)")
        }
    }

    func didTapStart(strategy: AuthenticationStrategy) async {
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
            try await dependencies.prepareForSignedInUser()
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
