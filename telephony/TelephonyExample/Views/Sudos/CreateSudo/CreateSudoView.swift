//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@preconcurrency import SudoProfiles
import SwiftUI

/// A form to create a Sudo with a label of the user's choosing.
struct CreateSudoView: View {

    // MARK: - Properties

    /// Called with the created Sudo, before this view is dismissed.
    let onCreated: (Sudo) -> Void

    @State private var viewModel = CreateSudoViewModel()

    @Environment(\.dismiss) private var dismiss

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
        .navigationTitle("Create Sudo")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Button("Create") {
                        Task {
                            await viewModel.didTapCreate()
                        }
                    }
                    .disabled(!viewModel.isCreateEnabled)
                }
            }
        }
        .onChange(of: viewModel.createdSudo) { _, createdSudo in
            guard let createdSudo else { return }
            onCreated(createdSudo)
            dismiss()
        }
        .alert("An error occurred", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}
