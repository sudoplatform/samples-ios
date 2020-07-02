//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoProfiles
import SudoTelephony

class ConversationDetailsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var conversation: PhoneMessageConversation!
    var localNumber: PhoneNumber!
    var remoteNumber: String!
    
    private var messages: [PhoneMessage] = []
    
    private var messageSubscriptionToken: Any?
    
    private let incomingSMSImage = UIImage(systemName: "square.and.arrow.down")
    private let incomingMMSImage = UIImage(systemName: "arrow.down.doc")
    private let outgoingSMSImage = UIImage(systemName: "square.and.arrow.up")
    private let outgoingMMSImage = UIImage(systemName: "arrow.up.doc")
    
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        
        self.title = "Conversation"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if conversation?.latestPhoneMessage != nil {
            self.subscribeToMessages()
            
            self.listMessages { messages in
                DispatchQueue.main.async {
                    self.messages = messages.sorted(by: { $0.created > $1.created })
                    self.tableView.reloadData()
                }
            }
        } else {
            let alert = UIAlertController(title: "Error", message: "Unable to determine latest message in conversation", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    private func listMessages(onSuccess: @escaping ([PhoneMessage]) -> Void) {
        let telephonyClient = (UIApplication.shared.delegate as! AppDelegate).telephonyClient!
        
        func showFailureAlert(error: Error) {
            let alert = UIAlertController(title: "Error", message: "Failed to list messages:\n\(error)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
        var allLocalMessages: [PhoneMessage] = []
        
        func fetchPageOfMessages(listToken: String?) {
            do {
                try telephonyClient.getMessages(conversationId: self.conversation.id, limit: nil, nextToken: listToken) { result in
                    switch (result) {
                    case .success(let token):
                        allLocalMessages += token.items
                        
                        if let nextToken = token.nextToken {
                            fetchPageOfMessages(listToken: nextToken)
                        } else {
                            onSuccess(allLocalMessages)
                        }
                    case .failure(let error):
                        DispatchQueue.main.async {
                            showFailureAlert(error: error)
                        }
                    }
                }
            } catch let error {
                DispatchQueue.main.async {
                    showFailureAlert(error: error)
                }
            }
        }
        
        fetchPageOfMessages(listToken: nil)
    }
    
    private func subscribeToMessages() {
        let telephonyClient = (UIApplication.shared.delegate as! AppDelegate).telephonyClient!
        
        func showFailureAlert(error: Error) {
            let alert = UIAlertController(title: "Error", message: "Failed to subscribe to messages:\n\(error)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
        do {
            self.messageSubscriptionToken = try telephonyClient.subscribeToMessages { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let message):
                    // Ignore updates to messages we aren't displaying.
                    guard message.localPhoneNumber == self.localNumber?.phoneNumber,
                        message.remotePhoneNumber == self.remoteNumber else {
                            return
                    }
                    
                    self.listMessages { messages in
                        DispatchQueue.main.async {
                            self.messages = messages.sorted(by: { $0.created > $1.created })
                            self.tableView.reloadData()
                        }
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        showFailureAlert(error: error)
                    }
                }
            }
        } catch let error {
            showFailureAlert(error: error)
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1: return "Messages"
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 1:
            return messages.count + 1
        default:
            return 2
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            let cell = tableView.dequeueReusableCell(withIdentifier: "detailCell")!
            cell.textLabel?.text = "Your Number"
            cell.detailTextLabel?.text = formatAsUSNumber(number: localNumber?.phoneNumber ?? "?")
            return cell
        case (0, 1):
            let cell = tableView.dequeueReusableCell(withIdentifier: "detailCell")!
            cell.textLabel?.text = "Remote Number"
            cell.detailTextLabel?.text = formatAsUSNumber(number: self.remoteNumber ?? "?")
            return cell
        case (_, 0):
            return tableView.dequeueReusableCell(withIdentifier: "createCell", for: indexPath)
        default:
            let message = messages[indexPath.row - 1]

            let cell = tableView.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath)

            cell.textLabel?.text = message.body
            cell.detailTextLabel?.text = DateFormatter.localizedString(from: message.created, dateStyle: .short, timeStyle: .short)

            switch (message.direction, message.media.count > 0) {
            case (.inbound,  false): cell.imageView?.image = incomingSMSImage
            case (.inbound,   true): cell.imageView?.image = incomingMMSImage
            case (.outbound, false): cell.imageView?.image = outgoingSMSImage
            case (.outbound,  true): cell.imageView?.image = outgoingMMSImage
            default: break
            }

            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 1 else { return }

        if indexPath.row == 0 {
            self.performSegue(withIdentifier: "navigateToCreateMessage", sender: self.localNumber)
        }
        else {
            performSegue(withIdentifier: "navigateToMessageDetails", sender: messages[indexPath.row - 1])
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "navigateToCreateMessage":
            let createViewController = segue.destination as! CreateMessageViewController
            createViewController.localNumber = self.localNumber
            createViewController.remoteNumber = self.remoteNumber
        case "navigateToMessageDetails":
            let messageDetails = segue.destination as! MessageDetailsViewController
            let message = sender as! PhoneMessage
            messageDetails.message = message
        default: break
        }
    }
    
    @IBAction func returnToConversationDetailsFromCreateMessage(segue: UIStoryboardSegue) {}
    @IBAction func returnToConversationDetailsFromDeleteMessage(segue: UIStoryboardSegue) {}
}

class MessageListItemCell: UITableViewCell {}
