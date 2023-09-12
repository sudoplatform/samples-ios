//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoDIRelay

class MessageDetailsViewController: UITableViewController {

    // MARK: - Properties

    var messageId: String!
    var message: Message?

    // MARK: - Properties: Computed

    let relayClient: SudoDIRelayClient = AppDelegate.dependencies.sudoDIRelayClient

    // MARK: - Outlets

    @IBOutlet weak var messageIdLabel: UILabel!
    @IBOutlet weak var postboxIdLabel: UILabel!

    @IBOutlet weak var createdAtLabel: UILabel!
    @IBOutlet weak var ownerLabel: UILabel!

    @IBOutlet weak var sudoOwnerLabel: UILabel!
    @IBOutlet weak var messageContentsLabel: UITextView!

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        Task(priority: .high) {
            await updateMessageView()
        }
    }

    // MARK: - View

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        /// Tapping on a row.
        tableView.deselectRow(at: indexPath, animated: false)
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        /// Automatic cell height.
         return UITableView.automaticDimension
    }

    /// Attempt to retrieve the message from the server
    @MainActor func updateMessageView() async {
        await presentActivityAlert(message: "Fetching message")
        if let message = await fetchMessage(messageId: self.messageId) {
            self.message = message
        }
        messageIdLabel.text = messageId
        postboxIdLabel.text = message?.postboxId

        if let createdAt = message?.createdAt {
            createdAtLabel.text = ISO8601DateFormatter().string(from: createdAt)
            }
        ownerLabel.text = message?.ownerId
        sudoOwnerLabel.text = message?.sudoId
        messageContentsLabel.text = message?.message

        dismiss(animated: true) {
            self.tableView.reloadData()
        }
    }

    @MainActor func fetchMessage(messageId: String) async -> Message? {
        do {
            let result = try await relayClient.listMessages(limit: 20, nextToken: nil)
            return result.items.first(where: {$0.id == messageId})

        } catch {
            await presentErrorAlertOnMain("Could not fetch message.", error: error)
            return nil
        }
    }
}
