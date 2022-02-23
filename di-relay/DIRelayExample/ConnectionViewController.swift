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

    @IBOutlet weak var messageBodyTextField: UITextField!
    @IBOutlet weak var sendMessageButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bottomOffsetConstraint: NSLayoutConstraint!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        prepareMetadataOnLoad()

        tableView.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0)

        navigationItem.title = myPostboxId

        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardChange), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardChange), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)

        messageBodyChanged()
    }

    // MARK: - Receive messages
    
    /// Attempt to subscribe if not already subscribed. Subscribes via the `SudoDIRelayClient`.
    ///
    /// Checks if `onMessagesReceivedToken` is nil to determine if subscription already exists.
    /// If unsuccessfully subscribes, presents an error alert on the UI.
    ///
    /// - Parameter completion: a `Result` that on `.success` resolves to `Void` and on `.failure` resolves to an error.
    private func subscribeToMessages(completion: @escaping (Result<Void, Error>) -> Void) {
        if onMessagesReceivedToken != nil {
            return
        }
        
        onMessagesReceivedToken = relayClient.subscribeToMessagesReceived(withConnectionId: myPostboxId) { [weak self] result in
            guard let weakSelf = self else { return }
            switch result {
            case .success(let message):
                self?.processMessageReceived(message: message)

                completion(.success(()))
            case let .failure(error):
                DispatchQueue.main.async {
                    weakSelf.presentErrorAlert(message: "MessagesReceived subscription failure", error: error)
                }
                completion(.failure(error))
            }
        }
    }
    
    /// Attempts to decrypt `message.cipherText` using our private key. Appends the entire`message` with the decrypted cipherText to the
    /// current list of messages. Reloads the view once finished.
    ///
    /// - Parameter message: A `RelayMessage` fetched from the relay.
    func processMessageReceived(message: RelayMessage) {
        var messageCopy = message
        
        if let decryptedText = decryptReceivedMessageOrPresentError(relayMessage: message) {
            messageCopy.cipherText = decryptedText
        }
        DispatchQueue.main.async {
            // Must keep a strong reference to keep subscription connection open
            self.messageLog.append(PresentableMessage(message: messageCopy, encrypted: false))
            self.messageLog.sort(by: >)
            self.tableView.reloadData()
        }
    }

    /// Attempt to decrypt the given `relayMessage` or display an error alert if unsuccessful.
    ///
    /// - Parameter relayMessage: A message returned from the postbox.
    /// - Returns: Decrypted string or nil.
    func decryptReceivedMessageOrPresentError(relayMessage: RelayMessage) -> String? {
        
        do {
            // The message was sent as a string representation of the data
            return try KeyManagement().unpackEncryptedMessageForConnection(
                connectionId: myPostboxId,
                encryptedPayloadString: relayMessage.cipherText
            )
        } catch {
            DispatchQueue.main.async {
                self.presentErrorAlert(message: "Unable to decrypt received message", error: error)
            }
            return nil
        }
    }

    /// Attempt to encrypt `message` and store in the relay via the `SudoDIRelayClient`.
    /// Appends the unencrypted `RelayMessage` in the current list of messages.
    ///
    /// Displays an error alert if encryption or storage were unsuccesful.
    ///
    /// - Parameter message: The plaintext message to store inside the relay and the cache.
    func encryptAndStoreInRelayAndCache(message: String) {
        do {
            // Encrypt using our public key
            guard let encryptedMessage = try KeyManagement().packEncryptedMessageForPeer(
                    peerConnectionId: myPostboxId,
                    message: message
            ) else {
                onFailure("Unable to encrypt message to store", error: nil)
                return
            }
            
            // Store encrypted message in our own postbox for persistence
            relayClient.storeMessage(withConnectionId: myPostboxId, message: encryptedMessage) { result in
                switch result {
                case .success(let storedMessage):
                    if var storedMessage = storedMessage {
                        // Store an unencrypted message in our cache to avoid decrypting effort later
                        DispatchQueue.main.async {
                            storedMessage.cipherText = message
                            self.messageLog.append(PresentableMessage(message: storedMessage, encrypted: false))
                            self.messageLog.sort(by: >)
                            self.tableView.reloadData()
                        }
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.presentErrorAlert(message: "Unable to store message", error: error)
                    }
                }
            }
        } catch {
            self.onFailure("Failed to encode message to store", error: nil)
            return
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
    /// If successfully POSTed, store the message in our own relay and cache.
    @IBAction func sendMessageButtonTapped() {

        let messageToSend = messageBodyTextField.text ?? ""
        do {
            // Clear the body text field
            DispatchQueue.main.async {
                self.messageBodyTextField.text = ""
            }
            guard let encryptedMessage = try KeyManagement().packEncryptedMessageForPeer(
                    peerConnectionId: peerPostboxId ?? "",
                    message: messageToSend
            ) else {
                onFailure("Unable to encrypt message to send to peer", error: nil)
                return
            }
            guard let encryptedMessageAsData = encryptedMessage.data(using: .utf8) else {
                onFailure("Failed to pack message to send to peer", error: nil)
                return
            }

            print("What should be stored in the postbox. \(encryptedMessageAsData.base64URLEncodedString())")

            guard let url = relayClient.getPostboxEndpoint(withConnectionId: peerPostboxId ?? "") else {
                onFailure("Unable to fetch peer's postbox endpoint", error: nil)
                return
            }

            // POST to peer's postbox
            HTTPTransports.transmit(
                data: encryptedMessageAsData,
                to: url
            ) { result in
                switch result {
                case .success:
                    // Store in our own postbox for persistence
                    self.encryptAndStoreInRelayAndCache(message: messageToSend)
                case .failure(let error):
                    self.onFailure("Failed to send message", error: error)
                }
            }
        } catch {
            self.onFailure("Failed to encode message to send to peer", error: nil)
            return
        }
    }

    @IBAction func messageBodyChanged() {
        sendMessageButton.isEnabled = !(messageBodyTextField.text?.isEmpty ?? true)
    }

    // MARK: - Helpers
    
    /// On view load, fetch messages, set up subscription and get metadata such as keys.
    func prepareMetadataOnLoad() {
        DispatchQueue.main.async {
            self.messageBodyTextField.isEnabled = false
        }

        fetchMessages() { result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    self.messageBodyTextField.isEnabled = true
                    self.tableView.reloadData()
                }
            default:
                break
            }
        }

        // if subscription not set up, set it up
        subscribeToMessages() { result in
            switch result {
            case .success():
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            default:
                break
            }
        }

        do {
            try getMetadata()
        } catch {
            presentErrorAlert(message: "Unable to fetch metadata", error: error)
        }


    }
    
    /// Fetch the peer postbox ID, the peer public key and our public key.
    private func getMetadata() throws {
        do {
            guard let peerPostboxId = try KeychainConnectionStorage().retrieve(for: myPostboxId) else {
                self.onFailure("Unable to retrieve peer postbox id", error: nil)
                return
            }
            self.peerPostboxId = peerPostboxId
            guard let peerPublicKey = try KeyManagement().getPublicKeyForConnection(connectionId: peerPostboxId) else {
                self.onFailure("Unable to retrieve peer public key", error: nil)
                return
            }
            self.peerPublicKey = peerPublicKey
            
            if self.myPublicKey == nil {
                guard let myPublicKey = try KeyManagement().getPublicKeyForConnection(connectionId: myPostboxId) else {
                    self.onFailure("Unable to retrieve public key for this postbox", error: nil)
                    return
                }
                self.myPublicKey = myPublicKey
            }
        } catch {
            self.onFailure("Unable to retrieve metadata for conversation", error: error)
            throw error
        }
    }
    
    
    /// Get messages via the `SudoDIRelayClient`.
    /// If successful, appends messages that are not already in the current list of messages.
    ///
    /// TODO: this could probably be made more efficient as getMessages is guaranteed to return messages in chronological order.
    ///        could get messages after a timestamp, but that needs to be exposed in the API.
    ///
    /// - Parameter completion: a `Result` that on `.success`resolves to the list of fetched messages, or  on `.failure` resolves to an error.
    private func fetchMessages(completion: @escaping(Result<[RelayMessage], Error>) -> Void) {
        relayClient.getMessages(withConnectionId: myPostboxId) { result in
            switch result {
            case .success(let messages):
                for message in messages {
                    // If the current list doesn't contain this message, and
                    // if this message also isn't the invitation message

                    /// TODO: get invitationMessageId when segued from postbox list view
                    if !self.messageLog.contains(where: { $0.message.messageId == message.messageId}) &&
                                                    message.messageId != self.invitationMessageId {
                        let decryptedText = self.decryptReceivedMessageOrPresentError(relayMessage: message)
                        var messageCopy = message
                        messageCopy.cipherText = decryptedText ?? message.cipherText
                        DispatchQueue.main.async {
                            self.messageLog.append(PresentableMessage(message: messageCopy, encrypted: false))
                        }
                    }
                }
                completion(.success(messages))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Present an error alert containing `message` and the `error`.
    ///
    /// - Parameters:
    ///   - message: Message to display.
    ///   - error: Error containing a `localizedDescription` to display.
    private func onFailure(_ message: String, error: Error?) {
        DispatchQueue.main.async {
            if self.presentedViewController != nil {
                self.dismiss(animated: true) {
                    self.presentErrorAlert(message: message, error: error)
                }
            } else {
                self.presentErrorAlert(message: message, error: error)
            }
        }
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
