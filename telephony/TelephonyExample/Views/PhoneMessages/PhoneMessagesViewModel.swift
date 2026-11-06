//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Observation
import UIKit
import SudoLogging
@preconcurrency import SudoTelephony
@preconcurrency import SudoTelephonyCommon
@preconcurrency import SudoUser

@Observable
@MainActor
final class PhoneMessagesViewModel {

    // MARK: - Properties

    let phoneNumber: PhoneNumber

    /// Messages received on `phoneNumber`, newest first.
    var messages: [PhoneMessage] = []

    /// How many of the number's messages couldn't be decrypted, e.g. because this device doesn't have the number's key.
    var unreadableMessageCount = 0

    /// True while messages are being fetched.
    var isLoading = false

    /// True while the number is being released.
    var isReleasing = false

    /// True if the user should confirm releasing the number.
    var showReleaseConfirmation = false

    /// The number once released, returned by the service in its released state.
    var releasedNumber: PhoneNumber?

    /// True once the first fetch has finished, so an empty list means there are no messages rather than not loaded yet.
    var hasLoaded = false

    /// Confirmation shown briefly, e.g. after copying a message.
    var toastMessage: String?

    /// The message the user asked to delete, awaiting confirmation.
    var messagePendingDelete: PhoneMessage?

    /// True if the user should confirm deleting `messagePendingDelete`.
    var showDeleteConfirmation = false

    /// True if `errorMessage` should be presented to the user.
    var showError = false

    var errorMessage = ""

    @ObservationIgnored private var eventsToken: SubscriptionToken?

    @ObservationIgnored private let dependencies: AppDependencies

    // MARK: - Lifecycle

    init(phoneNumber: PhoneNumber, dependencies: AppDependencies = AppDelegate.dependencies) {
        self.phoneNumber = phoneNumber
        self.dependencies = dependencies
    }

    // MARK: - Actions

    /// Fetches the messages and starts listening for new ones.
    func didAppear() async {
        guard let telephonyClient = dependencies.telephonyClient else { return }
        await loadMessages(telephonyClient)
        await subscribeToEvents(telephonyClient)
    }

    func didDisappear() {
        eventsToken?.cancel()
        eventsToken = nil
    }

    func didTapRelease() {
        showReleaseConfirmation = true
    }

    func didConfirmRelease() async {
        guard let telephonyClient = dependencies.telephonyClient else { return }
        Logger.sampleLogger.info("Releasing phone number...")
        isReleasing = true
        defer { isReleasing = false }
        do {
            releasedNumber = try await telephonyClient.deprovisionPhoneNumber(id: phoneNumber.id)
        } catch {
            Logger.sampleLogger.error("Failed to release phone number: \(error)")
            await presentError(error)
        }
    }

    func didTapDelete(_ message: PhoneMessage) {
        messagePendingDelete = message
        showDeleteConfirmation = true
    }

    func didConfirmDelete() async {
        guard let telephonyClient = dependencies.telephonyClient, let message = messagePendingDelete else { return }
        messagePendingDelete = nil
        Logger.sampleLogger.info("Deleting phone message \(message.id)...")
        isLoading = true
        defer { isLoading = false }
        do {
            try await telephonyClient.deletePhoneMessage(id: message.id)
            didDelete(message)
        } catch {
            Logger.sampleLogger.error("Failed to delete phone message \(message.id): \(error)")
            await presentError(error)
        }
    }

    /// Removes a message deleted here or from its own screen.
    func didDelete(_ message: PhoneMessage) {
        messages.removeAll { $0.id == message.id }
    }

    func didCopy(_ message: PhoneMessage) {
        UIPasteboard.general.string = message.body
        toastMessage = "Message copied"
    }

    func didPullToRefresh() async {
        guard let telephonyClient = dependencies.telephonyClient else { return }
        await loadMessages(telephonyClient)
    }

    // MARK: - Helpers

    private func loadMessages(_ telephonyClient: SudoTelephonyClient) async {
        isLoading = true
        defer {
            isLoading = false
            hasLoaded = true
        }
        do {
            var loaded: [PhoneMessage] = []
            var unreadable = 0
            var nextToken: String?
            repeat {
                let input = ListPhoneMessagesForPhoneNumberIdInput(phoneNumberId: phoneNumber.id, sortOrder: .descending, nextToken: nextToken)
                switch try await telephonyClient.listPhoneMessagesForPhoneNumberId(input) {
                case .success(let page):
                    loaded += page.items
                    nextToken = page.nextToken
                case .partial(let page):
                    // Messages this device can't decrypt come back without their content, so the rest of the inbox still shows.
                    loaded += page.items
                    unreadable += page.failed.count
                    nextToken = page.nextToken
                }
            } while nextToken != nil
            messages = loaded
            unreadableMessageCount = unreadable
        } catch {
            Logger.sampleLogger.error("Failed to list phone messages: \(error)")
            await presentError(error)
        }
    }

    private func subscribeToEvents(_ telephonyClient: SudoTelephonyClient) async {
        guard eventsToken == nil else { return }
        do {
            eventsToken = try await telephonyClient.subscribeToPhoneMessageEvents { [weak self] result in
                Task { @MainActor in
                    switch result {
                    case .success(let event):
                        Logger.sampleLogger.info("Phone message event: \(event.id) \(event.changeType.rawValue)")
                        await self?.apply(event, telephonyClient: telephonyClient)
                    case .failure(let error):
                        Logger.sampleLogger.error("Phone message subscription failed: \(error)")
                    }
                }
            }
            Logger.sampleLogger.info("Subscribed to phone message events")
        } catch {
            Logger.sampleLogger.error("Failed to subscribe to phone message events: \(error)")
        }
    }

    /// Applies a change to this number's messages. Events only carry IDs, so received and updated messages are fetched.
    private func apply(_ event: PhoneMessageEvent, telephonyClient: SudoTelephonyClient) async {
        guard event.phoneNumberId == phoneNumber.id else { return }
        messages.removeAll { $0.id == event.id }
        guard event.changeType != .deleted else { return }
        do {
            if let message = try await telephonyClient.getPhoneMessage(id: event.id) {
                messages.append(message)
                messages.sort { $0.receivedAt > $1.receivedAt }
            }
        } catch {
            Logger.sampleLogger.error("Failed to fetch phone message \(event.id): \(error)")
        }
    }

    /// Shows `error`, unless it means the session has expired, in which case the app goes back to sign in instead.
    private func presentError(_ error: Error) async {
        guard await !dependencies.session.didExpire(after: error) else { return }
        errorMessage = error.localizedDescription
        showError = true
    }
}
