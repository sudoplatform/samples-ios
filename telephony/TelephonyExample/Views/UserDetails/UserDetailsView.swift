//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

/// The signed in user's account identifiers, each copyable, e.g. to give to support or a service team when diagnosing an issue.
struct UserDetailsView: View {

    // MARK: - Properties

    @State private var viewModel = UserDetailsViewModel()

    /// How the user signed in.
    @AppStorage(AuthenticationStrategy.storageKey) private var strategy: AuthenticationStrategy = .test

    // MARK: - View

    var body: some View {
        List {
            Section {
                row("User ID", value: viewModel.userId)
                row("Subject", value: viewModel.subject)
            } footer: {
                Text("Tap the copy button to copy a value, for example to include in a support request.")
            }
            Section {
                LabeledContent("Signed in with", value: strategy.description)
                LabeledContent("Signed in", value: formatted(viewModel.signedInAt))
                LabeledContent("ID token expires", value: formatted(viewModel.idTokenExpiresAt))
            } header: {
                Text("Session")
            } footer: {
                Text("The ID token is refreshed automatically. SudoUser's refresh token lasts 30 days from signing in, after which you need to sign in again.")
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .navigationTitle("User Details")
        .toast($viewModel.toastMessage)
        .task {
            await viewModel.didAppear()
        }
        .alert("An error occurred", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    // MARK: - Helpers

    private func formatted(_ date: Date?) -> String {
        date?.formatted(date: .abbreviated, time: .shortened) ?? "Not available"
    }

    /// A label with its value underneath, which IDs are too long to fit beside, and a button to copy it.
    private func row(_ name: String, value: String?) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                Text(value ?? "Not available")
                    .font(.footnote.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
            Spacer()
            if let value {
                Button("Copy \(name)", systemImage: "doc.on.doc") {
                    viewModel.didTapCopy(value, name: name)
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
            }
        }
    }
}
