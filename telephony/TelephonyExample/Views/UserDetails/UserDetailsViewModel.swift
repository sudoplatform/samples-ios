//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Observation
import SudoLogging
@preconcurrency import SudoUser
import UIKit

@Observable
@MainActor
final class UserDetailsViewModel {

    // MARK: - Properties

    /// The user's ID: their SudoUser user name, which SudoUser documents as what support needs to diagnose an issue with a
    /// specific user. A federated user's name starts with their identity provider, e.g. "Auth0_auth0|".
    var userId: String?

    /// The user's subject, which the telephony SDK scopes subscriptions to and services record as the owner of the user's data.
    var subject: String?

    /// When the user last signed in, from the ID token's `auth_time` claim.
    var signedInAt: Date?

    /// When the current ID token expires, from its `exp` claim. SudoUser refreshes it automatically before then.
    var idTokenExpiresAt: Date?

    var isLoading = false

    var toastMessage: String?

    /// True if `errorMessage` should be presented to the user.
    var showError = false

    var errorMessage = ""

    @ObservationIgnored private let dependencies: AppDependencies

    // MARK: - Lifecycle

    init(dependencies: AppDependencies = AppDelegate.dependencies) {
        self.dependencies = dependencies
    }

    // MARK: - Actions

    func didAppear() async {
        guard userId == nil else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            userId = try await dependencies.userClient.getUserName()
            // SudoUser documents the subject as internal to the Sudo SDKs, but it's useful when talking to the service teams.
            subject = try await dependencies.userClient.getSubject()
            signedInAt = Self.date(fromClaim: try await dependencies.userClient.getUserClaim(name: "auth_time"))
            idTokenExpiresAt = Self.date(fromClaim: try await dependencies.userClient.getUserClaim(name: "exp"))
        } catch {
            Logger.sampleLogger.error("Failed to get user details: \(error)")
            // If the session has expired, the app goes back to sign in instead of showing the error.
            guard await !dependencies.session.didExpire(after: error) else { return }
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func didTapCopy(_ value: String, name: String) {
        UIPasteboard.general.string = value
        toastMessage = "\(name) copied"
    }

    // MARK: - Helpers

    /// A date from a JWT time claim, which is seconds since the Unix epoch.
    private static func date(fromClaim claim: Any?) -> Date? {
        (claim as? NSNumber).map { Date(timeIntervalSince1970: $0.doubleValue) }
    }
}
