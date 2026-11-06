//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Observation
@preconcurrency import SudoKeyManager
import SudoLogging
@preconcurrency import SudoProfiles
@preconcurrency import SudoUser
import UIKit

@Observable
@MainActor
final class HomeViewModel {

    // MARK: - Properties

    /// True while signing out or deregistering.
    var isLoading = false

    /// True once the user has signed out or deregistered and local state has been reset.
    var isSignedOut = false

    /// The signed in user's Sudos, which telephony resources are provisioned against.
    var sudos: [Sudo] = []

    /// True if the Sudos couldn't be decrypted because this device doesn't have their keys, e.g. they were created on another
    /// device or before signing out. Importing a key backup fixes this.
    var sudosNeedKeyImport = false

    /// True while the Sudos are being fetched or one is being deleted.
    var isLoadingSudos = false

    /// True while the user has pulled to refresh, which shows its own progress indicator.
    var isRefreshingSudos = false

    /// True once the Sudos have been fetched. Later changes are applied locally as the other screens report them, so they aren't fetched again.
    @ObservationIgnored private var hasLoadedSudos = false

    /// The Sudo the user has swiped to delete, awaiting confirmation.
    @ObservationIgnored private var sudoPendingDeletion: Sudo?

    /// True if the delete Sudo confirmation should be presented.
    var showDeleteSudoConfirmation = false

    /// True if the deregister confirmation should be presented.
    var showDeregisterConfirmation = false

    /// True if the sign out and remove data confirmation should be presented.
    var showRemoveDataConfirmation = false

    /// True if the explanation that TEST registrations can't back up keys should be presented.
    var showTestKeyBackupInfo = false

    /// True to show the key import/export screen, e.g. to export keys before removing them.
    var showKeyImportExport = false

    /// True if `errorMessage` should be presented to the user.
    var showError = false

    var errorMessage = ""

    @ObservationIgnored private let dependencies: AppDependencies

    // MARK: - Lifecycle

    init(dependencies: AppDependencies = AppDelegate.dependencies) {
        self.dependencies = dependencies
    }

    // MARK: - Actions

    /// Fetches the Sudos the first time Home appears, retrying on later appearances until a fetch succeeds.
    func didAppear() async {
        guard !hasLoadedSudos else { return }
        await loadSudos()
    }

    /// Fetches the Sudos again, picking up any changes made elsewhere, e.g. on another device.
    func didPullToRefresh() async {
        isRefreshingSudos = true
        defer { isRefreshingSudos = false }
        await loadSudos()
    }

    /// Fetches the Sudos again from the refresh button, which shows the Sudos section's progress indicator instead of pull to refresh's.
    func didTapRefresh() async {
        await loadSudos()
    }

    /// Fetches the Sudos again after keys were imported, as ones that couldn't be decrypted before may be readable now.
    func didImportKeys() async {
        await loadSudos()
    }

    func didCreateSudo(_ createdSudo: Sudo) {
        sudos.append(createdSudo)
        sudos.sort()
    }

    /// Asks for confirmation before deleting the swiped Sudo, as its telephony data will be lost.
    func didSwipeToDeleteSudos(at offsets: IndexSet) {
        guard let index = offsets.first else { return }
        sudoPendingDeletion = sudos[index]
        showDeleteSudoConfirmation = true
    }

    func didConfirmDeleteSudo() async {
        guard let sudo = sudoPendingDeletion else { return }
        sudoPendingDeletion = nil
        Logger.sampleLogger.info("Deleting Sudo...")
        isLoadingSudos = true
        defer { isLoadingSudos = false }
        do {
            try await dependencies.profilesClient.deleteSudo(input: SudoDeleteInput(sudoId: sudo.id, version: sudo.version))
            didDeleteSudo(sudo)
        } catch {
            Logger.sampleLogger.error("Failed to delete Sudo: \(error)")
            await presentError(error)
        }
    }

    /// Replaces a Sudo that has been edited from its detail screen.
    func didUpdateSudo(_ updatedSudo: Sudo) {
        guard let index = sudos.firstIndex(where: { $0.id == updatedSudo.id }) else { return }
        sudos[index] = updatedSudo
    }

    /// Removes a Sudo that has been deleted, either here or from its detail screen.
    func didDeleteSudo(_ sudo: Sudo) {
        sudos.removeAll { $0.id == sudo.id }
    }

    func didTapDeregister() {
        showDeregisterConfirmation = true
    }

    /// Deregisters a TEST key user, deleting their account, then clears local state.
    func didConfirmDeregister() async {
        await perform("deregister", removingLocalData: true) {
            try await self.dependencies.authenticator.deregister()
        }
    }

    /// Signs out a federated user, keeping their keys on this device so they can read their Sudos when they sign back in.
    func didTapSignOut() async {
        await perform("sign out", removingLocalData: false) {
            try await self.dependencies.authenticator.federatedSignOut(presentationAnchor: UIApplication.shared.presentationAnchor)
        }
    }

    func didTapKeyImportExportWithTestKeys() {
        showTestKeyBackupInfo = true
    }

    func didTapSignOutAndRemoveData() {
        showRemoveDataConfirmation = true
    }

    func didTapExportBeforeRemovingData() {
        showKeyImportExport = true
    }

    /// Signs out a federated user and removes their keys and data from this device. Their Sudos can only be read again here by
    /// importing a key backup.
    func didConfirmSignOutAndRemoveData() async {
        await perform("sign out and remove data", removingLocalData: true) {
            try await self.dependencies.authenticator.federatedSignOut(presentationAnchor: UIApplication.shared.presentationAnchor)
        }
    }

    // MARK: - Helpers

    private func loadSudos() async {
        isLoadingSudos = true
        defer { isLoadingSudos = false }
        do {
            sudos = try await dependencies.profilesClient.listSudos(cachePolicy: .remoteOnly)
            sudosNeedKeyImport = false
            hasLoadedSudos = true
        } catch SudoKeyManagerError.keyNotFound {
            Logger.sampleLogger.info("Sudos can't be decrypted without importing keys")
            // Clear any Sudos from before, e.g. ones read with keys an import has just replaced, so they don't look still readable.
            sudos = []
            sudosNeedKeyImport = true
        } catch {
            Logger.sampleLogger.error("Failed to list Sudos: \(error)")
            await presentError(error)
        }
    }

    /// Shows `error`, unless it means the session has expired, in which case the app goes back to sign in instead.
    private func presentError(_ error: Error) async {
        guard await !dependencies.session.didExpire(after: error) else { return }
        errorMessage = error.localizedDescription
        showError = true
    }

    private func perform(_ operationName: String, removingLocalData: Bool, operation: () async throws -> Void) async {
        Logger.sampleLogger.info("Attempting to \(operationName)...")
        isLoading = true
        defer { isLoading = false }
        do {
            try await operation()
            if removingLocalData {
                try await dependencies.reset()
            } else {
                try await dependencies.resetSignIn()
            }
            isSignedOut = true
        } catch {
            Logger.sampleLogger.error("Failed to \(operationName): \(error)")
            await presentError(error)
        }
    }
}
