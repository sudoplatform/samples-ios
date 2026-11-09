//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Observation
import SudoLogging
@preconcurrency import SudoTelephony
@preconcurrency import SudoTelephonyCommon
import UIKit

@Observable
@MainActor
final class PhoneMessageViewModel {

    // MARK: - Properties

    let message: PhoneMessage

    /// Confirmation shown briefly after the message text has been copied.
    var toastMessage: String?

    /// True if the user should confirm deleting the message.
    var showDeleteConfirmation = false

    /// True while the message is being deleted.
    var isDeleting = false

    /// True once the message has been deleted.
    var isDeleted = false

    /// True if `errorMessage` should be presented to the user.
    var showError = false

    var errorMessage = ""

    @ObservationIgnored private let dependencies: AppDependencies

    // MARK: - Lifecycle

    init(message: PhoneMessage, dependencies: AppDependencies = AppDelegate.dependencies) {
        self.message = message
        self.dependencies = dependencies
    }

    // MARK: - Actions

    /// Marks the message as read the first time it's opened.
    func didAppear() async {
        guard !message.seen, let telephonyClient = dependencies.telephonyClient else { return }
        do {
            _ = try await telephonyClient.updatePhoneMessages(withInput: UpdatePhoneMessagesInput(ids: [message.id], seen: true))
            Logger.sampleLogger.info("Marked phone message \(message.id) as read")
        } catch {
            // Not worth interrupting the user for; the message stays unread and is marked next time it's opened.
            Logger.sampleLogger.error("Failed to mark phone message \(message.id) as read: \(error)")
        }
    }

    func didTapDelete() {
        showDeleteConfirmation = true
    }

    func didConfirmDelete() async {
        guard let telephonyClient = dependencies.telephonyClient else { return }
        Logger.sampleLogger.info("Deleting phone message \(message.id)...")
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await telephonyClient.deletePhoneMessage(id: message.id)
            isDeleted = true
        } catch {
            Logger.sampleLogger.error("Failed to delete phone message \(message.id): \(error)")
            // If the session has expired, the app goes back to sign in instead of showing the error.
            guard await !dependencies.session.didExpire(after: error) else { return }
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func didTapCopy() {
        UIPasteboard.general.string = message.body
        toastMessage = "Message copied"
    }
}
