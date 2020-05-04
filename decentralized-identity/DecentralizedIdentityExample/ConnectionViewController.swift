//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoDecentralizedIdentity
import Combine

struct DecryptedMessage {
    let body: String
    let date: Date
    let direction: Direction?

    enum Direction {
        case incoming, outgoing
    }
}

class ConnectionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    // MARK: Data

    var walletId: String!
    var pairwiseConnection: Pairwise!
    var messages: [DecryptedMessage] = []
    private var myVerkey: String?
    private var messageCancellable: AnyCancellable?

    // MARK: Controller

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Retrieve local verkey.
        Dependencies.sudoDecentralizedIdentityClient.keyForDid(
            walletId: self.walletId,
            did: self.pairwiseConnection.myDid
        ) { result in
            switch result {
            case .success(let verkey):
                self.myVerkey = verkey
                self.subscribeToMessages()
            case .failure(let error):
                DispatchQueue.main.async {
                    self.presentErrorAlert(message: "Failed to retrieve local verkey", error: error)
                }
            }
        }
    }

    private func subscribeToMessages() {
        // Retrieve service URL from pairwise metadata
        guard let messageEndpointString = pairwiseConnection.metadataForKey(.serviceEndpoint),
            let messageEndpoint = URLComponents(string: messageEndpointString) else {
                DispatchQueue.main.async {
                    self.presentErrorAlert(message: "Failed to retrieve message endpoint")
                }
                return
        }
        assert(messageEndpoint.scheme == "samplefirebase")

        messageCancellable = FirebaseMessageTransport().messages(pairwiseDid: messageEndpoint.path)
            .flatMap { messages in
                // decrypt all messages, then emit the array of decrypted messages
                return Publishers.Sequence(sequence:
                    messages.map { encryptedMessage in
                        self.decryptMessage(encryptedMessage)
                            .catch { error in
                                Just(DecryptedMessage(
                                    body: "(Failed to decrypt message: \(error.localizedDescription))",
                                    date: encryptedMessage.date,
                                    direction: nil
                                ))
                            }
                    }
                )
                .flatMap { $0 }
                .collect()
            }
            .receive(on: DispatchQueue.main)
            .sink { (messages: [DecryptedMessage]) in
                self.messages = messages
                self.tableView.reloadData()
            }
    }

    func decryptMessage(_ encryptedMessage: Message) -> AnyPublisher<DecryptedMessage, SudoDecentralizedIdentityClientError> {
        return Future { completion in
            guard let encryptedBodyData = encryptedMessage.body.data(using: .utf8) else {
                return completion(.failure(.failedToEncodeMessageUtf8))
            }

            Dependencies.sudoDecentralizedIdentityClient.decryptPairwiseMessage(
                walletId: self.walletId,
                theirDid: self.pairwiseConnection.theirDid,
                message: encryptedBodyData,
                completion: completion
            )
        }
        .map { (pairwiseMessage: PairwiseMessage) -> DecryptedMessage in
            let direction: DecryptedMessage.Direction =
                (pairwiseMessage.senderVerkey == self.myVerkey) ? .outgoing : .incoming

            return DecryptedMessage(
                body: pairwiseMessage.message,
                date: encryptedMessage.date,
                direction: direction
            )
        }
        .eraseToAnyPublisher()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = pairwiseConnection.label
    }

    // MARK: Table View

    let incomingMessageImage = UIImage(systemName: "square.and.arrow.down")
    let outgoingMessageImage = UIImage(systemName: "square.and.arrow.up")
    let failedMessageImage = UIImage(systemName: "exclamationmark.bubble")

    @IBOutlet weak var tableView: UITableView!

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        assert(section == 0)
        return messages.count + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        assert(indexPath.section == 0)

        if indexPath.row == 0 {
            return tableView.dequeueReusableCell(withIdentifier: "createMessageCell", for: indexPath)
        } else {
            let message = messages[indexPath.row - 1]
            let cell = tableView.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath) as! ConnectionMessageTableViewCell
            cell.bodyLabel.text = message.body
            cell.dateLabel.text = DateFormatter.localizedString(from: message.date, dateStyle: .short, timeStyle: .short)

            switch message.direction {
            case .incoming: cell.messageTypeImageView.image = incomingMessageImage
            case .outgoing: cell.messageTypeImageView.image = outgoingMessageImage
            case .none: cell.messageTypeImageView.image = failedMessageImage
            }

            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        assert(indexPath.section == 0)

        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.row == 0 {
            performSegue(withIdentifier: "navigateToCreateMessage", sender: self)
        }
    }

    // MARK: Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "navigateToConnectionDetails":
            let destination = segue.destination as! ConnectionDetailsViewController
            destination.pairwiseConnection = self.pairwiseConnection
        case "navigateToCreateMessage":
            let destination = segue.destination as! CreateMessageViewController
            destination.walletId = self.walletId
            destination.pairwiseConnection = self.pairwiseConnection
        default: break
        }
    }

    @IBAction func returnToConnection(unwindSegue: UIStoryboardSegue) {}
}

class ConnectionMessageTableViewCell: UITableViewCell {
    @IBOutlet weak var messageTypeImageView: UIImageView!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
}
