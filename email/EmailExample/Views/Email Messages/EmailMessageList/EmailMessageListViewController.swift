//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
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
class EmailMessageListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // MARK: - Outlets

    /// The table view that lists each email message associated with the chosen `EmailAddress` from the previous view.
    ///
    /// If the user does not have any `EmailMessages` associated to this `EmailAddress`, then only the "Send Email Message" entry will be seen.
    /// This can be tapped to send an email.
    @IBOutlet var tableView: UITableView!

    // MARK: - Supplementary

    /// Typealias for a successful response call to `SudoEmailClient.getEmailMessagesWithFilter(_:limit:nextToken:cachePolicy:completion:)`.
    typealias EmailMessageListSuccessCompletion = ([EmailMessage]) -> Void

    /// Typealias for a error response call to `SudoEmailClient.getEmailMessagesWithFilter(_:limit:nextToken:cachePolicy:completion:)`.
    typealias EmailMessageListErrorCompletion = (Error) -> Void

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
        /// Used to navigate back to the `EmailAddressListViewController`.
        case returnToEmailAddressList
    }

    // MARK: - Properties

    /// Address of a `EmailAddress` that was selected from the previous view. Used to present to the user.
    var emailAddress: EmailAddress?

    /// A list of `EmailMessage` that are associated with the `emailAddress`.
    var emailMessages: [EmailMessage] = []

    /// EmailMessage subscription token. Used to cancel the subscription when the user navigates away from the view
    var allEmailMessagesCreatedSubscriptionToken: SubscriptionToken?

    var allEmailMessagesDeletedSubscriptionToken: SubscriptionToken?

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
            presentErrorAlert(message: "An error has occurred: no email address found") { _ in
                self.performSegue(withIdentifier: Segue.returnToEmailAddressList.rawValue, sender: self)
            }
            return
        }
        do {
            try subscribeToAllEmailMessagesCreated()
            try subscribeToAllEmailMessagesDeleted()
        } catch {
            presentErrorAlert(message: "Failed to subscribe to email message events", error: error)
        }
        loadCacheEmailMessagesAndFetchRemote()
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
            guard let readEmailMessage = segue.destination as? ReadEmailMessageViewController, let row = tableView.indexPathForSelectedRow?.row else {
                break
            }
            readEmailMessage.emailMessage = emailMessages[row]
            readEmailMessage.emailAddress = emailAddress
        default:
            break
        }
    }

    // MARK: - Actions

    /// Action associated with returning to this view from a segue.
    ///
    /// This action will ensure that the email message list is up to date when returning from views - e.g. `SendEmailMessageViewController`.
    @IBAction func returnToEmailMessageList(segue: UIStoryboardSegue) {
        loadCacheEmailMessagesAndFetchRemote()
    }

    @objc func didTapComposeEmailButton() {
        performSegue(withIdentifier: Segue.navigateToSendEmailMessage.rawValue, sender: self)
    }

    // MARK: - Operations

    func listEmailMessages(
        cachePolicy: SudoEmail.CachePolicy,
        success: EmailMessageListSuccessCompletion? = nil,
        failure: EmailMessageListErrorCompletion? = nil
    ) {
        emailClient.getEmailMessagesWithFilter(nil, limit: Defaults.emailListLimit, nextToken: nil, cachePolicy: cachePolicy) { result in
            switch result {
            case let .success(output):
                success?(output.items)
            case let .failure(error):
                failure?(error)
            }
        }
    }

    func deleteEmailMessage(_ id: String, _ completion: @escaping (Result<String, Error>) -> Void) {
        presentActivityAlert(message: "Deleting Email Message")
        emailClient.deleteEmailMessage(withId: id) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.dismissActivityAlert()
                case let .failure(error):
                    self?.dismissActivityAlert {
                        self?.presentErrorAlert(message: "Failed to delete email message", error: error)
                    }
                }
                completion(result)
            }
        }
    }

    func subscribeToAllEmailMessagesCreated() throws {
        allEmailMessagesCreatedSubscriptionToken = try emailClient.subscribeToEmailMessageCreated { [weak self] result in
            guard let weakSelf = self else { return }
            switch result {
            case .success:
                weakSelf.listEmailMessages(
                    cachePolicy: .useOnline,
                    success: { messages in
                        DispatchQueue.main.async {
                            let emailAddress = weakSelf.emailAddress?.address ?? ""
                            let sortedMessages = weakSelf
                                .filterEmailMessages(messages, withEmailAddress: emailAddress)
                                .sortedByCreatedDescending()
                            weakSelf.emailMessages = sortedMessages
                            weakSelf.tableView.reloadData()
                        }
                    },
                    failure: nil
                )
            case let .failure(error):
                DispatchQueue.main.async {
                    weakSelf.presentErrorAlert(message: "Email message created subscription failure", error: error)
                }
            }
        }
    }

    func subscribeToAllEmailMessagesDeleted() throws {
        allEmailMessagesDeletedSubscriptionToken = try emailClient.subscribeToEmailMessageDeleted { [weak self] result in
            guard let weakSelf = self else { return }
            switch result {
            case .success:
                weakSelf.listEmailMessages(
                    cachePolicy: .useOnline,
                    success: { messages in
                        DispatchQueue.main.async {
                            let emailAddress = weakSelf.emailAddress?.address ?? ""
                            let sortedMessages = weakSelf
                                .filterEmailMessages(messages, withEmailAddress: emailAddress)
                                .sortedByCreatedDescending()
                            weakSelf.emailMessages = sortedMessages
                            weakSelf.tableView.reloadData()
                        }
                    },
                    failure: nil
                )
            case let .failure(error):
                DispatchQueue.main.async {
                    weakSelf.presentErrorAlert(message: "Email message deleted subscription failure", error: error)
                }
            }
        }
    }

    func unsubscribeToAllSubscriptions() {
        allEmailMessagesCreatedSubscriptionToken?.cancel()
        allEmailMessagesDeletedSubscriptionToken?.cancel()
    }

    // MARK: - Helpers: Configuration

    /// Configures the table view used to display the navigation elements.
    func configureTableView() {
        let emailMessageCell = UINib(nibName: "EmailMessageTableViewCell", bundle: .main)
        tableView.register(emailMessageCell, forCellReuseIdentifier: "emailMessageCell")
        tableView.tableFooterView = UIView()
    }

    func configureNavigationBar() {
        let composeBarButton = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(didTapComposeEmailButton))
        navigationItem.rightBarButtonItem = composeBarButton
    }

    // MARK: - Helpers

    /// Firstly, attempts to load all the email addresses from the device's cache, and then update via a remote call.
    ///
    /// On any failure, either by cache or remote call, a "Failed to list email messages" UIAlert message will be presented to the user.
    ///
    /// All email messages will be filtered using the `emailAddress` to ensure only email messages associated with the email address are listed.
    func loadCacheEmailMessagesAndFetchRemote() {
        /// Called on failure.
        let failureCompletion: EmailMessageListErrorCompletion = { [weak self] error in
            DispatchQueue.main.async {
                self?.presentErrorAlert(message: "Failed to list Email Messages", error: error)
            }
        }
        /// Called to handle filtering success result and updating data.
        let filterCompletion: (([EmailMessage]) -> Void) = { [weak self] messages in
            guard let weakSelf = self else { return }
            let emailAddress = weakSelf.emailAddress?.address ?? ""
            let sortedMessages = weakSelf
                .filterEmailMessages(messages, withEmailAddress: emailAddress)
                .sortedByCreatedDescending()
            weakSelf.emailMessages = sortedMessages
            weakSelf.tableView.reloadData()
        }
        listEmailMessages(
            cachePolicy: .useCache,
            success: { [weak self] emailMessages in
                guard let weakSelf = self else { return }
                DispatchQueue.main.async {
                    filterCompletion(emailMessages)
                }
                weakSelf.listEmailMessages(
                    cachePolicy: .useOnline,
                    success: { emailMessages in
                        DispatchQueue.main.async {
                            filterCompletion(emailMessages)
                        }
                    },
                    failure: failureCompletion
                )
            },
            failure: failureCompletion
        )
    }

    /// Validates that the input email address exists and is not empty.
    func validateViewInputEmailAddress() -> Bool {
        guard let emailAddress = emailAddress else {
            return false
        }
        return !emailAddress.address.isEmpty
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
            .filter {
                $0.address == address
                || $0.to.contains(address)
                || $0.cc.contains(address)
                || $0.bcc.contains(address)
            }
    }

    func deleteEmailMessage(forIndexPath indexPath: IndexPath, completion: @escaping (Bool) -> Void) {
        let emailMessage = emailMessages.remove(at: indexPath.row)
        self.tableView.reloadData()
        deleteEmailMessage(emailMessage.id) { [weak self] result in
            guard let weakSelf = self else { return }
            switch result {
            case .success:
                // Do a call to service to update cache.
                weakSelf.listEmailMessages(cachePolicy: .useOnline)
                completion(true)
            case .failure:
                DispatchQueue.main.async {
                    weakSelf.emailMessages.insert(emailMessage, at: indexPath.row)
                    weakSelf.tableView.reloadData()
                }
                completion(false)
            }

        }
    }

    // MARK: - Conformance: UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return emailMessages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let emailMessage = emailMessages[indexPath.row]
        guard let emailMessageCell = tableView.dequeueReusableCell(withIdentifier: "emailMessageCell", for: indexPath) as? EmailMessageTableViewCell else {
            return EmailMessageTableViewCell()
        }
        emailMessageCell.emailMessage = emailMessage
        emailMessageCell.accessoryType = .disclosureIndicator
        return emailMessageCell
    }

    // MARK: - Conformance: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: Segue.navigateToReadEmailMessage.rawValue, sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let cancel = UIContextualAction(style: .destructive, title: "Delete") { _, _, completion in
            self.deleteEmailMessage(forIndexPath: indexPath, completion: completion)
        }
        cancel.backgroundColor = .red

        return UISwipeActionsConfiguration(actions: [cancel])
    }

}
