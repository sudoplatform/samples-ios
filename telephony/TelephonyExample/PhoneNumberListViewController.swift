//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoProfiles
import SudoTelephony

class PhoneNumberListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    var sudo: Sudo!
    private var phoneNumbers: [PhoneNumber] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()

        navigationItem.title = sudo.label ?? "New Sudo"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)

        listAllPhoneNumbers { phoneNumbers in
            DispatchQueue.main.async {
                self.phoneNumbers = phoneNumbers
                self.tableView.reloadData()
            }
        }
    }

    private func listAllPhoneNumbers(onSuccess: @escaping ([PhoneNumber]) -> Void) {
        let telephonyClient = (UIApplication.shared.delegate as! AppDelegate).telephonyClient!

        var allPhoneNumbers: [PhoneNumber] = []

        func fetchPageOfPhoneNumbers(listToken: String?) {
            do {
                try telephonyClient.listPhoneNumbers(sudoId: sudo.id, limit: nil, nextToken: listToken) { result in
                    switch result {
                    case .failure(let error):
                        DispatchQueue.main.async {
                            self.presentErrorAlert(message: "Unable to list phone numbers", error: error)
                        }
                    case .success(let token):
                        // `listPhoneNumbers` calls this block twice - first for cached data then for remote data.
                        // When we receive the first page of remote items, restart accumulating allPhoneNumbers.
                        if listToken == nil {
                            allPhoneNumbers = token.items
                        } else {
                            allPhoneNumbers += token.items
                        }

                        if let tokenForNextPage = token.nextToken {
                            fetchPageOfPhoneNumbers(listToken: tokenForNextPage)
                        } else {
                            onSuccess(allPhoneNumbers)
                        }
                    }
                }
            } catch let error {
                DispatchQueue.main.async {
                    self.presentErrorAlert(message: "Unable to list phone numbers", error: error)
                }
            }
        }

        fetchPageOfPhoneNumbers(listToken: nil)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return phoneNumbers.count + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        assert(indexPath.section == 0)

        if indexPath.row == phoneNumbers.count {
            return tableView.dequeueReusableCell(withIdentifier: "createCell", for: indexPath)
        } else {
            let phoneNumber = phoneNumbers[indexPath.row]

            let cell = tableView.dequeueReusableCell(withIdentifier: "phoneNumberCell", for: indexPath)
            cell.textLabel?.text = formatAsUSNumber(number: phoneNumber.phoneNumber)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        assert(indexPath.section == 0)

        if indexPath.row == phoneNumbers.count {
            performSegue(withIdentifier: "navigateToCreatePhoneNumber", sender: sudo.id!)
        } else {
            performSegue(withIdentifier: "navigateToConversations", sender: phoneNumbers[indexPath.row])
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "navigateToCreatePhoneNumber":
            let createViewController = segue.destination as! CreatePhoneNumberViewController
            let sudoId = sender as! String
            createViewController.sudoId = sudoId
        case "navigateToConversations":
            let conversationList = segue.destination as! ConversationListViewController
            conversationList.localNumber = sender as! PhoneNumber
        default: break
        }
    }

    @IBAction func returnToPhoneNumberList(segue: UIStoryboardSegue) {}
}
