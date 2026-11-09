//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@preconcurrency import SudoTelephonyCommon
import SwiftUI

/// The Sudo's phone numbers, shown on its screen, with a way to get a new one and release existing ones.
struct PhoneNumbersSection: View {

    // MARK: - Properties

    @Bindable var viewModel: PhoneNumbersViewModel

    // MARK: - View

    var body: some View {
        if viewModel.isTelephonyAvailable {
            Section {
                ForEach(viewModel.phoneNumbers, id: \.id) { phoneNumber in
                    Group {
                        if phoneNumber.state == .active {
                            NavigationLink {
                                PhoneMessagesView(phoneNumber: phoneNumber, onReleased: viewModel.didRelease)
                            } label: {
                                PhoneNumberRow(phoneNumber: phoneNumber, unreadCount: viewModel.unreadCount(for: phoneNumber))
                            }
                        } else {
                            PhoneNumberRow(phoneNumber: phoneNumber, unreadCount: 0)
                        }
                    }
                    .swipeActions {
                        // Not `role: .destructive`: in a swipe action that removes the row straight away, but it should stay
                        // until the user confirms and the release succeeds, otherwise the list and its data disagree and crash.
                        Button("Release") {
                            viewModel.didTapRelease(phoneNumber)
                        }
                        .tint(.red)
                    }
                }
                NavigationLink {
                    GetPhoneNumberView(sudoId: viewModel.sudoId, onProvisioned: viewModel.didProvision)
                } label: {
                    Label("Get a Number", systemImage: "plus")
                }
            } header: {
                HStack {
                    Text("Phone Numbers")
                    if viewModel.isLoading {
                        ProgressView()
                    }
                }
            }
            .disabled(viewModel.isLoading)
        } else {
            Section("Phone Numbers") {
                Text("Telephony isn't available in this environment. Its configuration has no telephonyService section.")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// A phone number with its state and how many of its messages are unread.
private struct PhoneNumberRow: View {

    // MARK: - Properties

    let phoneNumber: PhoneNumber

    let unreadCount: Int

    // MARK: - View

    var body: some View {
        HStack {
            UnreadIndicator(isUnread: unreadCount > 0, count: unreadCount)
            Text(PhoneNumberDisplay.number(phoneNumber.phoneNumber))
                .monospacedDigit()
            Spacer()
            Text(phoneNumber.stateDescription)
                .font(.footnote)
                .foregroundStyle(phoneNumber.state == .active ? Color.secondary : Color.orange)
        }
    }
}

extension PhoneNumber {

    /// The number's state in words, including why it failed if it did.
    var stateDescription: String {
        switch state {
        case .provisioning: return "Provisioning…"
        case .active: return "Active"
        case .suspended: return "Suspended"
        case .released: return "Released"
        case .failed:
            switch failureReason {
            case .numberUnavailable: return "Failed: number unavailable"
            case .carrierError: return "Failed: carrier error"
            case .ownerDeleted: return "Failed: Sudo deleted"
            case .unknown(let reason): return "Failed: \(reason)"
            case nil: return "Failed"
            }
        case .unknown(let state): return state
        }
    }
}
