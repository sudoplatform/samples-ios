//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoDIRelay
import SudoUser
import SudoProfiles

class PostboxViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ExitHandling {

    // MARK: - Supplementary

    /// Segues that are performed in `PostboxViewController`.
    enum Segue: String {
        /// Navigate to the `MessageViewController`.
        case navigateToMessage

        /// Navigate to `PostboxesViewController`.
        case unwindToPostboxes

    }

    // MARK: - Properties

    var sudo: Sudo!
    var postboxId: String!

    var postbox: Postbox!
    var messageIds: [String] = []
    var subscriptionToken: SubscriptionToken?
    private var presentedActivityAlert: UIAlertController?

    // MARK: - Properties: Computed

    var relayClient: SudoDIRelayClient {
        return AppDelegate.dependencies.sudoDIRelayClient
    }

    var sudoUserClient: SudoUserClient {
        return AppDelegate.dependencies.sudoUserClient
    }

    var profilesClient: SudoProfilesClient {
        return AppDelegate.dependencies.profilesClient
    }
    // MARK: - Outlets

    /// Text for service endpoint
    @IBOutlet weak var serviceEndpoint: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var isPostboxEnabledSwitch: UISwitch!

    @IBOutlet weak var messageText: UITextView!
    @IBOutlet weak var createMessageButton: UIButton!
    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        Task(priority: .medium) {
            await updatePostboxView()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
    }

    // MARK: - Table View

    /// Return the number of table rows.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messageIds.count
    }

    /// Return the title of the table.
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Messages for Postbox"
    }

    /// Return a table cell with a label containing the message ID.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let messageId = messageIds[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath)
        cell.textLabel?.text = messageId
        return cell

    }

    /// After tapping on a row, navigate to displaying the message details
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // Clicked on an existing message ID
        let messageId = messageIds[indexPath.row]
        performSegue(withIdentifier: Segue.navigateToMessage.rawValue, sender: messageId)

    }

    /// Swipe on an existing message ID to delete message.
    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let messageId = messageIds[indexPath.row]
        let action = UIContextualAction(style: .normal, title: "Delete") { [weak self] (_, _, completionHandler) in
            Task {
                _ = try await self?.didSwipeToDeleteMessage(messageId: messageId)
            }
            completionHandler(true)
        }
        action.backgroundColor = .systemRed
        return UISwipeActionsConfiguration(actions: [action])
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let segueType = Segue(rawValue: segue.identifier ?? "")
        switch segueType {
        case .navigateToMessage:
            let destination = segue.destination as! MessageDetailsViewController
            destination.messageId = sender as? String ?? ""
        default:
            break
        }
    }

    // MARK: - Actions

    /// Proceed to sign out and deregister user, and then unwind to the start (RegistrationViewController).
    ///
    /// - Parameter sender: Exit button.
    @IBAction func didTapExitButton(_ sender: Any) {
        subscriptionToken?.cancel()
        self.doExitButtonAction(sender)
    }

    @IBAction func isPostboxEnabledSwitchChanged(_ sender: Any) {
        Task { @MainActor in
            let enabled = isPostboxEnabledSwitch.isOn
            await presentActivityAlert(message: "Updating postbox")

            Task(priority: .medium) {
                let updatedPostbox = try await self.relayClient.updatePostbox(withPostboxId: postbox.id, isEnabled: enabled)
                postbox = updatedPostbox
            }
            self.dismiss(animated: true) {
                self.tableView.reloadData()
            }
        }
    }

    @IBAction func didTapServiceEndpointLabel(sender: UITapGestureRecognizer) {
        guard let label = sender.view as? UILabel else {
            return
        }
        UIPasteboard.general.string = label.text
    }

    @IBAction func didTapCreateMessageButton(_ sender: Any) {
        Task { @MainActor in
            guard let messageText = messageText.text else {
                await presentErrorAlert(message: "Message contains no text and will not be sent")
                return
            }
            await presentActivityAlert(message: "Sending message")
            Task(priority: .medium) {
                _ = try await sendMessage(messageText: messageText)
            }
            self.dismiss(animated: true) {
                self.messageText.text = ""
            }
        }
    }

    // MARK: - Helpers

    /// Attempt to send a message using the SendMessage helper class. Note that normally a separate application
    /// would be responsible for sending the message to the relay.
    func sendMessage(messageText: String) async throws {
        try await SendMessage.writeMessage(serviceEndpoint: postbox.serviceEndpoint, messageContents: Data(JSONEncoder().encode(messageText)))
    }

    /// Attempt to retrieve an updated list of the postbox IDs and refresh the table.
    /// If unsuccessful, does not refresh the table.
    @MainActor func updatePostboxView() async {
        await presentActivityAlert(message: "Fetching messages")
        if let fetchedMessageIds = await fetchMessageIdsOrAlert() {
            messageIds = fetchedMessageIds
        }
        // Set up message subscription - we are not actually using the retrieved message
        // but instead fire another round-trip
        // We must store the token in order for the subscription to be created successfully, otherwise
        // the out of scope returned value will cause the subscription to be terminated.
        do {
            subscriptionToken = try await relayClient.subscribeToMessageCreated(
                statusChangeHandler: nil,
                resultHandler: { result in
                    switch result {
                    case .success:
                        Task(priority: .medium) {
                            if let fetchedMessageIds = await self.fetchMessageIdsOrAlert() {
                                self.messageIds = fetchedMessageIds
                            }
                            self.tableView.reloadData()
                        }

                    default:
                        return
                    }
                })
        } catch {
            await presentErrorAlertOnMain("Could not set up message subscription.", error: error)
        }
        self.dismiss(animated: true) {
            self.tableView.reloadData()
        }
    }

    /// Attempt to retrieve the list of messages from the relay for the given postbox
    /// If unsuccessful, display an error alert on the UI.
    ///
    /// - Returns: List of message IDs or  nil.
    @MainActor func fetchMessageIdsOrAlert() async -> [String]? {
        do {
            let result = try await relayClient.listPostboxes(limit: 20, nextToken: nil)
            guard let localPostbox = result.items.first(where: {$0.id == postboxId}) else {
                await presentErrorAlertOnMain("Could not fetch postbox.", error: nil)
                return nil
            }
            postbox = localPostbox
            serviceEndpoint.text = postbox.serviceEndpoint
            isPostboxEnabledSwitch.setOn(postbox.isEnabled, animated: true)

        } catch {
            await presentErrorAlertOnMain("Could not fetch postbox.", error: error)
            return nil
        }
        do {
            let result = try await relayClient.listMessages(limit: 20, nextToken: nil)
            return result.items
                .filter {$0.postboxId == postbox.id}
                .map {$0.id}
        } catch {
            await presentErrorAlertOnMain("Could not fetch messages for postbox.", error: error)
            return nil
        }
    }

    /// Deletes message from the relay and updates table view.
    ///
    /// If unsuccessful, present an error alert.
    ///
    /// - Parameter messageId: postbox ID to delete.
    @MainActor func didSwipeToDeleteMessage(messageId: String) async throws {
        await presentActivityAlertOnMain("Deleting message")

        _ = try await relayClient.deleteMessage(withMessageId: messageId)

        self.messageIds = self.messageIds.filter {$0 != messageId}
        self.dismiss(animated: true) {
            self.tableView.reloadData()
        }
    }
}
