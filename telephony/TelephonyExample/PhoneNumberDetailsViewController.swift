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
        case voicemail
    }

    /// Whether we are currently displaying message conversations, call records, or voicemail.
    private var currentSegment: Segment = .conversations

    /// Data source. Lazy so local number can be passed into the view controller
    lazy var dataSource: PhoneNumberDetailsDataSource = {
        return PhoneNumberDetailsDataSource(localNumber: self.localNumber)
    }()

    // MARK: - List conversations and calls

    var callSubscription: SubscriptionToken?
    var voicemailSubscription: SubscriptionToken?

    override func viewDidLoad() {
        super.viewDidLoad()

        let telephonyClient = (UIApplication.shared.delegate as! AppDelegate).telephonyClient!

        self.callSubscription = try! telephonyClient.subscribeToCallRecords { [weak self] (changes) in
            if case .calls = self?.currentSegment {
                self?.loadData()
            }
        }

        self.voicemailSubscription = try! telephonyClient.subscribeToVoicemails { [weak self] (changes) in
            if case .voicemail = self?.currentSegment {
                self?.loadData()
            }
        }
    }

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
            self.dataSource.fetchAllConversations { (result) in
                switch result {
                case .success:
                    self.tableView.reloadData()
                case .failure(let error):
                    self.presentErrorAlert(message: "Failed to fetch conversations", error: error)
                }
            }
        case .calls:
            self.dataSource.fetchAllCallRecords { (result) in
                switch result {
                case .success:
                    self.tableView.reloadData()
                case .failure(let error):
                    self.presentErrorAlert(message: "Failed to fetch call records", error: error)
                }
            }
        case .voicemail:
            self.dataSource.fetchAllVoicemails { result in
                switch result {
                case .success:
                    self.tableView.reloadData()
                case .failure(let error):
                    self.presentErrorAlert(message: "Failed to fetch voicemail", error: error)
                }
            }
        }
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
        case (.conversations, 1): return dataSource.conversations.count + 1
        case (.calls, 1): return dataSource.callRecords.count + 1
        case (.voicemail, 1): return dataSource.voicemails.count
        default: assertionFailure(); return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch (indexPath.section, indexPath.row, currentSegment) {
        case (0, 0, _):
            let cell = tableView.dequeueReusableCell(withIdentifier: "detailCell", for: indexPath)
            cell.detailTextLabel?.text = formatAsUSNumber(number: localNumber.phoneNumber)
            return cell
        case (0, 1, _):
            let cell = tableView.dequeueReusableCell(withIdentifier: "segmentCell", for: indexPath) as! SegmentCell
            cell.segmentedControl.selectedSegmentIndex = Segment.allCases.firstIndex(of: currentSegment) ?? 0
            cell.segmentChanged = { [weak self] in
                self?.currentSegment = Segment.allCases[$0]
                self?.loadData()
                self?.tableView.reloadSections([1], with: .none)
            }
            return cell
        case (1, 0, .conversations), (1, 0, .calls):
            let cell = tableView.dequeueReusableCell(withIdentifier: "createCell", for: indexPath)
            cell.textLabel?.text = {
                switch currentSegment {
                case .conversations: return "Compose Message"
                case .calls: return "Make a Call"
                default: return nil
                }
            }()
            return cell
        case (1, _, _):
            switch self.currentSegment {
            case .conversations:
                let cell = tableView.dequeueReusableCell(withIdentifier: "conversationCell", for: indexPath)
                let conversation = self.dataSource.conversations[indexPath.row - 1]
                let formattedNumber = conversation.latestPhoneMessage.map { formatAsUSNumber(number: $0.remotePhoneNumber) }
                cell.textLabel?.text = formattedNumber
                return cell
            case .calls:
                let cell = tableView.dequeueReusableCell(withIdentifier: "callRecordCell", for: indexPath)
                let call = self.dataSource.callRecords[indexPath.row - 1]
                let from = formatAsUSNumber(number: call.remotePhoneNumber)
                cell.textLabel?.text = from
                cell.imageView?.image = displayImage(for: call)
                return cell
            case .voicemail:
                let cell = tableView.dequeueReusableCell(withIdentifier: "voicemailCell", for: indexPath)
                let voicemail = self.dataSource.voicemails[indexPath.row]
                cell.textLabel?.text = formatAsUSNumber(number: voicemail.remotePhoneNumber)
                cell.detailTextLabel?.text = DateFormatter.localizedString(from: voicemail.created, dateStyle: .short, timeStyle: .short)
                return cell
            }
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
            self.performSegue(withIdentifier: "navigateToConversationDetails", sender: self.dataSource.conversations[indexPath.row - 1])
        case (.calls, 1, 0):
            self.performSegue(withIdentifier: "navigateToCreateVoiceCall", sender: nil)
        case (.calls, 1, _):
            let call = self.dataSource.callRecords[indexPath.row - 1]
            self.performSegue(withIdentifier: "callRecordDetailSegue", sender: call)
        case (.voicemail, 1, _):
            let voicemail = self.dataSource.voicemails[indexPath.row]
            self.performSegue(withIdentifier: "navigateToVoicemail", sender: voicemail)
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
        case "callRecordDetailSegue":
            let destination = segue.destination as! CallRecordDetailTableViewController
            destination.callRecord = sender as? CallRecord
        case "navigateToVoicemail":
            let destination = segue.destination as! VoicemailViewController
            destination.voicemail = sender as? Voicemail
        default:
            break
        }
    }
}



class PhoneNumberDetailsDataSource {

    let localNumber: PhoneNumber
    init(localNumber: PhoneNumber) {
        self.localNumber = localNumber
    }

    let telephonyClient = (UIApplication.shared.delegate as! AppDelegate).telephonyClient!

    var conversations: [PhoneMessageConversation] = []
    var callRecords: [CallRecord] = []
    var voicemails: [Voicemail] = []

    func fetchAllConversations(completion: @escaping (Swift.Result<[PhoneMessageConversation], Error>) -> Void) {

        var allConversations: [PhoneMessageConversation] = []

        func fetchPageOfConversations(listToken: String?) {
            do {
                try telephonyClient.getConversations(localNumber: self.localNumber, limit: nil, nextToken: listToken) { result in
                    switch result {
                    case .failure(let error):
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                    case .success(let token):
                        allConversations += token.items

                        if let tokenForNextPage = token.nextToken {
                            fetchPageOfConversations(listToken: tokenForNextPage)
                        } else {
                            DispatchQueue.main.async {
                                self.conversations = allConversations.sorted(by: { (lhs, rhs) -> Bool in
                                    return lhs.updated > rhs.updated
                                })
                                completion(.success(self.conversations))
                            }
                        }
                    }
                }
            } catch let error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }

        fetchPageOfConversations(listToken: nil)
    }

    func fetchAllCallRecords(completion: @escaping (Swift.Result<[CallRecord], Error>) -> Void) {

        let startTime = Date()
        NSLog("Fetching all call records")

        var allCalls: [CallRecord] = []

        func fetchPageOfCallRecords(listToken: String?) {
            do {
                try telephonyClient.getCallRecords(localNumber: self.localNumber, limit: 500, nextToken: listToken) { (result) in
                    switch result {
                    case .failure(let error):
                        NSLog("Fetch all call records failed with error: \(error)")
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                    case .success(let token):
                        allCalls += token.items

                        if let tokenForNextPage = token.nextToken {
                            NSLog("Fetching additional page of call records")
                            fetchPageOfCallRecords(listToken: tokenForNextPage)
                        } else {
                            DispatchQueue.main.async {
                                self.callRecords = allCalls.sorted(by: { (lhs, rhs) -> Bool in
                                    return lhs.created > rhs.created
                                })
                                NSLog("Successfullly fetched \(self.callRecords.count) call records in \(Date().timeIntervalSince(startTime)) seconds")
                                completion(.success(self.callRecords))
                            }
                        }
                    }
                }
            } catch let error {
                NSLog("Fetch all call records failed with error: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }


        fetchPageOfCallRecords(listToken: nil)
    }

    func fetchAllVoicemails(completion: @escaping (Swift.Result<[Voicemail], Error>) -> Void) {
        var allRecords: [Voicemail] = []

        func fetchPage(listToken: String?) {
            telephonyClient.getVoicemails(localNumber: self.localNumber, limit: 100, nextToken: listToken) { result in
                switch result {
                case .failure(let error):
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                case .success(let token):
                    allRecords += token.items

                    if let tokenForNextPage = token.nextToken {
                        fetchPage(listToken: tokenForNextPage)
                    } else {
                        DispatchQueue.main.async {
                            self.voicemails = allRecords.sorted(by: { (lhs, rhs) -> Bool in
                                return lhs.updated > rhs.updated
                            })
                            completion(.success(self.voicemails))
                        }
                    }
                }
            }
        }

        fetchPage(listToken: nil)
    }
}

func displayImage(for callRecord: CallRecord) -> UIImage? {
    let image: UIImage?
    switch callRecord.direction {
    case .inbound:
        image = UIImage(systemName: "phone.arrow.down.left")
    case .outbound:
        image = UIImage(systemName: "phone.arrow.up.right")
    default: image = nil
    }

    return image?.withTintColor(displayColor(for: callRecord), renderingMode: .alwaysOriginal)
}

func displayColor(for callRecord: CallRecord) -> UIColor {
    switch callRecord.state {
    case .completed:
        return .label
    case .unanswered:
        return .systemRed
    default:
        return .label
    }
}
