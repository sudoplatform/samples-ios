//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit

class MessageDetailsViewController: UITableViewController {
    @IBOutlet weak var directionLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var senderLabel: UILabel!
    @IBOutlet weak var recipientLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var encryptedMessageLabel: UILabel!

    var messageResult: MessageDecryptionResult!

    override func viewDidLoad() {
        super.viewDidLoad()

        dateLabel.text = DateFormatter.localizedString(
            from: messageResult.date,
            dateStyle: .short,
            timeStyle: .short
        )

        switch messageResult {
        case .decrypted(let message):
            directionLabel.text = message.direction == .incoming ? "Incoming" : "Outgoing"
            senderLabel.text = message.senderVerkey
            recipientLabel.text = message.recipientVerkey
            messageLabel.text = message.body
            encryptedMessageLabel.text = String(data: message.encryptedBody, encoding: .utf8)
        case .notDecrypted(let encryptedMessage, let error):
            directionLabel.text = "(Failed to decrypt)"
            senderLabel.text = "(Failed to decrypt)"
            recipientLabel.text = "(Failed to decrypt)"
            messageLabel.text = "(Failed to decrypt: \(error.localizedDescription))"
            encryptedMessageLabel.text = String(data: encryptedMessage.body, encoding: .utf8)
        case .none: break
        }
    }
}
