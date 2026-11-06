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
final class EditSudoViewModel {

    // MARK: - Properties

    var label: String

    /// True while the Sudo is being updated.
    var isLoading = false

    /// The Sudo as returned by the service once updated, which has a new version.
    var updatedSudo: Sudo?

    /// True if `errorMessage` should be presented to the user.
    var showError = false

    var errorMessage = ""

    @ObservationIgnored private let sudo: Sudo

    @ObservationIgnored private let dependencies: AppDependencies

    // MARK: - Properties: Computed

    var isSaveEnabled: Bool {
        let trimmedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedLabel.isEmpty && trimmedLabel != sudo.label && !isLoading
    }

    // MARK: - Lifecycle

    init(sudo: Sudo, dependencies: AppDependencies = AppDelegate.dependencies) {
        self.sudo = sudo
        self.label = sudo.label ?? ""
        self.dependencies = dependencies
    }

    // MARK: - Actions

    func didTapSave() async {
        Logger.sampleLogger.info("Updating Sudo...")
        isLoading = true
        defer { isLoading = false }
        do {
            let input = SudoUpdateInput(sudoId: sudo.id, version: sudo.version, label: .newValue(label.trimmingCharacters(in: .whitespacesAndNewlines)))
            updatedSudo = try await dependencies.profilesClient.updateSudo(input: input)
        } catch {
            Logger.sampleLogger.error("Failed to update Sudo: \(error)")
            // If the session has expired, the app goes back to sign in instead of showing the error.
            guard await !dependencies.session.didExpire(after: error) else { return }
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
