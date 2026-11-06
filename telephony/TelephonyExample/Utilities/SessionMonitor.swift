//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Observation
import SudoLogging
@preconcurrency import SudoProfiles
@preconcurrency import SudoTelephonyCommon
@preconcurrency import SudoUser

/// Notices when the user's session expires, e.g. after the app was left open overnight, so the app can send them back to sign in
/// from whichever screen they're on instead of showing an error on each request.
@Observable
@MainActor
final class SessionMonitor {

    // MARK: - Properties

    /// True once the session has expired and couldn't be refreshed. The user needs to sign in again; their keys and data stay.
    private(set) var hasExpired = false

    @ObservationIgnored private unowned let userClient: SudoUserClient

    // MARK: - Lifecycle

    init(userClient: SudoUserClient) {
        self.userClient = userClient
    }

    // MARK: - Methods

    /// Checks whether `error` means the session has expired, and if so marks it as expired. Call this before showing a request's
    /// error: if it returns true, don't show the error, as the app is going back to sign in.
    ///
    /// The SDKs refresh the tokens before each request, so a request that still isn't authorized means they couldn't. Refreshing
    /// once more confirms it rather than signing the user out because of a single failed request.
    func didExpire(after error: Error) async -> Bool {
        guard Self.isNotAuthorized(error) else { return false }
        guard !hasExpired else { return true }
        do {
            _ = try await userClient.refreshTokens()
            return false
        } catch {
            Logger.sampleLogger.info("Session has expired: \(error)")
            hasExpired = true
            return true
        }
    }

    /// Clears the expired state once the user has signed in again.
    func didSignIn() {
        hasExpired = false
    }

    // MARK: - Helpers

    private static func isNotAuthorized(_ error: Error) -> Bool {
        switch error {
        case SudoTelephonyError.notAuthorized, SudoTelephonyError.notSignedIn,
             SudoProfilesClientError.notAuthorized, SudoProfilesClientError.notSignedIn:
            return true
        default:
            return false
        }
    }
}
