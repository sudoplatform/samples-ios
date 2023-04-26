//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoUser
import SudoProfiles
import SudoVirtualCards

/// This View Controller presents a table view so that a user can navigate through each of the funding source creation menu items.
///
/// - Links From:
///     - `FundingSourceListViewController`: A user taps the "Create Funding Source" button.
/// - Links To:
///     - `CreateCardFundingSourceViewController`: If a user taps the "Add Stripe Credit Card" button, the `CreateCardFundingSourceViewController`
///         will be presented so the user can create a Stripe credit card based funding source.
///     - `CreateBankAccountFundingSourceViewController`: If a user taps the "Add Bank Account" button, the`CreateBankAccountFundingSourceViewController`
///         will be presented so the user can create a Checkout bank account based funding source.
class CreateFundingSourceMenuViewController: UIViewController,
                                             UITableViewDelegate,
                                             UITableViewDataSource {

    // MARK: - Outlets

    /// Table view that lists the menu items.
    @IBOutlet var tableView: UITableView!

    // MARK: - Supplementary

    /// Segues that are performed in `CreateFundingSourceMenuViewController`.
    enum Segue: String {
        /// Used to navigate to the `CreateCardFundingSourceViewController`.
        case navigateToAddStripeCreditCard
        /// Used to navigate to the `CreateBankAccountFundingSourceViewController`.
        case navigateToAddCheckoutBankAccount
    }

    /// Menu items shown on the table view.
    enum MenuItem: Int, CaseIterable {
        /// Add Stripe credit card table view item.
        case addStripeCreditCard
        /// Add Checkout bank account table view item.
        case addCheckoutBankAccount

        /// Title label of the table view item shown to the user.
        var displayTitle: String {
            switch self {
            case .addStripeCreditCard:
                return "Add Stripe Credit Card"
            case .addCheckoutBankAccount:
                return "Add Checkout Bank Account"
            }
        }
    }

    // MARK: - Properties

    /// Array of table view menu items used on the view.
    let tableData: [MenuItem] = MenuItem.allCases

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    // MARK: - Actions

    /// Action associated with tapping the "Info" button on the navigation bar.
    ///
    /// This action will present an informative alert with the option to to "Learn more".
    @objc func didTapInfoButton() {
        showInfoAlert()
    }

    // MARK: - Helpers: Configuration

    /// Configures the table view used to display the menu items.
    func configureTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "default")
        tableView.tableFooterView = UIView()
    }

    /// Configure the view's navigation bar.
    ///
    /// Sets the right bar to an info button which will display an informative alert.
    func configureNavigationBar() {
        let infoButton = UIButton(type: .infoLight)
        infoButton.addTarget(self, action: #selector(didTapInfoButton), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: infoButton)
    }

    // MARK: - Helpers

    /// Presents a `UIAlertController` containing an informative message and an action to redirect to a Sudo Platform webpage.
    func showInfoAlert() {
        let alert = UIAlertController(
            title: "What is a Funding Source?",
            message: "A Funding source is required to link a real credit card, debit card or bank account to a virtual card."
            + " This funding source is used to fund a transaction performed on the virtual card.",
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Learn More", style: .default) { _ in
            let docURL = URL(string: "https://docs.sudoplatform.com/guides/virtual-cards/manage-funding-sources")!
            UIApplication.shared.open(docURL, options: [:], completionHandler: nil)
        })
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    // MARK: - Conformance: UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let menuItem = tableData[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "default", for: indexPath)
        cell.textLabel?.text = menuItem.displayTitle
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    // MARK: - Conformance: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 0 else {
            return
        }
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        let menuItem = tableData[indexPath.row]
        switch menuItem {
        case .addStripeCreditCard:
            performSegue(
                withIdentifier: Segue.navigateToAddStripeCreditCard.rawValue,
                sender: self)
        case .addCheckoutBankAccount:
            performSegue(
                withIdentifier: Segue.navigateToAddCheckoutBankAccount.rawValue,
                sender: self)
        }
    }
}
