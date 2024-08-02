//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoEmail
import SudoProfiles

/// This View Controller presents a list of `EmailMessage` associated with an `EmailAddress`.
///
/// - Links From:
///     - `EmailAddressListViewController`: A user chooses an `EmailAddress` which will show this view with the list of email messages for this email address.
/// - Links To:
///     - `ReadEmailMessageViewController`: If a user taps on an `EmailMessage`, the `ReadEmailMessageViewController` will be presented so the
///         user can read the email message.
///     - `CreateEmailMessageViewController`: If a user taps the "Create Email Message" button, the `CreateEmailMessageViewController` will be presented so the
///         user can send a new email message.
final class EmailMessageListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, FolderSwitcherViewDelegate {

    // MARK: - Outlets

    /// The table view that lists each email message associated with the chosen `EmailAddress` from the previous view.
    ///
    /// If the user does not have any `EmailMessages` associated to this `EmailAddress`, then only the "Send Email Message" entry will be seen.
    /// This can be tapped to send an email.
    @IBOutlet var tableView: UITableView!

    // MARK: - Supplementary

    /// Defaults used in `EmailMessageListViewController`.
    enum Defaults {
        /// Limit used when querying email messages from `SudoEmailClient`.
        static let emailListLimit = 30
    }

    /// Segues that are performed in `EmailMessageListViewController`.
    enum Segue: String {
        /// Used to navigate to the `SendEmailMessageViewController`.
        case navigateToSendEmailMessage
        /// Used to navigate to the `ReadEmailMessageViewController`.
        case navigateToReadEmailMessage
        /// Used to navigate to the `EmailAddressSettingsViewController`.
        case navigateToEmailAddressSettings
        /// Used to navigate back to the `EmailAddressListViewController`.
        case returnToEmailAddressList
    }

    // MARK: - Properties

    /// Address of a `EmailAddress` that was selected from the previous view. Used to present to the user.
    var emailAddress: EmailAddress?

    /// A list of `EmailMessage` that are associated with the `emailAddress`.
    var emailMessages: [EmailMessage] = []

    /// A list of blocked email addresses associated with the `emailAddress`
    var blockedAddresses: [String] = []

    /// Blocked addresses that have been selected for unblocking
    var selectedBlockedAddresses: [String] = []

    /// View to allow user selection of Email Folder
    var folderNameSwitcher: FolderSwitcherView!

    /// EmailMessage subscription token. Used to cancel the subscription when the user navigates away from the view
    var allEmailMessagesCreatedSubscriptionToken: SubscriptionToken?

    var allEmailMessagesDeletedSubscriptionToken: SubscriptionToken?

    /// The currently folder that is open
    var selectedFolder: FolderType = FolderType.inbox

    // MARK: - Properties: Computed

    /// Email client used to get and create email addresses.
    var emailClient: SudoEmailClient {
        return AppDelegate.dependencies.emailClient
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        configureNavigationBar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard validateViewInputEmailAddress() else {
            Task { @MainActor in
                presentErrorAlert(message: "An error has occurred: no email address found") { _ in
                    self.performSegue(withIdentifier: Segue.returnToEmailAddressList.rawValue, sender: self)
                }
            }
            return
        }
        do {
            Task.detached(priority: .medium) { [weak self] in
                guard let weakSelf = self else { return }
                do {
                    try await weakSelf.subscribeToAllEmailMessagesCreated()
                    try await weakSelf.subscribeToAllEmailMessagesDeleted()
                } catch {
                    Task { @MainActor in
                        weakSelf.presentErrorAlert(message: "Failed to subscribe to email message events", error: error)
                    }
                }
            }
        }
        Task.detached(priority: .medium) {
            await self.loadCacheEmailMessagesAndFetchRemote()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeToAllSubscriptions()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let segueType = Segue(rawValue: segue.identifier ?? "")
        switch segueType {
        case .navigateToSendEmailMessage:
            guard let sendEmailMessage = segue.destination as? SendEmailMessageViewController else {
                break
            }
            sendEmailMessage.emailAddress = emailAddress

        case .navigateToReadEmailMessage:
            guard let readEmailMessage = segue.destination as? ReadEmailMessageViewController,
                  let row = tableView.indexPathForSelectedRow?.row else {
                break
            }
            readEmailMessage.emailMessage = emailMessages[row]
            readEmailMessage.emailAddress = emailAddress

        case .navigateToEmailAddressSettings:
            guard let emailAddressSettings = segue.destination as? EmailAddressSettingsViewController else {
                break
            }
            emailAddressSettings.emailAddress = emailAddress

        default:
            break
        }
    }

    // MARK: - Actions

    /// Action associated with returning to this view from a segue.
    ///
    /// This action will ensure that the email message list is up to date when returning from views - e.g. `SendEmailMessageViewController`.
    @IBAction func returnToEmailMessageList(segue: UIStoryboardSegue) {
        Task.detached(priority: .medium) {
            await self.loadCacheEmailMessagesAndFetchRemote()
        }
    }

    @objc func didTapComposeEmailButton() {
        performSegue(withIdentifier: Segue.navigateToSendEmailMessage.rawValue, sender: self)
    }

    @objc func didTapEmailAddressSettingsButton() {
        performSegue(withIdentifier: Segue.navigateToEmailAddressSettings.rawValue, sender: self)
    }

    // MARK: - Operations

    func listEmailMessages(cachePolicy: SudoEmail.CachePolicy) async throws -> [EmailMessage] {
        guard let emailAddress = emailAddress else {
            Task { @MainActor in
                presentErrorAlert(message: "An error has occurred: no email address found") { _ in
                    self.performSegue(withIdentifier: Segue.returnToEmailAddressList.rawValue, sender: self)
                }
            }
            return []
        }
        let folderId = generateFolderId(
            emailAddressId: emailAddress.id,
            folderName: folderNameSwitcher.titleForCurrentFolder()
        )
        let listEmailMessagesInput = ListEmailMessagesForEmailFolderIdInput(
            emailFolderId: folderId,
            cachePolicy: cachePolicy
        )
        let messagesResult = try await emailClient.listEmailMessagesForEmailFolderId(
            withInput: listEmailMessagesInput
        )
        switch messagesResult {
        case .success(let successResult):
            return successResult.items
        case .partial(let partialResult):
            let failedMessageIds = partialResult.failed.map { partial in
                partial.partial.id
            }
            presentErrorAlert(message: "Failed to list email messages \(failedMessageIds)")
            return partialResult.items
        @unknown default:
            fatalError("Unknown message result \(messagesResult)")
        }
    }

    func listDraftEmailMessages() async throws -> [EmailMessage] {
        guard let emailAddressId = emailAddress?.id else {
            Task { @MainActor in
                presentErrorAlert(message: "An error has occurred: no email address found") { _ in
                    self.performSegue(withIdentifier: Segue.returnToEmailAddressList.rawValue, sender: self)
                }
            }
            return []
        }
        presentActivityAlert(message: "Listing Draft Email Messages")
        let draftsMetadata = try await emailClient.listDraftEmailMessageMetadataForEmailAddressId(emailAddressId: emailAddressId)
        var draftMessages: [EmailMessage] = []
        if draftsMetadata.isEmpty {
            dismissActivityAlert()
            return draftMessages
        }
        for i in 0...draftsMetadata.count - 1 {
            let input = GetDraftEmailMessageInput(id: draftsMetadata[i].id, emailAddressId: emailAddressId)
            guard let draft = try await emailClient.getDraftEmailMessage(withInput: input) else {
                continue
            }
            guard let emailDraft = transformDraftToEmailMessage(
                draft: draft,
                emailAddressId: emailAddressId
            ) else {
                continue
            }
            draftMessages.append(emailDraft)
        }
        dismissActivityAlert()
        return draftMessages.sortedByCreatedDescending()
    }

    func deleteEmailMessage(_ id: String) async throws -> String {
        presentActivityAlert(message: "Deleting Email Message")
        guard let deletedMessageId = try await emailClient.deleteEmailMessage(withId: id) else {
            self.dismissActivityAlert()
            throw SudoEmailError.emailMessageNotFound
        }
        self.dismissActivityAlert()
        return deletedMessageId
    }

    func subscribeToAllEmailMessagesCreated() async throws {
        allEmailMessagesCreatedSubscriptionToken = try await emailClient.subscribeToEmailMessageCreated(withDirection: nil) { [weak self] result in
            guard let weakSelf = self else { return }
            switch result {
            case .success:
                Task.detached(priority: .medium) {
                    do {
                        let messages = try await weakSelf.listEmailMessages(cachePolicy: .remoteOnly)
                        Task { @MainActor in
                            let emailAddress = weakSelf.emailAddress?.emailAddress ?? ""
                            let sortedMessages = weakSelf
                                .filterEmailMessages(messages, withEmailAddress: emailAddress)
                                .sortedByCreatedDescending()
                            weakSelf.emailMessages = sortedMessages
                            weakSelf.tableView.reloadData()
                        }
                    } catch {
                        NSLog("ignoring listEmailMessages failure")
                    }
                }
            case let .failure(error):
                Task { @MainActor in
                    weakSelf.presentErrorAlert(message: "Email message created subscription failure", error: error)
                }
            }
        }
    }

    func subscribeToAllEmailMessagesDeleted() async throws {
        allEmailMessagesDeletedSubscriptionToken = try await emailClient.subscribeToEmailMessageDeleted(
            withId: nil,
            resultHandler: { [weak self] result in
                guard let weakSelf = self else { return }
                switch result {
                case .success:
                    Task.detached(priority: .medium) {
                        do {
                            let messages = try await weakSelf.listEmailMessages(cachePolicy: .remoteOnly)
                            Task { @MainActor in
                                let emailAddress = weakSelf.emailAddress?.emailAddress ?? ""
                                let sortedMessages = weakSelf
                                    .filterEmailMessages(messages, withEmailAddress: emailAddress)
                                    .sortedByCreatedDescending()
                                weakSelf.emailMessages = sortedMessages
                                weakSelf.tableView.reloadData()
                            }
                        } catch {
                            NSLog("ignoring listEmailMessages failure")
                        }
                    }
                case let .failure(error):
                    Task { @MainActor in
                        weakSelf.presentErrorAlert(message: "Email message deleted subscription failure", error: error)
                    }
                }
            }
        )
    }

    func unsubscribeToAllSubscriptions() {
        allEmailMessagesCreatedSubscriptionToken?.cancel()
        allEmailMessagesDeletedSubscriptionToken?.cancel()
    }

    // MARK: - Helpers: Configuration

    /// Configures the table view used to display the navigation elements.
    func configureTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "folders")
        tableView.register(
            FolderSwitcherView.self,
            forHeaderFooterViewReuseIdentifier: "folderSwitcher"
        )
        let emailMessageCell = UINib(nibName: "EmailMessageTableViewCell", bundle: .main)
        tableView.register(emailMessageCell, forCellReuseIdentifier: "emailMessageCell")
        let blockedAddressCell = UINib(nibName: "BlockedAddressTableViewCell", bundle: .main)
        tableView.register(blockedAddressCell, forCellReuseIdentifier: "blockedAddressCell")
        tableView.tableFooterView = UIView()
    }

    func configureNavigationBar() {
        let gearImage = UIImage(systemName: "gearshape")
        let emailAddressSettingsBarButton = UIBarButtonItem(
                image: gearImage,
                style: .plain,
                target: self,
                action: #selector(didTapEmailAddressSettingsButton)
        )

        let composeBarButton = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(didTapComposeEmailButton))
        navigationItem.rightBarButtonItems = [emailAddressSettingsBarButton, composeBarButton]
    }

    // MARK: - Helpers

    /// Firstly, attempts to load all the email addresses from the device's cache, and then update via a remote call.
    ///
    /// On any failure, either by cache or remote call, a "Failed to list email messages" UIAlert message will be presented to the user.
    ///
    /// All email messages will be filtered using the `emailAddress` to ensure only email messages associated with the email address are listed.
    func loadCacheEmailMessagesAndFetchRemote() async {
        do {
            if folderNameSwitcher.currentFolder == .drafts {
                self.emailMessages = try await listDraftEmailMessages()
                Task { @MainActor in
                    self.tableView.reloadData()
                }
                return
            }
            let localMessages = try await listEmailMessages(cachePolicy: .cacheOnly)

            self.emailMessages = localMessages.sortedByCreatedDescending()
            Task { @MainActor in
                self.tableView.reloadData()
            }

            let remoteMessages = try await listEmailMessages(cachePolicy: .remoteOnly)

            self.emailMessages = remoteMessages.sortedByCreatedDescending()
            Task { @MainActor in
                self.tableView.reloadData()
            }
        } catch {
            Task { @MainActor in
                self.presentErrorAlert(message: "Failed to list Email Messages", error: error)
            }
        }
    }

    /// Loads the list of blocked email addresses for the user
    func loadBlockedAddresses() async {
        do {
            let result = try await self.emailClient.getEmailAddressBlocklist()
            var cleartextAddresses: [String] = []
            result.forEach {
                switch $0.status {
                case .completed:
                    cleartextAddresses.append($0.address)
                default:
                    // Handle error. Likely a missing key in which case address can be unblocked by hashedValue
                    NSLog("Error")
                }
            }
            self.blockedAddresses = cleartextAddresses
            Task { @MainActor in
                self.tableView.reloadData()
            }
        } catch {
            Task { @MainActor in
                self.presentErrorAlert(message: "Failed to list blocked addresses", error: error)
            }
        }
    }

    /// Validates that the input email address exists and is not empty.
    func validateViewInputEmailAddress() -> Bool {
        guard let emailAddress = emailAddress else {
            return false
        }
        return !emailAddress.emailAddress.isEmpty
    }

    /// Filter a list of email messages by an email address.
    ///
    /// Returns any elements of `emailMessages` where the `address` matches again `to`, `cc`, or `bcc` properties.
    ///
    /// - Parameters:
    ///   - emailMessages: Array of email messages to be filtered.
    ///   - emailAddress: Email address to use to filter the email messages.
    /// - Returns: Filtered email messages.
    func filterEmailMessages(_ emailMessages: [EmailMessage], withEmailAddress address: String) -> [EmailMessage] {
        return emailMessages
            .filter { message in
                let to = message.to.map(\.address)
                let from = message.from.map(\.address)
                let cc = message.cc.map(\.address)
                let bcc = message.bcc.map(\.address)
                return to.contains(address) || from.contains(address) || cc.contains(address) || bcc.contains(address)
            }
    }

    func deleteEmailMessage(forIndexPath indexPath: IndexPath) async -> Bool {
        guard let emailAddress = emailAddress else {
            Task { @MainActor in
                presentErrorAlert(message: "An error has occurred: no email address found") { _ in
                    self.performSegue(withIdentifier: Segue.returnToEmailAddressList.rawValue, sender: self)
                }
            }
            return false
        }
        let emailMessage = emailMessages.remove(at: indexPath.row)
        if folderNameSwitcher.currentFolder == .trash {
            // permanently delete email message
            Task { @MainActor in
                self.tableView.reloadData()
            }
            do {
                _ = try await deleteEmailMessage(emailMessage.id)
                // Do a call to service to update cache.
                _ = try await self.listEmailMessages(cachePolicy: .remoteOnly)
                self.dismissActivityAlert()
                return true
            } catch {
                Task { @MainActor in
                    self.emailMessages.insert(emailMessage, at: indexPath.row)
                    self.tableView.reloadData()
                    self.dismissActivityAlert()
                }
                return false
            }
        } else if folderNameSwitcher.currentFolder == .drafts {
            do {
                let input = DeleteDraftEmailMessagesInput(ids: [emailMessage.id], emailAddressId: emailAddress.id)
                presentActivityAlert(message: "Deleting Draft Email Message")
                _ = try await emailClient.deleteDraftEmailMessages(withInput: input)
                Task { @MainActor in
                    self.tableView.reloadData()
                    self.dismissActivityAlert()
                }
                return true
            } catch {
                Task { @MainActor in
                    self.emailMessages.insert(emailMessage, at: indexPath.row)
                    self.tableView.reloadData()
                    self.dismissActivityAlert()
                }
                return false
            }
        } else {
            // move email message to trash folder
            presentActivityAlert(message: "Moving to Trash")
            let folderId = generateFolderId(
                emailAddressId: emailAddress.id,
                folderName: "TRASH"
            )
            let input = UpdateEmailMessagesInput(
                ids: [emailMessage.id],
                values: UpdateEmailMessagesValues(
                    folderId: folderId,
                    seen: emailMessage.seen
                )
            )
            do {
                let result = try await emailClient.updateEmailMessages(withInput: input)
                switch result.status {
                case .success:
                    self.tableView.reloadData()
                    // Do a call to service to update cache.
                    _ = try await self.listEmailMessages(cachePolicy: .remoteOnly)
                    self.dismissActivityAlert()
                    return true
                default:
                    Task { @MainActor in
                        self.emailMessages.insert(emailMessage, at: indexPath.row)
                        self.tableView.reloadData()
                        self.dismissActivityAlert()
                    }
                    return false
                }
            } catch {
                Task { @MainActor in
                    self.emailMessages.insert(emailMessage, at: indexPath.row)
                    self.tableView.reloadData()
                    self.dismissActivityAlert()
                }
                return false
            }
        }
    }

    func generateFolderId(emailAddressId: String, folderName: String) -> String {
        return "\(emailAddressId)-\(folderName.uppercased())"
    }

    /// A simple method to create a dummy EmailMessage object based on a DraftEmailMessage object to
    /// allow draft email messages to be displayed OK.
    func transformDraftToEmailMessage(draft: DraftEmailMessage, emailAddressId: String) -> EmailMessage? {
        var rfc822Message: BasicRFC822Message
        do {
            rfc822Message = try RFC822Util.fromPlainText(draft.rfc822Data)
        } catch {
            Task { @MainActor in
                self.presentErrorAlert(message: "Failed to parse draft email message", error: error)
            }
            return nil
        }
        let fromAddress = EmailAddressAndName(address: rfc822Message.from)
        let emailDraft = EmailMessage(
            id: draft.id,
            clientRefId: "draftClientRefId",
            owner: "draftOwnerId",
            owners: [.init(id: "draftOwnerId", issuer: "drafts")],
            emailAddressId: emailAddressId,
            folderId: generateFolderId(
                emailAddressId: emailAddressId,
                folderName: folderNameSwitcher.titleForCurrentFolder()
            ),
            previousFolderId: nil,
            createdAt: draft.updatedAt,
            updatedAt: draft.updatedAt,
            sortDate: draft.updatedAt,
            seen: true,
            direction: .outbound,
            state: .undelivered,
            version: 1,
            size: Double(draft.rfc822Data.count),
            from: [fromAddress],
            replyTo: [fromAddress],
            to: rfc822Message.to.map { EmailAddressAndName(address: $0) },
            cc: rfc822Message.cc.map { EmailAddressAndName(address: $0) },
            bcc: rfc822Message.bcc.map { EmailAddressAndName(address: $0) },
            subject: rfc822Message.subject,
            hasAttachments: false,
            encryptionStatus: EncryptionStatus.UNENCRYPTED,
            date: nil
        )
        return emailDraft
    }

    func deleteEmailMessages() async {
        do {
            self.presentActivityAlert(message: "Deleting Email Messages")
            let emailMessageIds = self.emailMessages.map { $0.id }
            let result = try await self.emailClient.deleteEmailMessages(
                withIds: emailMessageIds
            )
            switch result.status {
            case .success:
                self.dismissActivityAlert()
            case .failure:
                self.dismissActivityAlert()
                self.presentErrorAlert(message: "Failed to empty Trash folder")
            case .partial:
                self.dismissActivityAlert()
                self.presentErrorAlert(message: "Failed to delete email messages \(result.failureItems ?? [])")
            @unknown default:
                fatalError("Unhandled unknown status \(String(describing: result.status))")
            }
        } catch {
            self.dismissActivityAlert()
            self.presentErrorAlert(message: "Failed to empty Trash folder \(error)")
        }
    }

    // MARK: - Conformance: UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.selectedFolder == FolderType.blocklist {
            return blockedAddresses.count
        }
        return emailMessages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        assert(indexPath.section == 0)
        if self.selectedFolder == FolderType.blocklist {
            let blockedAddress = blockedAddresses[indexPath.row]
            guard let blockedAddressCell = tableView.dequeueReusableCell(
                withIdentifier: "blockedAddressCell", for: indexPath
            ) as? BlockedAddressTableViewCell else {
                return BlockedAddressTableViewCell()
            }
            blockedAddressCell.emailAddress = blockedAddress
            blockedAddressCell.accessoryType = .disclosureIndicator
            return blockedAddressCell
        } else {
            let emailMessage = emailMessages[indexPath.row]
            guard let emailMessageCell = tableView.dequeueReusableCell(
                withIdentifier: "emailMessageCell", for: indexPath
            ) as? EmailMessageTableViewCell else {
                return EmailMessageTableViewCell()
            }
            emailMessageCell.emailMessage = emailMessage
            emailMessageCell.accessoryType = .disclosureIndicator
            return emailMessageCell
        }
    }

    // MARK: - Conformance: UITableViewDelegate

    @MainActor
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if selectedFolder == FolderType.blocklist {
            let address = blockedAddresses[indexPath.row]
            if selectedBlockedAddresses.contains(address) {
                selectedBlockedAddresses.remove(at: selectedBlockedAddresses.firstIndex(of: address)!)
                tableView.deselectRow(at: indexPath, animated: true)
            } else {
                selectedBlockedAddresses.append(address)
            }
        } else {
            performSegue(withIdentifier: Segue.navigateToReadEmailMessage.rawValue, sender: self)
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    @MainActor
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let cancel = UIContextualAction(style: .destructive, title: "Delete") { _, _, completion in
            Task.detached(priority: .medium) {
                _ = await self.deleteEmailMessage(forIndexPath: indexPath)
                completion(true)
            }
        }
        cancel.backgroundColor = .red
        return UISwipeActionsConfiguration(actions: [cancel])
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        folderNameSwitcher = tableView.dequeueReusableHeaderFooterView(withIdentifier: "folderSwitcher") as? FolderSwitcherView
        folderNameSwitcher.delegate = self
        return folderNameSwitcher
    }

    // MARK: Conformance: - FolderSwitcherViewDelegate

    func folderSwitcherView(
        _ view: FolderSwitcherView,
        didSelectFolderType folderType: FolderType
    ) {
        self.selectedFolder = folderType
        blockedAddresses = []
        emailMessages = []
        if self.selectedFolder == FolderType.blocklist {
            Task { @MainActor in
                await self.loadBlockedAddresses()
            }
        } else {
            Task { @MainActor in
                await self.loadCacheEmailMessagesAndFetchRemote()
            }
        }
    }

    @MainActor
    func emptyTrash() {
        let alert = UIAlertController(
            title: "Empty Trash Folder",
            message: "Are you sure you want to empty the Trash folder? All email messages in the Trash folder will be permanently deleted.",
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Empty Trash", style: .default) { _ in
            Task.detached(priority: .medium) {
                await self.deleteEmailMessages()
            }
        })
        present(alert, animated: true, completion: nil)
    }

    @MainActor
    func unblockEmailAddresses() {
        presentActivityAlert(message: "Unblocking Email Address")
        Task.init {
            do {
                let result = try await self.emailClient.unblockEmailAddresses(addresses: selectedBlockedAddresses)

                switch result.status {
                case .success:
                    self.dismissActivityAlert()
                    self.presentAlert(title: "Success", message: "Email address(es) unblocked")
                    blockedAddresses = blockedAddresses.filter { item in
                        !selectedBlockedAddresses.contains(item)
                    }
                case .partial:
                    self.dismissActivityAlert()
                    self.presentErrorAlert(message: "Unable to unblock some addresses. Please try again")
                    blockedAddresses = blockedAddresses.filter { item in
                        !result.successItems!.contains(item)
                    }
                case .failure:
                    self.dismissActivityAlert()
                    self.presentErrorAlert(message: "Failed to unblock email address(es). Please try again")
                @unknown default:
                    fatalError("Unhandled unknown status \(String(describing: result.status))")
                }
                Task { @MainActor in
                    self.tableView.reloadData()
                }
            } catch {
                Task { @MainActor in
                    self.dismissActivityAlert()
                    self.presentErrorAlert(message: "Failed to unblock email address(es). Please try again", error: error)
                }
            }
        }
    }
}
