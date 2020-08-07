//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoEmail
import SudoProfiles

class CreateEmailAddressViewController: UIViewController,
    UITableViewDataSource,
    UITableViewDelegate,
    ActivityAlertViewControllerDelegate,
    LearnMoreViewDelegate {

    // MARK: - Outlets

    /// Table view that lists the input field for the form.
    @IBOutlet var tableView: UITableView!

    /// Shows supplementary information to the input form, such as the chosen sudo and learn more.
    @IBOutlet var tableFooterView: UIView!

    /// View appearing at the end of the content providing learn more labels and buttons.
    @IBOutlet var learnMoreView: LearnMoreView!

    @IBOutlet var sudoLabel: UILabel!

    // MARK: - Supplementary

    /// Typealias for a successful response call to `SudoEmailClient.getEmailAddresssWithFilter(_:limit:nextToken:cachePolicy:completion:)`.
       typealias ProvisionEmailAddressSuccessCompletion = (EmailAddress) -> Void

       /// Typealias for a error response call to `SudoEmailClient.getEmailAddresssWithFilter(_:limit:nextToken:cachePolicy:completion:)`.
       typealias ProvisionEmailAddressErrorCompletion = (Error) -> Void

    enum Segue: String {
        case returnToEmailAddressList
    }

    // MARK: - Properties

    /// Label of a `Sudo` that was selected from the previous view. Used to present to the user.
    var sudoLabelText: String = ""

    /// `Sudo` that was selected from the previous view. Used to filter email addresses and provision a new email address.
    var sudo: Sudo = Sudo()

    var potentialAddresses: [String] = []

    // MARK: - Properties: Computed

    /// Email client used to get and create email addresses.
    var emailClient: SudoEmailClient {
        return AppDelegate.dependencies.emailClient
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureLearnMoreView()
        configureFooterValues()
        configureTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presentCancellableActivityAlert(message: "Loading", delegate: self) {
            self.emailClient.getSupportedEmailDomainsWithCachePolicy(.remoteOnly) { [weak self] result in
                DispatchQueue.main.async {
                    guard let weakSelf = self else { return }
                    switch result {
                    case let .failure(error):
                        weakSelf.dismissActivityAlert {
                            weakSelf.presentErrorAlert(message: "Error loading view: \(error.localizedDescription)")
                        }
                    case let .success(domains):
                        guard let domain = domains.first else {
                            weakSelf.dismissActivityAlert {
                                weakSelf.presentErrorAlert(message: "Error loading view: No supported domains available")
                            }
                            return
                        }
                        weakSelf.potentialAddresses = weakSelf.generateAddressesForDomain(domain)
                        weakSelf.tableView.reloadData()
                        weakSelf.dismissActivityAlert()
                    }
                }
            }
        }
    }

    // MARK: - Operations

    func provisionEmailAddress(
        _ address: String,
        success: @escaping ProvisionEmailAddressSuccessCompletion,
        failure: @escaping ProvisionEmailAddressErrorCompletion
    ) {
        emailClient.provisionEmailAddress(address, sudoId: sudo.id ?? "") { result in
            switch result {
            case let .success(address):
                success(address)
            case let .failure(error):
                failure(error)
            }
        }
    }

    // MARK: - Helpers: Configuration

    /// Configures the table view used to display the input form information.
    func configureTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "default")
        tableFooterView.backgroundColor = .none
        tableFooterView.translatesAutoresizingMaskIntoConstraints = true
        tableView.tableFooterView = tableFooterView
    }

    /// Configures the table footer values from the passed in `Sudo`.
    ///
    /// If a valid sudo is not found, an error will be presented to the user, which results in a segue back to the `EmailAddressListViewController`.
    func configureFooterValues() {
        guard let sudoLabelText = sudo.label, !sudoLabelText.isEmpty else {
            presentErrorAlert(
                message: "An error has occurred: no sudo label found",
                okHandler: { _ in
                    self.performSegue(withIdentifier: Segue.returnToEmailAddressList.rawValue, sender: self)
                }
            )
            return
        }
        guard let sudoId = sudo.id, !sudoId.isEmpty else {
            presentErrorAlert(
                message: "An error has occurred: no sudo id found",
                okHandler: { _ in
                    self.performSegue(withIdentifier: Segue.returnToEmailAddressList.rawValue, sender: self)
                }
            )
            return
        }
        sudoLabel.text = sudoLabelText
    }

    func configureLearnMoreView() {
        learnMoreView.delegate = self
        learnMoreView.label.text = "Addresses from different configured domains can be provisioned and used to communicate with other recipients. " +
        "The list above has been randonly generated based on the currently configured domains."
    }

    // MARK: - Helpers

    func generateAddressesForDomain(_ domain: String, count: Int = 5) -> [String] {
        return [String](repeating: "", count: count).map { _ in
            "\(String(UUID().uuidString.prefix(8).lowercased()))@\(domain)"
        }
    }

    // MARK: - Conformance: UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return potentialAddresses.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "default", for: indexPath)
        let address = potentialAddresses[indexPath.row]
        cell.textLabel?.text = address
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let address = potentialAddresses[indexPath.row]
        presentActivityAlert(message: "Provisioning...") {
            self.provisionEmailAddress(
                address,
                success: { [weak self, weak tableView] _ in
                    DispatchQueue.main.async {
                        tableView?.deselectRow(at: indexPath, animated: true)
                        self?.dismissActivityAlert {
                            self?.performSegue(withIdentifier: Segue.returnToEmailAddressList.rawValue, sender: self)
                        }
                    }
                },
                failure: { [weak self, weak tableView] error in
                    DispatchQueue.main.async {
                        tableView?.deselectRow(at: indexPath, animated: true)
                        self?.dismissActivityAlert {
                            self?.presentErrorAlert(message: "Failed to provision email address: \(error.localizedDescription)")
                        }
                    }
                }
            )
        }
    }

    // MARK: - Conformance: ActivityAlertViewControllerDelegate

    func didTapAlertCancelButton() {
        dismissActivityAlert {
            self.navigationController?.popViewController(animated: true)
        }
    }

    // MARK: - Conformance: LearnMoreViewDelegate

    func didTapLearnMoreButton() {
        guard let docURL = URL(string: "https://docs.sudoplatform.com/guides/email/manage-email-addresses") else {
            return
        }
        UIApplication.shared.open(docURL, options: [:], completionHandler: nil)
    }

}