//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@preconcurrency import SudoTelephonyCommon
import SwiftUI

/// Messages received on one of the user's numbers, unread ones marked. Receive only for now; sending and replying come later.
struct PhoneMessagesView: View {

    // MARK: - Properties

    /// Called with the number once released, before this view is dismissed.
    let onReleased: (PhoneNumber) -> Void

    @State private var viewModel: PhoneMessagesViewModel

    @Environment(\.dismiss) private var dismiss

    // MARK: - Lifecycle

    init(phoneNumber: PhoneNumber, onReleased: @escaping (PhoneNumber) -> Void) {
        self.onReleased = onReleased
        _viewModel = State(initialValue: PhoneMessagesViewModel(phoneNumber: phoneNumber))
    }

    // MARK: - View

    var body: some View {
        List(viewModel.messages, id: \.id) { message in
            NavigationLink {
                PhoneMessageView(message: message) {
                    viewModel.didDelete(message)
                }
            } label: {
                PhoneMessageRow(message: message)
            }
            .swipeActions {
                // Not `role: .destructive`, which removes the row straight away, before the user has confirmed.
                Button("Delete") {
                    viewModel.didTapDelete(message)
                }
                .tint(.red)
            }
            .contextMenu {
                Button("Copy", systemImage: "doc.on.doc") {
                    viewModel.didCopy(message)
                }
                .disabled(message.body.isEmpty)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if viewModel.unreadableMessageCount > 0 {
                Label(
                    viewModel.unreadableMessageCount == 1
                        ? "1 message can't be read on this device. Import your keys to read it."
                        : "\(viewModel.unreadableMessageCount) messages can't be read on this device. Import your keys to read them.",
                    systemImage: "key.slash"
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding()
                .frame(maxWidth: .infinity)
                .background(.bar)
            }
        }
        .overlay {
            if viewModel.messages.isEmpty {
                if viewModel.hasLoaded {
                    ContentUnavailableView(
                        "No Messages",
                        systemImage: "message",
                        description: Text("No messages to this number.")
                    )
                } else {
                    ProgressView()
                }
            }
        }
        .navigationTitle(PhoneNumberDisplay.number(viewModel.phoneNumber.phoneNumber))
        .toast($viewModel.toastMessage)
        .deleteMessageConfirmation(isPresented: $viewModel.showDeleteConfirmation) {
            Task {
                await viewModel.didConfirmDelete()
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if viewModel.isReleasing {
                    ProgressView()
                } else {
                    Button("Release Number", systemImage: "trash", role: .destructive, action: viewModel.didTapRelease)
                }
            }
        }
        .releaseNumberConfirmation(isPresented: $viewModel.showReleaseConfirmation, phoneNumber: viewModel.phoneNumber) {
            Task {
                await viewModel.didConfirmRelease()
            }
        }
        .onChange(of: viewModel.releasedNumber) { _, releasedNumber in
            guard let releasedNumber else { return }
            onReleased(releasedNumber)
            dismiss()
        }
        .refreshable {
            await viewModel.didPullToRefresh()
        }
        .task {
            await viewModel.didAppear()
        }
        .onDisappear(perform: viewModel.didDisappear)
        .alert("An error occurred", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

/// A received message: whether it's unread, who it's from, when, and its text.
private struct PhoneMessageRow: View {

    // MARK: - Properties

    let message: PhoneMessage

    // MARK: - View

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            UnreadIndicator(isUnread: !message.seen)
            details
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(message.remotePhoneNumber.map(PhoneNumberDisplay.number) ?? "Unknown sender")
                    .font(.headline)
                    .monospacedDigit()
                Spacer()
                Text(message.receivedAt, format: .dateTime.day().month().hour().minute())
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Text(message.body.isEmpty ? "(No text)" : message.body)
                .lineLimit(2)
                .foregroundStyle(message.body.isEmpty ? .secondary : .primary)
            if message.mediaOmitted {
                Text("Media not shown")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
