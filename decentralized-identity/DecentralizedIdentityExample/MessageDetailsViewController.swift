//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoDecentralizedIdentity

class MessageDetailsTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
}

class MessageDetailsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    // MARK: Message Details

    var messageResult: MessageDecryptionResult!

    typealias Field = (key: String, value: String)
    typealias Section = (header: String?, fields: [Field])
    private var sections: [Section]!

    override func viewDidLoad() {
        super.viewDidLoad()

        switch messageResult {
        case .decrypted(let message):
            sections = sectionsForDecryptedMessage(message)
        case .notDecrypted(let message, let error):
            sections = sectionsForNotDecryptedMessage(message, error)
        case .none:
            sections = []
        }
    }

    func sectionsForDecryptedMessage(_ message: DecryptedMessage) -> [Section] {
        let detailSections: [Section]
        let messageText: String

        switch message.body {
        case .text(let text):
            messageText = text
            detailSections = []
        case .message(let agentMessage as PreviewableDIDCommMessage, let json):
            messageText = json
            detailSections = [
                (agentMessage.typeDescription, agentMessage.detailFields),
                ("Agent Message", [
                    ("ID", agentMessage.id),
                    ("Type", agentMessage.type),
                ]),
            ]
        case .message(let agentMessage, let json):
            messageText = json
            detailSections = [("Agent Message", [
                ("ID", agentMessage.id),
                ("Type", agentMessage.type),
            ])]
        }

        let generalFields: [Field] = [
            ("Direction", message.direction == .incoming ? "Incoming" : "Outgoing"),
            ("Fetched At", DateFormatter.localizedString(
                from: message.date,
                dateStyle: .short,
                timeStyle: .long
            )),
            ("Message", messageText),
            ("Encrypted Message", String(decoding: message.encryptedBody, as: Unicode.UTF8.self)),
            ("Sender Verkey", message.senderVerkey ?? "(anoncrypt)"),
            ("Recipient Verkey", message.recipientVerkey),
        ]

        if detailSections.isEmpty {
            // don't display a section header if there's only one section
            return [(header: nil, fields: generalFields)]
        } else {
            return detailSections + [(header: "Generic Data", fields: generalFields)]
        }
    }

    func sectionsForNotDecryptedMessage(_ message: RelayedMessage, _ error: SudoDecentralizedIdentityClientError) -> [Section] {
        return [(header: nil, fields: [
            ("Status", "Failed to decrypt"),
            ("Error", error.localizedDescription),
            ("Date Received", DateFormatter.localizedString(
                from: message.date,
                dateStyle: .short,
                timeStyle: .short
            )),
            ("Encrypted Message", String(decoding: message.body, as: Unicode.UTF8.self)),
        ])]
    }

    // MARK: Table View

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].1.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! MessageDetailsTableViewCell
        cell.titleLabel.text = sections[indexPath.section].1[indexPath.row].0
        cell.bodyLabel.text = sections[indexPath.section].1[indexPath.row].1
        return cell
    }
}
