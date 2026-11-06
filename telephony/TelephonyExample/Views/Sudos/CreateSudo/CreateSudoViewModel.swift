//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Observation
import SudoLogging
@preconcurrency import SudoProfiles

@Observable
@MainActor
final class CreateSudoViewModel {

    // MARK: - Properties

    var label = ""

    /// True while the Sudo is being created.
    var isLoading = false

    /// The Sudo once created.
    var createdSudo: Sudo?

    /// True if `errorMessage` should be presented to the user.
    var showError = false

    var errorMessage = ""

    @ObservationIgnored private let dependencies: AppDependencies

    // MARK: - Properties: Computed

    var isCreateEnabled: Bool {
        !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }

    // MARK: - Lifecycle

    init(dependencies: AppDependencies = AppDelegate.dependencies) {
        self.dependencies = dependencies
    }

    // MARK: - Actions

    func didTapCreate() async {
        Logger.sampleLogger.info("Creating Sudo...")
        isLoading = true
        defer { isLoading = false }
        do {
            createdSudo = try await dependencies.profilesClient.createSudo(input: SudoCreateInput(label: label))
        } catch SudoProfilesClientError.insufficientEntitlements {
            Logger.sampleLogger.error("Failed to create Sudo: insufficient entitlements")
            errorMessage = "You've reached the maximum number of Sudos you can have. "
                + "Delete a Sudo to create another. Entitlements on the Home screen shows your limits."
            showError = true
        } catch {
            Logger.sampleLogger.error("Failed to create Sudo: \(error)")
            // If the session has expired, the app goes back to sign in instead of showing the error.
            guard await !dependencies.session.didExpire(after: error) else { return }
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
