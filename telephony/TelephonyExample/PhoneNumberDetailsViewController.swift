//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoTelephony

/// Displays information about the user's phone number as well as a list of conversations and call records.
class PhoneNumberDetailsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    /// The local phone number, i.e. the number messages are sent from.
    var localNumber: PhoneNumber!

    private enum Segment: CaseIterable {
        case conversations
        case calls
    }

    /// Whether we are currently displaying message conversations or call records.
    private var currentSegment: Segment = .conversations

    /// Array of conversations to drive the table view with.
    private var conversations: [PhoneMessageConversation] = []
    /// Array of call records to drive the table view with.
    private var calls: [Void] = []

    // MARK: - List conversations and calls

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // This loads the conversation list when the view is first appears.
        // It also serves as a simple way to keep the list up to date if you compose a new message.
        self.loadData()
    }

    /// Loads data into the tableview.
    private func loadData() {
        switch currentSegment {
        case .conversations:
            self.listAllConversations { conversations in
                DispatchQueue.main.async {
                    self.conversations = conversations.sorted(by: { (lhs, rhs) -> Bool in
                        return lhs.updated < rhs.updated
                    })
                    self.tableView.reloadData()
                }
            }
        case .calls:
            // TODO: Implement when call records exist.
            self.calls = []
            self.tableView.reloadData()
        }
    }

    private func listAllConversations(onSuccess: @escaping ([PhoneMessageConversation]) -> Void) {
        let telephonyClient = (UIApplication.shared.delegate as! AppDelegate).telephonyClient!

        var allConversations: [PhoneMessageConversation] = []

        func fetchPageOfConversations(listToken: String?) {
            do {
                try telephonyClient.getConversations(localNumber: self.localNumber, limit: nil, nextToken: listToken) { result in
                    switch result {
                    case .failure(let error):
                        DispatchQueue.main.async {
                            self.presentErrorAlert(message: "Unable to list conversations", error: error)
                        }
                    case .success(let token):
                        allConversations += token.items

                        if let tokenForNextPage = token.nextToken {
                            fetchPageOfConversations(listToken: tokenForNextPage)
                        } else {
                            onSuccess(allConversations)
                        }
                    }
                }
            } catch let error {
                DispatchQueue.main.async {
                    self.presentErrorAlert(message: "Unable to list conversations", error: error)
                }
            }
        }

        fetchPageOfConversations(listToken: nil)
    }

    // MARK: - Delete phone number

    @IBAction func deletePressed(_ sender: Any) {
        let alert = UIAlertController(title: "Delete Number", message: "Are you sure you want to delete this number? You will lose access to it and all associated messages", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .default) { _ in
            self.deleteNumber()
        })
        present(alert, animated: true, completion: nil)
    }

    private func deleteNumber() {
        let telephonyClient = (UIApplication.shared.delegate as! AppDelegate).telephonyClient!

        self.presentActivityAlert(message: "Deleting")
        do {
            try telephonyClient.deletePhoneNumber(phoneNumber: self.localNumber.phoneNumber) { (result) in

                DispatchQueue.main.async {
                    // dismiss activity alert
                    self.dismiss(animated: true, completion: nil)

                    switch result {
                    case .success:

                        let alert = UIAlertController(title: "Deleted Number", message: nil, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                            self.navigationController?.popViewController(animated: true)
                        }))
                        self.present(alert, animated: true, completion: nil)

                    case .failure(let error):
                        self.presentErrorAlert(message: "Failed to delete number", error: error)
                    }
                }
            }
        } catch let error {
            self.dismiss(animated: true) {
                self.presentErrorAlert(message: "Failed to delete number", error: error)
            }
        }
    }

    // MARK: - UITableViewDataSource

    @IBOutlet weak var tableView: UITableView!

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (currentSegment, section) {
        case (_, 0): return 2
        case (.conversations, 1): return conversations.count + 1
        case (.calls, 1): return calls.count + 1
        default: assertionFailure(); return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            let cell = tableView.dequeueReusableCell(withIdentifier: "detailCell", for: indexPath)
            cell.detailTextLabel?.text = formatAsUSNumber(number: localNumber.phoneNumber)
            return cell
        case (0, 1):
            let cell = tableView.dequeueReusableCell(withIdentifier: "segmentCell", for: indexPath) as! SegmentCell
            cell.segmentedControl.selectedSegmentIndex = Segment.allCases.firstIndex(of: currentSegment) ?? 0
            cell.segmentChanged = { [weak self] in
                self?.currentSegment = Segment.allCases[$0]
                self?.tableView.reloadSections([1], with: .none)
            }
            return cell
        case (1, 0):
            let cell = tableView.dequeueReusableCell(withIdentifier: "createCell", for: indexPath)
            cell.textLabel?.text = {
                switch currentSegment {
                case .conversations: return "Compose Message"
                case .calls: return "Make a Call"
                }
            }()
            return cell
        case (1, _):
            let cell = tableView.dequeueReusableCell(withIdentifier: "conversationCell", for: indexPath)
            let conversation = self.conversations[indexPath.row - 1]
            let formattedNumber = conversation.latestPhoneMessage.map { formatAsUSNumber(number: $0.remotePhoneNumber) }
            cell.textLabel?.text = formattedNumber
            return cell
        default:
            assertionFailure()
            return UITableViewCell()
        }
    }

    @objc(PhoneNumberDetailsSegmentCell) class SegmentCell: UITableViewCell {
        @IBOutlet weak var segmentedControl: UISegmentedControl!

        var segmentChanged: ((Int) -> Void)?

        @IBAction func segmentedControlChanged(_ sender: UISegmentedControl) {
            segmentChanged?(sender.selectedSegmentIndex)
        }
    }

    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch (currentSegment, indexPath.section, indexPath.row) {
        case (.conversations, 1, 0):
            self.performSegue(withIdentifier: "navigateToCreateMessage", sender: nil)
        case (.conversations, 1, _):
            self.performSegue(withIdentifier: "navigateToConversationDetails", sender: self.conversations[indexPath.row - 1])
        case (.calls, 1, 0):
            self.performSegue(withIdentifier: "navigateToCreateVoiceCall", sender: nil)
        case (.calls, 1, _):
            // TODO: Implement when call records exist.
            break
        default: break
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch (indexPath.section, indexPath.row) {
        case (0, 0), (0, 1): return 56
        default: return UITableView.automaticDimension
        }
    }

    // MARK: Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "navigateToCreateMessage":
            let createViewController = segue.destination as! CreateMessageViewController
            createViewController.localNumber = self.localNumber
            createViewController.remoteNumber = nil
        case "navigateToConversationDetails":
            let conversationDetails = segue.destination as! ConversationDetailsViewController
            let conversation = sender as! PhoneMessageConversation
            guard let message = conversation.latestPhoneMessage else { return }
            conversationDetails.localNumber = self.localNumber
            conversationDetails.remoteNumber = message.remotePhoneNumber
            conversationDetails.conversation = conversation
        case "navigateToCreateVoiceCall":
            let destination = segue.destination as! CreateVoiceCallViewController
            destination.localNumber = self.localNumber
        default:
            break
        }
    }
}
