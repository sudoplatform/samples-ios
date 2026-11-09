//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Observation
import SudoLogging
@preconcurrency import SudoTelephony
@preconcurrency import SudoTelephonyCommon
@preconcurrency import SudoUser

@Observable
@MainActor
final class PhoneNumbersViewModel {

    // MARK: - Properties

    /// The Sudo's numbers, excluding released ones.
    var phoneNumbers: [PhoneNumber] = []

    /// True while the numbers are being fetched or one is being released.
    var isLoading = false

    /// The number the user asked to release, awaiting confirmation.
    var numberPendingRelease: PhoneNumber?

    /// True if the user should confirm releasing `numberPendingRelease`.
    var showReleaseConfirmation = false

    /// True if `errorMessage` should be presented to the user.
    var showError = false

    var errorMessage = ""

    /// The Sudo whose screen these numbers are shown on. New numbers are provisioned for it.
    let sudoId: String

    /// IDs of each number's unread messages, keyed by phone number ID.
    var unreadMessageIds: [String: Set<String>] = [:]

    /// False if the configured environment has no telephony service.
    var isTelephonyAvailable: Bool {
        dependencies.telephonyClient != nil
    }

    @ObservationIgnored private var updatesSubscription: ActiveSubscription?

    @ObservationIgnored private var messageEventsSubscription: ActiveSubscription?

    @ObservationIgnored private let dependencies: AppDependencies

    // MARK: - Lifecycle

    init(sudoId: String, dependencies: AppDependencies = AppDelegate.dependencies) {
        self.sudoId = sudoId
        self.dependencies = dependencies
    }

    // MARK: - Actions

    /// Fetches the numbers and their unread messages, then starts listening for changes to either, e.g. a new number going from
    /// provisioning to active, or a message arriving.
    func didAppear() async {
        guard let telephonyClient = dependencies.telephonyClient else { return }
        await loadPhoneNumbers(telephonyClient)
        await loadUnreadMessages(telephonyClient)
        await subscribeToUpdates(telephonyClient)
        await subscribeToMessageEvents(telephonyClient)
    }

    func didDisappear() {
        updatesSubscription?.cancel()
        updatesSubscription = nil
        messageEventsSubscription?.cancel()
        messageEventsSubscription = nil
    }

    func unreadCount(for phoneNumber: PhoneNumber) -> Int {
        unreadMessageIds[phoneNumber.id]?.count ?? 0
    }

    func didProvision(_ phoneNumber: PhoneNumber) {
        apply(phoneNumber)
    }

    /// Updates the list with a number released from its messages screen.
    func didRelease(_ phoneNumber: PhoneNumber) {
        apply(phoneNumber)
    }

    func didTapRelease(_ phoneNumber: PhoneNumber) {
        numberPendingRelease = phoneNumber
        showReleaseConfirmation = true
    }

    func didConfirmRelease() async {
        guard let telephonyClient = dependencies.telephonyClient, let phoneNumber = numberPendingRelease else { return }
        numberPendingRelease = nil
        Logger.sampleLogger.info("Releasing phone number...")
        isLoading = true
        defer { isLoading = false }
        do {
            apply(try await telephonyClient.deprovisionPhoneNumber(withId: phoneNumber.id))
        } catch {
            Logger.sampleLogger.error("Failed to release phone number: \(error)")
            await presentError(error)
        }
    }

    // MARK: - Helpers

    private func loadPhoneNumbers(_ telephonyClient: SudoTelephonyClient) async {
        isLoading = true
        defer { isLoading = false }
        do {
            var numbers: [PhoneNumber] = []
            var nextToken: String?
            repeat {
                let page = try await telephonyClient.listPhoneNumbersForSudoId(withInput: ListPhoneNumbersForSudoIdInput(sudoId: sudoId, nextToken: nextToken))
                numbers += page.items
                nextToken = page.nextToken
            } while nextToken != nil
            // The service leaves out released numbers already.
            phoneNumbers = numbers
        } catch {
            Logger.sampleLogger.error("Failed to list phone numbers: \(error)")
            await presentError(error)
        }
    }

    /// Collects the unread messages of each active number. Fine for a sample with a few numbers; an app would want an unread
    /// count from the service instead of listing every message.
    private func loadUnreadMessages(_ telephonyClient: SudoTelephonyClient) async {
        var unread: [String: Set<String>] = [:]
        for phoneNumber in phoneNumbers where phoneNumber.state == .active {
            do {
                var nextToken: String?
                repeat {
                    let input = ListPhoneMessagesForPhoneNumberIdInput(phoneNumberId: phoneNumber.id, nextToken: nextToken)
                    // Messages this device can't decrypt still count: whether they're read isn't sealed.
                    let unseen: [String]
                    switch try await telephonyClient.listPhoneMessagesForPhoneNumberId(withInput: input) {
                    case .success(let page):
                        unseen = page.items.filter { !$0.seen }.map(\.id)
                        nextToken = page.nextToken
                    case .partial(let page):
                        unseen = page.items.filter { !$0.seen }.map(\.id) + page.failed.map(\.partial).filter { !$0.seen }.map(\.id)
                        nextToken = page.nextToken
                    }
                    unread[phoneNumber.id, default: []].formUnion(unseen)
                } while nextToken != nil
            } catch {
                Logger.sampleLogger.error("Failed to list messages for phone number \(phoneNumber.id): \(error)")
            }
        }
        unreadMessageIds = unread
    }

    private func subscribeToUpdates(_ telephonyClient: SudoTelephonyClient) async {
        guard updatesSubscription == nil else { return }
        let subscriber = PhoneNumberUpdatesSubscriber(
            onUpdate: { [weak self] phoneNumber in
                Task { @MainActor in
                    Logger.sampleLogger.info("Phone number update: \(phoneNumber.id) is \(phoneNumber.state.rawValue)")
                    self?.apply(phoneNumber)
                }
            },
            onConnectionChange: { [weak self] state in
                Task { @MainActor in
                    // The subscription has ended; it's opened again the next time the screen appears.
                    guard case .disconnected(let cause) = state else { return }
                    Logger.sampleLogger.error("Phone number subscription disconnected: \(String(describing: cause))")
                    self?.updatesSubscription = nil
                }
            }
        )
        do {
            let token = try await telephonyClient.subscribeToPhoneNumbers(subscriber: subscriber)
            updatesSubscription = ActiveSubscription(token: token, subscriber: subscriber)
            Logger.sampleLogger.info("Subscribed to phone number updates")
        } catch {
            Logger.sampleLogger.error("Failed to subscribe to phone number updates: \(error)")
        }
    }

    /// Keeps the unread counts current as messages arrive, are read, or are deleted.
    private func subscribeToMessageEvents(_ telephonyClient: SudoTelephonyClient) async {
        guard messageEventsSubscription == nil else { return }
        let subscriber = PhoneMessageEventsSubscriber(
            onEvent: { [weak self] event in
                Task { @MainActor in
                    Logger.sampleLogger.info("Phone message event: \(event.id) \(event.changeType.rawValue)")
                    self?.apply(event)
                }
            },
            onConnectionChange: { [weak self] state in
                Task { @MainActor in
                    // The subscription has ended; it's opened again the next time the screen appears.
                    guard case .disconnected(let cause) = state else { return }
                    Logger.sampleLogger.error("Phone message subscription disconnected: \(String(describing: cause))")
                    self?.messageEventsSubscription = nil
                }
            }
        )
        do {
            let token = try await telephonyClient.subscribeToPhoneMessages(subscriber: subscriber)
            messageEventsSubscription = ActiveSubscription(token: token, subscriber: subscriber)
        } catch {
            Logger.sampleLogger.error("Failed to subscribe to phone message events: \(error)")
        }
    }

    private func apply(_ event: PhoneMessageEvent) {
        if event.changeType == .deleted || event.seen {
            unreadMessageIds[event.phoneNumberId]?.remove(event.id)
        } else {
            unreadMessageIds[event.phoneNumberId, default: []].insert(event.id)
        }
    }

    /// Adds or replaces one of this Sudo's numbers, removing it once released. Updates cover all of the user's numbers, so other
    /// Sudos' numbers are ignored.
    private func apply(_ phoneNumber: PhoneNumber) {
        phoneNumbers.removeAll { $0.id == phoneNumber.id }
        guard phoneNumber.state != .released, phoneNumber.sudoId == sudoId else { return }
        phoneNumbers.append(phoneNumber)
        phoneNumbers.sort { $0.createdAt < $1.createdAt }
    }

    /// Shows `error`, unless it means the session has expired, in which case the app goes back to sign in instead.
    private func presentError(_ error: Error) async {
        guard await !dependencies.session.didExpire(after: error) else { return }
        errorMessage = error.localizedDescription
        showError = true
    }
}
