//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@preconcurrency import SudoTelephonyCommon
import SwiftUI

/// A single received message, marked as read when opened, with its text selectable and copyable, and a way to delete it.
struct PhoneMessageView: View {

    // MARK: - Properties

    /// Called once the message has been deleted, before this view is dismissed.
    let onDeleted: () -> Void

    @State private var viewModel: PhoneMessageViewModel

    @Environment(\.dismiss) private var dismiss

    // MARK: - Lifecycle

    init(message: PhoneMessage, onDeleted: @escaping () -> Void) {
        self.onDeleted = onDeleted
        _viewModel = State(initialValue: PhoneMessageViewModel(message: message))
    }

    // MARK: - View

    var body: some View {
        List {
            Section {
                LabeledContent("From", value: viewModel.message.remotePhoneNumber.map(PhoneNumberDisplay.number) ?? "Unknown sender")
                LabeledContent("To", value: PhoneNumberDisplay.number(viewModel.message.localPhoneNumber))
                LabeledContent(
                    "Received",
                    value: viewModel.message.receivedAt.formatted(date: .abbreviated, time: .shortened)
                )
            }
            Section {
                Text(viewModel.message.body.isEmpty ? "(No text)" : viewModel.message.body)
                    .textSelection(.enabled)
                    .foregroundStyle(viewModel.message.body.isEmpty ? .secondary : .primary)
            } header: {
                Text("Message")
            } footer: {
                if viewModel.message.mediaOmitted {
                    Text("This message had media, which isn't shown.")
                }
            }
        }
        .navigationTitle("Message")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Copy", systemImage: "doc.on.doc", action: viewModel.didTapCopy)
                    .disabled(viewModel.message.body.isEmpty || viewModel.isDeleting)
            }
            ToolbarItem(placement: .primaryAction) {
                if viewModel.isDeleting {
                    ProgressView()
                } else {
                    Button("Delete Message", systemImage: "trash", role: .destructive, action: viewModel.didTapDelete)
                }
            }
        }
        .deleteMessageConfirmation(isPresented: $viewModel.showDeleteConfirmation) {
            Task {
                await viewModel.didConfirmDelete()
            }
        }
        .onChange(of: viewModel.isDeleted) { _, isDeleted in
            guard isDeleted else { return }
            onDeleted()
            dismiss()
        }
        .alert("An error occurred", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .toast($viewModel.toastMessage)
        .task {
            await viewModel.didAppear()
        }
    }
}
