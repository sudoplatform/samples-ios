//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoDecentralizedIdentity
import Combine
import Firebase

struct DecryptedMessage {
    let body: Body
    let encryptedBody: Data
    let date: Date
    let senderVerkey: String?
    let recipientVerkey: String
    let direction: Direction

    enum Body {
        case message(DIDCommMessage, String)
        case text(String)
    }

    enum Direction {
        case incoming, outgoing
    }
}

enum MessageDecryptionResult {
    case decrypted(DecryptedMessage)
    case notDecrypted(RelayedMessage, SudoDecentralizedIdentityClientError)

    var date: Date {
        switch self {
        case .decrypted(let decryptedMessage): return decryptedMessage.date
        case .notDecrypted(let encryptedMessage, _): return encryptedMessage.date
        }
    }
}

class ConnectionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    // MARK: Data

    var walletId: String!
    var pairwiseConnection: Pairwise!
    var messages: [MessageDecryptionResult] = []

    private var myPostboxId: String!
    private var theirService: DidDoc.Service!
    private var myVerkey: String!
    private var theirVerkey: String!
    private var messageCancellable: AnyCancellable?

    // MARK: Receive messages

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        messageBodyTextField.isEnabled = false

        fetchMetadataDependencies {
            DispatchQueue.main.async {
                self.messageBodyTextField.isEnabled = true
                self.subscribeToMessages()
            }
        }
    }

    func fetchMetadataDependencies(onSuccess: @escaping () -> Void) {
        let group = DispatchGroup()

        func retrieveDidDocOrAlert(forDid did: String) -> DidDoc? {
            switch Result(catching: {
                try KeychainDIDDocStorage().retrieve(for: did)
            }) {
            case .success(.some(let didDoc)):
                return didDoc
            case .success(.none):
                self.presentErrorAlert(message: "Failed to retrieve stored DID doc:\nNot found")
                return nil
            case .failure(let error):
                self.presentErrorAlert(message: "Failed to retrieve stored DID doc", error: error)
                return nil
            }
        }

        // Retrieve my DID doc to get the service endpoint used.
        guard let myDidDoc = retrieveDidDocOrAlert(forDid: pairwiseConnection.myDid) else { return }

        // Retrieve relay postbox ID from my service endpoint to subscribe to.
        guard let myPostboxId = Dependencies.firebaseRelay.postboxId(
            fromServiceEndpoint: myDidDoc.service[0].endpoint
        ) else {
            self.presentErrorAlert(message: "Failed to retrieve local postbox ID from stored DID doc service endpoint")
            return
        }

        // Retrieve their DID doc to get the service endpoint to send messages to.
        guard let theirDidDoc = retrieveDidDocOrAlert(forDid: pairwiseConnection.theirDid) else { return }

        // Attempt to find an endpoint from the sender's DID Doc.
        // TODO: We may need to be smarter about finding the right endpoint in the future.
        guard let theirService = theirDidDoc.service
            .first(where: { ["http", "https"].contains(URL(string: $0.endpoint)?.scheme) }) else {
                self.presentErrorAlert(message: "No supported service endpoint found in recipient's DID Doc")
                return
        }

        func retrieveVerkeyOrAlert(forDid did: String, onSuccess: @escaping (String) -> Void) {
            group.enter()

            Dependencies.sudoDecentralizedIdentityClient.keyForDid(
                walletId: self.walletId,
                did: did
            ) { result in
                defer { group.leave() }

                switch result {
                case .success(let verkey):
                    onSuccess(verkey)
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.presentErrorAlert(message: "Failed to retrieve stored verkey", error: error)
                    }
                }
            }
        }

        // Retrieve local verkey to determine direction of messages.
        var myVerkey: String?
        retrieveVerkeyOrAlert(forDid: pairwiseConnection.myDid) { myVerkey = $0 }

        // Retrieve recipient verkey to encrypt outgoing messages.
        var theirVerkey: String?
        retrieveVerkeyOrAlert(forDid: pairwiseConnection.theirDid) { theirVerkey = $0 }

        group.notify(queue: .main) {
            // subscribe to messages after verkeys are retrieved
            self.myPostboxId = myPostboxId
            self.theirService = theirService
            self.myVerkey = myVerkey
            self.theirVerkey = theirVerkey

            if myVerkey != nil, theirVerkey != nil {
                onSuccess()
            }
        }
    }

    private func subscribeToMessages() {
        messageCancellable = Dependencies.firebaseRelay.subscribeToMessages(atPostboxId: myPostboxId)
            .flatMap { messages in
                // decrypt all messages, then emit the array of decrypted messages
                return Publishers.Sequence(sequence:
                    messages.map { encryptedMessage in
                        self.decryptMessage(encryptedMessage)
                            .map(MessageDecryptionResult.decrypted)
                            .catch { error in
                                Just(MessageDecryptionResult.notDecrypted(
                                    encryptedMessage, error))
                            }
                    }
                )
                .flatMap { $0 }
                .collect()
                // We have to sort again since collect() will take elements in the order they decrypt.
                .map { $0.sorted(by: { $0.date > $1.date }) }
            }
            .receive(on: DispatchQueue.main)
            .sink { (messages: [MessageDecryptionResult]) in
                self.messages = messages
                self.tableView.reloadData()
            }
    }

    func decryptMessage(_ encryptedMessage: RelayedMessage) -> AnyPublisher<DecryptedMessage, SudoDecentralizedIdentityClientError> {
        return Future { completion in
            Dependencies.sudoDecentralizedIdentityClient.unpackMessage(
                walletId: self.walletId,
                message: encryptedMessage.body,
                completion: completion
            )
        }
        .map { (unpackedMessage: UnpackedMessage) -> DecryptedMessage in
            let direction: DecryptedMessage.Direction =
                (unpackedMessage.senderVerkey == self.myVerkey) ? .outgoing : .incoming

            let body: DecryptedMessage.Body

            switch ClientContainer().parseDIDCommJSON(data: Data(unpackedMessage.message.utf8)) {
            case .success(let message):
                body = .message(message, unpackedMessage.message)
            case .failure:
                body = .text(unpackedMessage.message)
            }

            return DecryptedMessage(
                body: body,
                encryptedBody: encryptedMessage.body,
                date: encryptedMessage.date,
                senderVerkey: unpackedMessage.senderVerkey,
                recipientVerkey: unpackedMessage.recipientVerkey,
                direction: direction
            )
        }
        .eraseToAnyPublisher()
    }

    // MARK: Send message

    @IBOutlet weak var messageBodyTextField: UITextField!
    @IBOutlet weak var sendMessageButton: UIButton!

    @IBAction func sendMessageButtonTapped() {
        let basicMessage = BasicMessage(
            id: UUID().uuidString,
            thread: nil, // TODO?
            content: messageBodyTextField.text ?? "",
            sent: Date(),
            l10n: nil
        )

        let basicMessageJson: Data

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.withoutEscapingSlashes]
            encoder.dateEncodingStrategy = .iso8601
            basicMessageJson = try encoder.encode(basicMessage)
        } catch let error {
            self.presentErrorAlert(message: "Failed to encode basic message", error: error)
            return
        }

        Dependencies.sudoDecentralizedIdentityClient.packMessage(
            walletId: walletId,
            message: basicMessageJson,
            recipientVerkeys: [myVerkey, theirVerkey],
            senderVerkey: myVerkey
        ) { result in
            switch result {
            case .success(let packedMessageForSelfAndRecipient):
                DecentralizedIdentityExample.encryptForRoutingKeys(
                    walletId: self.walletId,
                    message: packedMessageForSelfAndRecipient,
                    to: self.theirVerkey,
                    routingKeys: ArraySlice(self.theirService.routingKeys)
                ) { result in
                    switch result {
                    case .success(let packedMessage):
                        let packedMessageJson: Data
                        do {
                            let encoder = JSONEncoder()
                            encoder.outputFormatting = [.withoutEscapingSlashes]
                            packedMessageJson = try encoder.encode(packedMessage)
                        } catch let error {
                            DispatchQueue.main.async {
                                self.presentErrorAlert(message: "Failed to encode packed message", error: error)
                            }
                            return
                        }

                        // Transmit the encrypted message to the recipient's service endpoint.
                        DIDCommTransports.transmit(
                            data: packedMessageJson,
                            to: self.theirService.endpoint
                        ) { result in
                            if case .failure(let error) = result {
                                DispatchQueue.main.async {
                                    self.presentErrorAlert(message: "Failed to transmit encrypted message", error: error)
                                }
                            }
                        }
                    case .failure(let error):
                        DispatchQueue.main.async {
                            self.presentErrorAlert(message: "Failed to encrypt message for recipient routing keys", error: error)
                        }
                    }
                }

                let packedMessageJson: Data
                do {
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = [.withoutEscapingSlashes]
                    packedMessageJson = try encoder.encode(packedMessageForSelfAndRecipient)
                } catch let error {
                    DispatchQueue.main.async {
                        self.presentErrorAlert(message: "Failed to encode packed message", error: error)
                    }
                    return
                }

                // Persist encrypted message to our own DB so we have a copy.
                Firestore.firestore(app: Dependencies.firebaseRelay.app)
                    .collection("postboxes")
                    .document(self.myPostboxId)
                    .collection("messages")
                    .addDocument(data: [
                        "message": packedMessageJson,
                        "createdAt": FieldValue.serverTimestamp()
                    ]) { error in
                        if let error = error {
                            DispatchQueue.main.async {
                                self.presentErrorAlert(message: "Failed to persist encrypted message to local DB", error: error)
                            }
                        }
                    }

                // Clear the body text field.
                DispatchQueue.main.async {
                    self.messageBodyTextField.text = ""
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.presentErrorAlert(message: "Failed to encrypt message", error: error)
                }
            }
        }
    }

    @IBAction func messageBodyChanged() {
        sendMessageButton.isEnabled = !(messageBodyTextField.text?.isEmpty ?? true)
    }

    // MARK: Table View

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bottomOffsetConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0)

        navigationItem.title = pairwiseConnection.label

        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardChange), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardChange), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)

        messageBodyChanged()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        assert(section == 0)
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        assert(indexPath.section == 0)

        let messageResult = messages[indexPath.row]

        let cell: ConnectionMessageTableViewCell

        switch messageResult {
        case .decrypted(let message):
            switch message.direction {
            case .incoming:
                cell = tableView.dequeueReusableCell(withIdentifier: "incomingMessageCell", for: indexPath) as! ConnectionMessageTableViewCell
            case .outgoing:
                cell = tableView.dequeueReusableCell(withIdentifier: "outgoingMessageCell", for: indexPath) as! ConnectionMessageTableViewCell
            }

            switch message.body {
            case .message(let agentMessage as PreviewableDIDCommMessage, _):
                cell.bodyLabel.text = agentMessage.preview
                cell.dateLabel.text = agentMessage.typeDescription
                // TODO: show the date somewhere
            case .message(let agentMessage, _):
                cell.bodyLabel.text = "(\(agentMessage.type))"
                cell.dateLabel.text = DateFormatter.localizedString(from: message.date, dateStyle: .short, timeStyle: .short)
            case .text(let text):
                cell.bodyLabel.text = text
                cell.dateLabel.text = DateFormatter.localizedString(from: message.date, dateStyle: .short, timeStyle: .short)
            }

        case .notDecrypted(let encryptedMessage, let error):
            cell = tableView.dequeueReusableCell(withIdentifier: "incomingMessageCell", for: indexPath) as! ConnectionMessageTableViewCell
            cell.bodyLabel.text = "(Failed to decrypt message: \(error.localizedDescription))"
            cell.dateLabel.text = DateFormatter.localizedString(from: encryptedMessage.date, dateStyle: .short, timeStyle: .short)
        }

        cell.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0)

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        assert(indexPath.section == 0)

        tableView.deselectRow(at: indexPath, animated: true)

        performSegue(withIdentifier: "navigateToMessageDetails", sender: messages[indexPath.row])
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

    // MARK: Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "navigateToConnectionDetails":
            let destination = segue.destination as! ConnectionDetailsViewController
            destination.pairwiseConnection = self.pairwiseConnection

            view.endEditing(true)
        case "navigateToMessageDetails":
            let messageResult = sender as! MessageDecryptionResult
            let destination = segue.destination as! MessageDetailsViewController
            destination.messageResult = messageResult
        default: break
        }
    }
}

class ConnectionMessageTableViewCell: UITableViewCell {
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
}
