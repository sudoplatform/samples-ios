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
final class SudoDetailViewModel {

    // MARK: - Properties

    /// The Sudo being shown, replaced when edited as each update gives it a new version.
    private(set) var sudo: Sudo

    /// True while the Sudo is being deleted.
    var isLoading = false

    /// True once the Sudo has been deleted.
    var isDeleted = false

    /// True if the delete confirmation should be presented.
    var showDeleteConfirmation = false

    /// True if `errorMessage` should be presented to the user.
    var showError = false

    var errorMessage = ""

    @ObservationIgnored private let dependencies: AppDependencies

    // MARK: - Lifecycle

    init(sudo: Sudo, dependencies: AppDependencies = AppDelegate.dependencies) {
        self.sudo = sudo
        self.dependencies = dependencies
    }

    // MARK: - Actions

    func didUpdateSudo(_ updatedSudo: Sudo) {
        sudo = updatedSudo
    }

    func didTapDelete() {
        showDeleteConfirmation = true
    }

    func didConfirmDelete() async {
        Logger.sampleLogger.info("Deleting Sudo...")
        isLoading = true
        defer { isLoading = false }
        do {
            try await dependencies.profilesClient.deleteSudo(input: SudoDeleteInput(sudoId: sudo.id, version: sudo.version))
            isDeleted = true
        } catch {
            Logger.sampleLogger.error("Failed to delete Sudo: \(error)")
            // If the session has expired, the app goes back to sign in instead of showing the error.
            guard await !dependencies.session.didExpire(after: error) else { return }
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
