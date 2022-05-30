//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import Combine
import SudoDIRelay

struct PresentableMessage: Comparable {

    var message: RelayMessage
    var encrypted: Bool

    // MARK: - Conformance: Comparable

    static func < (lhs: PresentableMessage, rhs: PresentableMessage) -> Bool {
        if lhs.message.timestamp < rhs.message.timestamp {
            return true
        }
        return false
    }
}

class ConnectionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // MARK: - Properties

    let dateFormatter: DateFormatter = DateFormatter()
    let relayClient: SudoDIRelayClient = AppDelegate.dependencies.sudoDIRelayClient

    var messageLog: [PresentableMessage] = []
    var onMessagesReceivedToken: SubscriptionToken?
    var myPostboxId: String = ""
    var peerPostboxId: String?

    /// The peer posted an invitation message containing metadata we don't want to display in the connection view.
    /// Make note of this message and do not display it.
    var invitationMessageId: String?

    private var myPublicKey: String?
    private var peerPublicKey: String?

    // MARK: - Outlets

    /// The table view that lists all messages.
    @IBOutlet weak var tableView: UITableView!

    @IBOutlet weak var messageBodyTextField: UITextField!
    @IBOutlet weak var sendMessageButton: UIButton!
    @IBOutlet weak var bottomOffsetConstraint: NSLayoutConstraint!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0)

        navigationItem.title = myPostboxId

        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardChange), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardChange), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)

        messageBodyChanged()
    }

    override func viewWillAppear(_ animated: Bool) {
        Task {
            do {
                try await self.prepareMetadataOnLoad()
            } catch {
                self.presentErrorAlertOnMain("Unable to prepare metadata on load. ", error: error)
            }
        }
    }

    // MARK: - Receive messages

    /// Attempt to subscribe if not already subscribed. Subscribes via the `SudoDIRelayClient`.
    ///
    /// Checks if `onMessagesReceivedToken` is nil to determine if subscription already exists.
    /// If unsuccessfully subscribes, presents an error alert on the UI.
    private func subscribeToMessages() async throws {
        if onMessagesReceivedToken != nil {
            return
        }

        do {
            onMessagesReceivedToken = try await relayClient.subscribeToMessagesReceived(withConnectionId: myPostboxId) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let message):
                    self.processMessageReceived(message: message)
                case let .failure(error):
                    self.presentErrorAlertOnMain("MessagesReceived subscription failure", error: error)
                }
            }
        } catch {
            self.presentErrorAlertOnMain("MessagesReceived subscription threw error. ", error: error)
            throw error
        }
    }

    /// Attempts to decrypt `message.cipherText` using our private key. Appends the entire`message` with the decrypted cipherText to the
    /// current list of messages. Reloads the view once finished.
    ///
    /// - Parameter message: A `RelayMessage` fetched from the relay.
    func processMessageReceived(message: RelayMessage) {
        var messageCopy = message

        if let decryptedText = decryptMessageOrPresentError(relayMessage: message) {
            messageCopy.cipherText = decryptedText
        }

        // Must keep a strong reference to keep subscription connection open
        messageLog.append(PresentableMessage(message: messageCopy, encrypted: false))
        messageLog.sort(by: >)
        tableView.reloadData()
    }

    /// Attempt to decrypt the given `relayMessage` or display an error alert if unsuccessful.
    ///
    /// - Parameter relayMessage: A message returned from the postbox.
    /// - Returns: Decrypted string or nil if unsuccessful
    func decryptMessageOrPresentError(relayMessage: RelayMessage) -> String? {
        // The message was sent as a string representation of the data
        guard let message = try? KeyManagement().unpackEncryptedMessageForConnection(
            connectionId: myPostboxId,
            encryptedPayloadString: relayMessage.cipherText
        ) else {
            presentErrorAlertOnMain("Unable to decrypt received message", error: nil)
            return nil
        }
        return message
    }

    /// Attempt to encrypt `message` and store in the relay via the `SudoDIRelayClient`.
    /// Appends the unencrypted `RelayMessage` in the current list of messages.
    ///
    /// Displays an error alert if encryption or storage were unsuccesful.
    ///
    /// - Parameter message: The plaintext message to store inside the relay and the cache.
    func encryptAndStoreInRelayAndCache(message: String) async throws {
        do {
            // Encrypt using our public key
            guard let encryptedMessage = try KeyManagement().packEncryptedMessageForPeer(
                    peerConnectionId: myPostboxId,
                    message: message
            ) else {
                presentErrorAlertOnMain("Unable to encrypt message to store", error: nil)
                return
            }

            // Store encrypted message in our own postbox for persistence
            var storedMessage = try await relayClient.storeMessage(
                withConnectionId: myPostboxId,
                message: encryptedMessage
            )
            // Store an unencrypted message in our cache to avoid decrypting effort later
            storedMessage?.cipherText = message

            if let storedMessage = storedMessage {
                messageLog.append(PresentableMessage(message: storedMessage, encrypted: false))
                messageLog.sort(by: >)
                tableView.reloadData()
            }
        } catch {
            presentErrorAlertOnMain("Unable to store message message in relay. ", error: error)
            throw error
        }
    }

    // MARK: - Table View

    /// Return number of table rows.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messageLog.count + 1
    }

    /// Construct table view cells.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if indexPath.row == messageLog.count {
            // Add a summary label before the conversation messages
            let cell: ConnectionSummaryTableViewCell
            cell = tableView.dequeueReusableCell(withIdentifier: "connectionSummaryMessageCell", for: indexPath) as! ConnectionSummaryTableViewCell
            if peerPostboxId != nil {
                cell.summaryLabel.text = "Connected to peer with postbox ID: \(peerPostboxId ?? "")\n"
            }
            cell.summaryLabel.numberOfLines = 2
            cell.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0)
            return cell
        }

        let cell: ConnectionMessageTableViewCell
        let entry = messageLog[indexPath.row]

        switch entry.message.direction {
            case .inbound:
                cell = tableView.dequeueReusableCell(withIdentifier: "incomingMessageCell", for: indexPath) as! ConnectionMessageTableViewCell
            case .outbound:
                cell = tableView.dequeueReusableCell(withIdentifier: "outgoingMessageCell", for: indexPath) as! ConnectionMessageTableViewCell
        }

        cell.bodyLabel.text = entry.message.cipherText
        cell.dateLabel.text = DateFormatter.localizedString(from: entry.message.timestamp, dateStyle: .short, timeStyle: .short)

        cell.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0)
        return cell
    }

    /// Click on a row
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    @objc func handleKeyboardChange(notification: Notification) {
        guard let frameEnd = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

        bottomOffsetConstraint.constant = notification.name == UIResponder.keyboardWillHideNotification
            ? 0
            : frameEnd.height - view.safeAreaInsets.bottom

        UIView.animate(withDuration: 0.5) {
           self.view.layoutIfNeeded()
        }
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "navigateToConnectionDetails":
            let destination = segue.destination as! ConnectionDetailsViewController
            destination.myPostboxId = myPostboxId
            destination.peerPostboxId = peerPostboxId
            destination.myPublicKey = myPublicKey
            destination.peerPublicKey = peerPublicKey
            view.endEditing(true)
        default:
            break
        }
    }

    // MARK: - Actions

    /// Take the text from the UI text field, encrypt it using the peer's public key and POST it to the peer's endpoint.
    /// If POST is successful, store the message in our own relay and cache.
    @IBAction func sendMessageButtonTapped() {

        let messageToSend = messageBodyTextField.text ?? ""

        // Clear the body text field and disable send button
        self.messageBodyTextField.text = ""

        presentActivityAlert(message: "Encrypting and sending message...")

        do {
            guard let encryptedMessage = try KeyManagement().packEncryptedMessageForPeer(
                    peerConnectionId: peerPostboxId ?? "",
                    message: messageToSend
            ) else {
                presentErrorAlertOnMain("Unable to encrypt message to send to peer", error: nil)
                return
            }
            guard let encryptedMessageAsData = encryptedMessage.data(using: .utf8) else {
                presentErrorAlertOnMain("Failed to pack message to send to peer", error: nil)
                return
            }

            print("What should be stored in the postbox. \(encryptedMessageAsData.base64URLEncodedString())")

            guard let url = relayClient.getPostboxEndpoint(withConnectionId: peerPostboxId ?? "") else {
                presentErrorAlertOnMain("Unable to fetch peer's postbox endpoint", error: nil)
                return
            }

            Task(priority: .medium) {
                // POST to peer's postbox
                _ = try await HTTPTransports.transmit(
                    data: encryptedMessageAsData,
                    to: url
                )
                // Store in our own postbox for persistence
                try await self.encryptAndStoreInRelayAndCache(message: messageToSend)
            }
            self.dismiss(animated: true)
        } catch {
            presentErrorAlertOnMain("Failed to send to peer", error: error)
            return
        }
    }

    @IBAction func messageBodyChanged() {
        sendMessageButton.isEnabled = !(messageBodyTextField.text?.isEmpty ?? true)
    }

    // MARK: - Helpers

    /// On view load, fetch messages, set up subscription and get metadata such as keys.
    /// Passes errors thrown back to caller and does not present error alerts. These need to be handled by caller as desired.
    func prepareMetadataOnLoad() async throws {

        messageBodyTextField.isEnabled = false

        let fetchedMessages = try await fetchMessages()
        messageLog.append(contentsOf: fetchedMessages)
        messageLog.sort(by: >)
        messageBodyTextField.isEnabled = true
        tableView.reloadData()

        try await subscribeToMessages()
        tableView.reloadData()
        try getMetadata()
    }

    /// Fetch the peer postbox ID, the peer public key and our public key.
    private func getMetadata() throws {
        do {
            guard let peerPostboxId = try KeychainConnectionStorage().retrieve(for: myPostboxId) else {
                presentErrorAlertOnMain("Unable to retrieve peer postbox id", error: nil)
                return
            }
            self.peerPostboxId = peerPostboxId

            guard let peerPublicKey = try KeyManagement().getPublicKeyForConnection(connectionId: peerPostboxId) else {
                presentErrorAlertOnMain("Unable to retrieve peer public key", error: nil)
                return
            }
            self.peerPublicKey = peerPublicKey

            if self.myPublicKey == nil {
                guard let myPublicKey = try KeyManagement().getPublicKeyForConnection(connectionId: myPostboxId) else {
                    presentErrorAlertOnMain("Unable to retrieve public key for this postbox", error: nil)
                    return
                }
                self.myPublicKey = myPublicKey
            }
        } catch {
            presentErrorAlertOnMain("Unable to retrieve metadata for conversation", error: error)
            throw error
        }
    }


    /// Get messages via the `SudoDIRelayClient` and decrypt if possible.
    /// If successful, appends messages that are not already in the current list of messages.
    ///  - Returns: List of messages
    private func fetchMessages() async throws -> [PresentableMessage] {
        var messages: [RelayMessage]
        do {
            messages = try await relayClient.listMessages(withConnectionId: myPostboxId)
        } catch {
            presentErrorAlertOnMain("Could not fetch messages from relay. ", error: error)
            throw error
        }
        let invitationId = invitationMessageId ?? ""

        // Skip message if it is the invitation message
        messages = messages.compactMap { message in
            return message.messageId == invitationId ? nil : message
        }

        // Skip message if list already currently contains it
        messages = messages.compactMap { message in
            let doesContainMessage = messageLog.contains(where: {$0.message.messageId == message.messageId})
            return doesContainMessage ? nil : message
        }

        // Attempt to decrypt all of the remaining messages
        let presentableMessages: [PresentableMessage] = messages.compactMap { message in
            let decryptionResult = decryptMessageOrPresentError(relayMessage: message)
            guard let decryptedText = decryptionResult else {
                return PresentableMessage(message: message, encrypted: true)
            }
            var relayMessage = message
            relayMessage.cipherText = decryptedText
            return PresentableMessage(message: relayMessage, encrypted: false)
        }
        return presentableMessages
    }
}

// MARK: - UITableViewCells

class ConnectionMessageTableViewCell: UITableViewCell {

    // MARK: - Outlets

    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
}

class ConnectionSummaryTableViewCell: UITableViewCell {

    // MARK: - Outlets

    @IBOutlet weak var summaryLabel: UILabel!
}
