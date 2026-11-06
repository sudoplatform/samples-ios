//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@preconcurrency import SudoProfiles
import SwiftUI

/// A form to change a Sudo's label.
struct EditSudoView: View {

    // MARK: - Properties

    /// Called with the updated Sudo once saved, before this view is dismissed.
    let onUpdated: (Sudo) -> Void

    @State private var viewModel: EditSudoViewModel

    @Environment(\.dismiss) private var dismiss

    // MARK: - Lifecycle

    init(sudo: Sudo, onUpdated: @escaping (Sudo) -> Void) {
        self.onUpdated = onUpdated
        _viewModel = State(initialValue: EditSudoViewModel(sudo: sudo))
    }

    // MARK: - View

    var body: some View {
        Form {
            Section {
                TextField("Enter Sudo Label", text: $viewModel.label)
                    .submitLabel(.done)
            } footer: {
                Text("Choose any label you would like for your Sudo: Shopping, Dating, etc.")
            }
            .disabled(viewModel.isLoading)
        }
        .navigationTitle("Edit Sudo")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Button("Save") {
                        Task {
                            await viewModel.didTapSave()
                        }
                    }
                    .disabled(!viewModel.isSaveEnabled)
                }
            }
        }
        .onChange(of: viewModel.updatedSudo) { _, updatedSudo in
            guard let updatedSudo else { return }
            onUpdated(updatedSudo)
            dismiss()
        }
        .alert("An error occurred", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}
