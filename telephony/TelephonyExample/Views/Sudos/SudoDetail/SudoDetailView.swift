//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@preconcurrency import SudoProfiles
@preconcurrency import SudoTelephonyCommon
import SwiftUI

/// Shows a single Sudo and the phone numbers it can use.
struct SudoDetailView: View {

    // MARK: - Properties

    /// Called with the updated Sudo once it has been edited.
    let onUpdated: (Sudo) -> Void

    /// Called once the Sudo has been deleted, before this view is dismissed.
    let onDeleted: () -> Void

    @State private var viewModel: SudoDetailViewModel

    @State private var phoneNumbersViewModel: PhoneNumbersViewModel

    @Environment(\.dismiss) private var dismiss

    // MARK: - Lifecycle

    init(sudo: Sudo, onUpdated: @escaping (Sudo) -> Void, onDeleted: @escaping () -> Void) {
        self.onUpdated = onUpdated
        self.onDeleted = onDeleted
        _viewModel = State(initialValue: SudoDetailViewModel(sudo: sudo))
        _phoneNumbersViewModel = State(initialValue: PhoneNumbersViewModel(sudoId: sudo.id))
    }

    // MARK: - View

    var body: some View {
        List {
            PhoneNumbersSection(viewModel: phoneNumbersViewModel)
        }
        .disabled(viewModel.isLoading)
        .task {
            await phoneNumbersViewModel.didAppear()
        }
        .onDisappear(perform: phoneNumbersViewModel.didDisappear)
        .navigationTitle(viewModel.sudo.label ?? "New Sudo")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    EditSudoView(sudo: viewModel.sudo) { updatedSudo in
                        viewModel.didUpdateSudo(updatedSudo)
                        onUpdated(updatedSudo)
                    }
                } label: {
                    Label("Edit Sudo", systemImage: "pencil")
                }
                .disabled(viewModel.isLoading)
            }
            ToolbarItem(placement: .primaryAction) {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Button("Delete Sudo", systemImage: "trash", role: .destructive, action: viewModel.didTapDelete)
                }
            }
        }
        .onChange(of: viewModel.isDeleted) { _, isDeleted in
            guard isDeleted else { return }
            onDeleted()
            dismiss()
        }
        .deleteSudoConfirmation(isPresented: $viewModel.showDeleteConfirmation) {
            Task {
                await viewModel.didConfirmDelete()
            }
        }
        .releaseNumberConfirmation(
            isPresented: $phoneNumbersViewModel.showReleaseConfirmation,
            phoneNumber: phoneNumbersViewModel.numberPendingRelease
        ) {
            Task {
                await phoneNumbersViewModel.didConfirmRelease()
            }
        }
        .alert("An error occurred", isPresented: $phoneNumbersViewModel.showError) {
            Button("OK") {}
        } message: {
            Text(phoneNumbersViewModel.errorMessage)
        }
        .alert("An error occurred", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}
