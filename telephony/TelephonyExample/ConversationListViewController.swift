//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoTelephony

class ConversationListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // The users phone number, i.e. the number messages are sent from.
    var localNumber: PhoneNumber!

    // array of conversations to drive the tableview from
    private var conversations: [PhoneMessageConversation] = []

    var client = (UIApplication.shared.delegate as! AppDelegate).telephonyClient!

    @IBOutlet weak var conversationListTableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        conversationListTableView.delegate = self
        conversationListTableView.dataSource = self
        conversationListTableView.tableFooterView = UIView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // This loads the conversation list when the view is first appears.
        // It also serves as a simple way to keep the list up to date if you compose a new message.
        self.loadData()
    }

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

    /// Loads data into the tableview.
    private func loadData() {
        self.listAllConversations { conversations in
            DispatchQueue.main.async {
                self.conversations = conversations.sorted(by: { (lhs, rhs) -> Bool in
                    return lhs.updated < rhs.updated
                })
                self.conversationListTableView.reloadData()
            }
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
        default:
            break
        }
    }

    //MARK: Data Source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 { return nil }
        return "Conversations"
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section > 0 else { return 1 }
        return self.conversations.count + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch (indexPath.section, indexPath.row) {
        case (0, _):
            let cell = tableView.dequeueReusableCell(withIdentifier: "detailCell")!
            cell.detailTextLabel?.text = formatAsUSNumber(number: localNumber.phoneNumber)
            return cell
        case (_, 0):
            return tableView.dequeueReusableCell(withIdentifier: "createCell")!
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "conversationCell")!
            let conversation = self.conversations[indexPath.row - 1]
            let formattedNumber = conversation.latestPhoneMessage.map { formatAsUSNumber(number: $0.remotePhoneNumber) }
            cell.textLabel?.text = formattedNumber
            return cell
        }
    }

    //MARK: Delegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section > 0 else { return }

        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.row == 0 {
            self.performSegue(withIdentifier: "navigateToCreateMessage", sender: nil)
        }
        else {
            self.performSegue(withIdentifier: "navigateToConversationDetails", sender: self.conversations[indexPath.row - 1])
        }
        
    }
}
