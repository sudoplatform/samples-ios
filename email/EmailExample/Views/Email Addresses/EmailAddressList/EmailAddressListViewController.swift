//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoEmail
import SudoProfiles

/// This View Controller presents a list of `EmailAddresses` associated with a `Sudo`.
///
/// - Links From:
///     - `CreateEmailAddressViewController`: A user chooses the "Create" option from the top right corner of the navigation bar.
///     - `SudoListViewController`: A user chooses a `Sudo` which will show this view with the list of email addressess created against this sudo. The email
///         `address` property is used as the text for each email.
/// - Links To:
///     - `CreateEmailAddressViewController`: If a user taps the "Create Email Address" button, the `CreateEmailAddressViewController` will be presented so the
///         user can add a new email address to their sudo.
class EmailAddressListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // MARK: - Outlets

    /// The table view that lists each email address associated with the chosen `Sudo` from the previous view.
    ///
    /// If the user does not have any `EmailAddressess` associated to this `Sudo`, then only the "Create Email Address" entry will be seen. This can be tapped
    /// to add a email to the sudo.
    @IBOutlet weak var tableView: UITableView!

    // MARK: - Supplementary

    /// Defaults used in `EmailAddressListViewController`.
    enum Defaults {
        /// Limit used when querying email addresses from `SudoEmailClient`.
        static let emailListLimit = 30
    }

    /// Segues that are performed in `EmailAddressListViewController`.
    enum Segue: String {
        /// Used to navigate to the `CreateEmailAddressViewController`.
        case navigateToCreateEmailAddress
        /// Used to navigate to the `EmailMessageListViewController`.
        case navigateToEmailMessageList
        /// Used to navigate back to the `SudoListViewController`.
        case returnToSudoList
    }

    // MARK: - Properties

    /// Label of a `Sudo` that was selected from the previous view. Used to present to the user.
    var sudoLabelText: String = ""

    /// `Sudo` that was selected from the previous view. Used to filter email addresses and provision a new email address.
    var sudo: Sudo = Sudo()

    /// A list of `EmailAddresses` that are associated with the `sudoId`.
    var emailAddresses: [EmailAddress] = []

    // MARK: - Properties: Computed

    /// Email client used to get and create email addresses.
    var emailClient: SudoEmailClient {
        return AppDelegate.dependencies.emailClient
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let sudoLabel = sudo.label, !sudoLabel.isEmpty else {
            presentErrorAlert(
                message: "An error has occurred: no sudo label found",
                okHandler: { _ in
                    self.performSegue(withIdentifier: Segue.returnToSudoList.rawValue, sender: self)
                }
            )
            return
        }
        guard let sudoId = sudo.id, !sudoId.isEmpty else {
            presentErrorAlert(
                message: "An error has occurred: no sudo id found",
                okHandler: { _ in
                    self.performSegue(withIdentifier: Segue.returnToSudoList.rawValue, sender: self)
                }
            )
            return
        }

        Task.detached(priority: .medium) {
            await self.loadCacheEmailAddressesAndFetchRemote()
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let segueType = Segue(rawValue: segue.identifier ?? "")
        switch segueType {
        case .navigateToCreateEmailAddress:
            guard let createEmailAddress = segue.destination as? CreateEmailAddressViewController else {
                break
            }
            createEmailAddress.sudo = sudo
        case .navigateToEmailMessageList:
            guard let emailMessageList = segue.destination as? EmailMessageListViewController, let row = tableView.indexPathForSelectedRow?.row else {
                break
            }
            emailMessageList.emailAddress = emailAddresses[row]
        default:
            break
        }
    }

    // MARK: - Actions

    /// Action associated with returning to this view from a segue.
    ///
    /// This action will ensure that the email address list is up to date when returning from views - e.g. `CreateEmailAddressViewController`.
    @IBAction func returnToEmailAddressList(segue: UIStoryboardSegue) {
        Task.detached(priority: .medium) {
            await self.loadCacheEmailAddressesAndFetchRemote()
        }
    }

    // MARK: - Operations

    func listEmailAddresses(
        cachePolicy: SudoEmail.CachePolicy
    ) async throws -> [EmailAddress] {
        let listEmailAddressesInput = ListEmailAddressesInput(
            cachePolicy: cachePolicy,
            limit: Defaults.emailListLimit,
            nextToken: nil
        )
        let output = try await emailClient.listEmailAddresses(withInput: listEmailAddressesInput)
        return output.items
    }

    func deleteEmailAddressWithId(_ id: String) async throws -> EmailAddress {
        presentActivityAlert(message: "Deleting Email Address")
        do {
            let emailAddress = try await emailClient.deprovisionEmailAddress(id)
            self.dismissActivityAlert()
            return emailAddress
        } catch {
            self.dismissActivityAlert()
            self.presentErrorAlert(message: "Failed to delete email address", error: error)
            throw error
        }
    }

    // MARK: - Helpers: Configuration

    /// Configures the table view used to display the navigation elements.
    func configureTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "default")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "create")
        tableView.tableFooterView = UIView()
    }

    // MARK: - Helpers

    /// Firstly, attempts to load all the email addresses from the device's cache, and then update via a remote call.
    ///
    /// On any failure, either by cache or remote call, a "Failed to list email addresses" UIAlert message will be presented to the user.
    ///
    /// All email addresses will be filtered using the `sudoId` to ensure only email addresses associated with the sudo are listed.
    func loadCacheEmailAddressesAndFetchRemote() async {
        do {
            let localAddresses = try await listEmailAddresses(cachePolicy: .cacheOnly)

            Task { @MainActor in
                self.emailAddresses = self.filterEmailAddresses(localAddresses, withSudoId: self.sudo.id ?? "")
                self.tableView.reloadData()
            }

            let remoteAddresses = try await listEmailAddresses(cachePolicy: .remoteOnly)

            Task { @MainActor in
                self.emailAddresses = self.filterEmailAddresses(remoteAddresses, withSudoId: self.sudo.id ?? "")
                self.tableView.reloadData()
            }
        } catch {
            Task { @MainActor in
                self.presentErrorAlert(message: "Failed to list Email Addresses", error: error)
            }
        }
    }

    /// Filter a list of email addresses by a sudo identifier.
    ///
    /// - Parameters:
    ///   - emailAddresses: `EmailAddresses` to be filtered.
    ///   - sudoId: Sudo Identifier to use to filter the email addresses.
    /// - Returns: Filtered email addressess.
    func filterEmailAddresses(_ emailAddresses: [EmailAddress], withSudoId sudoId: String) -> [EmailAddress] {
        return emailAddresses.filter { $0.owners.contains { $0.id == sudoId } }
    }

    // MARK: - Conformance: UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    @MainActor
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return emailAddresses.count + 1
    }

    @MainActor
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        if indexPath.row == emailAddresses.count {
            cell = tableView.dequeueReusableCell(withIdentifier: "create", for: indexPath)
            cell.textLabel?.text = "Create Email Address"
            cell.textLabel?.textColor = UIColor.systemBlue
            cell.accessoryView = UIImageView(image: UIImage.init(systemName: "plus"))
            cell.semanticContentAttribute = .forceRightToLeft
        } else {
            let emailAddress = emailAddresses[indexPath.row]
            cell = tableView.dequeueReusableCell(withIdentifier: "default", for: indexPath)
            if let displayName = emailAddress.alias {
                if displayName.isEmpty {
                    cell.textLabel?.text = "\(emailAddress.emailAddress)"
                } else {
                    cell.textLabel?.text = "\(displayName)  <\(emailAddress.emailAddress)>"
                }
            } else {
                cell.textLabel?.text = "\(emailAddress.emailAddress)"
            }
            cell.textLabel?.minimumScaleFactor = 0.7
            cell.textLabel?.adjustsFontSizeToFitWidth = true
            cell.accessoryType = .disclosureIndicator
        }
        return cell
    }

    // MARK: - Conformance: UITableViewDelegate

    @MainActor
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        assert(indexPath.section == 0)
        if indexPath.row == emailAddresses.count {
            performSegue(withIdentifier: Segue.navigateToCreateEmailAddress.rawValue, sender: self)
        } else {
            performSegue(withIdentifier: Segue.navigateToEmailMessageList.rawValue, sender: self)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    @MainActor
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.row < emailAddresses.count else {
            return nil
        }
        let cancel = UIContextualAction(style: .destructive, title: "Delete") { _, _, completion in
            let emailAddress = self.emailAddresses[indexPath.row]

            Task.detached(priority: .medium) {
                do {
                    _ = try await self.deleteEmailAddressWithId(emailAddress.id)
                    Task { @MainActor in
                        self.emailAddresses.remove(at: indexPath.row)
                        self.tableView.deleteRows(at: [indexPath], with: .automatic)
                        completion(true)
                    }
                } catch {
                    completion(false)
                }
            }
        }
        cancel.backgroundColor = .red
        return UISwipeActionsConfiguration(actions: [cancel])
    }

}
