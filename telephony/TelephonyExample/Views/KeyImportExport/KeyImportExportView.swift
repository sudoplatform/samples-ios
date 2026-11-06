//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI
import UniformTypeIdentifiers

/// Exports the user's keys to a password-protected file and imports them from one, so Sudos created on one device can be read
/// on another signed in as the same user. Only reachable with Federated Sign In, as TEST registrations are tied to a single device.
struct KeyImportExportView: View {

    // MARK: - Properties

    /// Called once keys have been imported, so data encrypted with them can be fetched again.
    let onImported: () -> Void

    @State private var viewModel = KeyImportExportViewModel()

    // MARK: - View

    var body: some View {
        List {
            Section {
                Text("Your Sudos are encrypted with keys kept on this device. Back them up to read your Sudos on another device signed in to the same account.")
            }
            Section {
                Button("Export Keys", systemImage: "square.and.arrow.up", action: viewModel.didTapExport)
            } footer: {
                Text("Creates a backup file protected by a password you choose. Anyone with the file and its password can read your Sudos, so keep both safe.")
            }
            Section {
                Button("Import Keys", systemImage: "square.and.arrow.down", action: viewModel.didTapImport)
            } footer: {
                Text("Replaces this device's keys with the ones in a backup.")
            }
        }
        .navigationTitle("Import/Export Keys")
        .sheet(item: $viewModel.passwordPrompt, onDismiss: viewModel.didDismissPasswordPrompt) { prompt in
            passwordSheet(for: prompt)
        }
        .sheet(item: $viewModel.exportedFile, onDismiss: viewModel.didDismissShareSheet) { file in
            ShareSheet(url: file.url, onComplete: viewModel.didFinishSharing)
                .presentationDetents([.medium, .large])
        }
        .fileImporter(isPresented: $viewModel.showFileImporter, allowedContentTypes: [.json], onCompletion: viewModel.didPickFile)
        .alert("Replace This Device's Keys?", isPresented: $viewModel.showImportConfirmation, presenting: viewModel.pendingImport) { _ in
            Button("Cancel", role: .cancel) {}
            Button("Continue", role: .destructive, action: viewModel.didConfirmImport)
        } message: { file in
            Text("\(KeyImportExportViewModel.describe(file)). Sudos created on this device with keys that aren't in this backup will no longer be readable.")
        }
        .alert("Keys Imported", isPresented: $viewModel.showImportResult) {
            Button("OK") {}
        } message: {
            Text(viewModel.importResultMessage)
        }
        .alert("An error occurred", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func passwordSheet(for prompt: KeyImportExportViewModel.PasswordPrompt) -> some View {
        switch prompt {
        case .export:
            KeyBackupPasswordView(
                mode: .export,
                isWorking: viewModel.isWorking,
                errorMessage: viewModel.passwordError,
                onSubmit: { password in
                    Task {
                        await viewModel.didEnterExportPassword(password)
                    }
                },
                onCancel: viewModel.didCancelPasswordPrompt
            )
        case .importBackup(let file):
            KeyBackupPasswordView(
                mode: .importBackup(description: KeyImportExportViewModel.describe(file)),
                isWorking: viewModel.isWorking,
                errorMessage: viewModel.passwordError,
                onSubmit: { password in
                    Task {
                        if await viewModel.didEnterImportPassword(password, file: file) {
                            onImported()
                        }
                    }
                },
                onCancel: viewModel.didCancelPasswordPrompt
            )
        }
    }
}
