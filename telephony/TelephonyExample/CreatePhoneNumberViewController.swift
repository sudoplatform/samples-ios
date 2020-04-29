//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit

@objc(CreatePhoneNumberViewControllerHeaderCell) class HeaderCell: UITableViewCell {
    @IBOutlet weak var noResultsContainer: UIView!
    @IBOutlet weak var activityIndicatorContainer: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var countryLabel: UILabel!
    @IBOutlet weak var prefixTextField: UITextField!
    @IBOutlet weak var countryContainer: UIView!

    func configure(forState state: CreatePhoneNumberViewController.State) {
        switch state {
        case .initial, .results:
            noResultsContainer.isHidden = true
            activityIndicatorContainer.isHidden = true
            activityIndicator.stopAnimating()
        case .searching:
            noResultsContainer.isHidden = true
            activityIndicatorContainer.isHidden = false
            activityIndicator.startAnimating()
        case .noResults:
            noResultsContainer.isHidden = false
            activityIndicatorContainer.isHidden = true
            activityIndicator.stopAnimating()
        }
    }
}

class CreatePhoneNumberViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    enum State {
        case initial, searching, noResults, results
    }

    var sudoId: String!

    private var state: State = .initial
    @IBOutlet weak var tableView: UITableView!

    private var searchCountryCode: String? = nil
    private var searchPrefix: String? = nil
    private var searchResults: [String] = []

    override func viewDidLoad() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        assert(indexPath.section == 0)

        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "headerCell", for: indexPath) as! HeaderCell
            cell.configure(forState: state)
            if let countryCode = searchCountryCode {
                cell.countryLabel.text = countryCode
            }
            cell.prefixTextField.text = searchPrefix
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(countryTapped(_:)))
            cell.countryContainer.addGestureRecognizer(tapGesture)
            cell.prefixTextField.addTarget(self, action: #selector(prefixChanged(_:forEvent:)), for: .primaryActionTriggered)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.textLabel?.text = formatAsUSNumber(number: searchResults[indexPath.row - 1])
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        assert(indexPath.section == 0)
        guard indexPath.row > 0 else { return }

        tableView.deselectRow(at: indexPath, animated: true)

        let number = searchResults[indexPath.row - 1]

        self.view.endEditing(true)

        let alert = UIAlertController(title: "Provision", message: "Are you sure you want to provision \(number)?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Provision", style: .default) { action in
            self.provisionPhoneNumber(phoneNumber: number)
        })
        present(alert, animated: true, completion: nil)
    }

    @IBAction func infoTapped() {
        let alert = UIAlertController(title: "Phone Numbers", message: "Sudo Platform phone numbers have an associated country code.\nThe ZZ country code is used to simulate phone numbers without incurring costs.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Learn More", style: .default) { action in
            let docURL = URL(string: "https://docs.sudoplatform.com/guides/telephony/phone-numbers")!
            UIApplication.shared.open(docURL, options: [:], completionHandler: nil)
        })
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    @objc func countryTapped(_ sender: UITapGestureRecognizer) {
        let alert = UIAlertController(title: "Select Country", message: nil, preferredStyle: .actionSheet)

        let actionHandler: (UIAlertAction) -> Void = { action in
            let country = action.title
            self.searchCountryCode = country
            self.searchPhoneNumbers()
        }

        let telephonyClient = (UIApplication.shared.delegate as! AppDelegate).telephonyClient!

        do {
            try telephonyClient.getSupportedCountries { result in
                switch result {
                case .success(let countries):
                    DispatchQueue.main.async {
                        countries.map { country in
                            UIAlertAction(title: country, style: .default, handler: actionHandler)
                        }.forEach(alert.addAction)

                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

                        self.present(alert, animated: true, completion: nil)
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.presentErrorAlert(message: "Failed to list supported countries", error: error)
                    }
                }
            }
        } catch {
            presentErrorAlert(message: "Failed to list supported countries", error: error)
        }
    }

    @objc func prefixChanged(_ sender: UITextField, forEvent event: UIEvent) {
        sender.endEditing(true)
        self.searchPrefix = sender.text
        self.searchPhoneNumbers()
    }

    private func searchPhoneNumbers() {
        guard let countryCode = searchCountryCode else {
            state = .noResults
            tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
            return
        }

        state = .searching
        tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)

        let telephonyClient = (UIApplication.shared.delegate as! AppDelegate).telephonyClient!

        do {
            try telephonyClient.searchAvailablePhoneNumbers(countryCode: countryCode, prefix: searchPrefix ?? "", limit: nil) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .failure(let error):
                        self.state = .noResults
                        self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
                        self.presentErrorAlert(message: "Failed to search phone numbers", error: error)
                    case .success(let results):
                        self.searchResults = results.numbers
                        self.state = self.searchResults.count > 0 ? .results : .noResults
                        self.tableView.reloadData()
                    }
                }
            }
        } catch let error {
            presentErrorAlert(message: "Failed to search phone numbers", error: error)
        }
    }

    private func provisionPhoneNumber(phoneNumber: String) {
        let telephonyClient = (UIApplication.shared.delegate as! AppDelegate).telephonyClient!

        do {
            self.presentActivityAlert(message: "Provisioning")
            try telephonyClient.provisionPhoneNumber(countryCode: searchCountryCode!, phoneNumber: phoneNumber, sudoId: sudoId) { result in
                DispatchQueue.main.async {
                    // dismiss activity alert
                    self.dismiss(animated: true) {
                        switch result {
                        case .success(let phoneNumber):
                            let success = UIAlertController(title: "Success", message: nil, preferredStyle: .alert)
                            success.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                                self.performSegue(withIdentifier: "returnToPhoneNumberList", sender: self)
                            })
                            self.present(success, animated: true, completion: nil)
                        case .failure(let error):
                            self.presentErrorAlert(message: "Failed to provision phone number", error: error)
                        }
                    }
                }
            }
        } catch let error {
            dismiss(animated: true) {
                self.presentErrorAlert(message: "Failed to provision phone number", error: error)
            }
        }
    }
}
