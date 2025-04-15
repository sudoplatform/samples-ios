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
///     - `CreateStripeCardFundingSourceViewController`: If a user taps the "Add Stripe Credit Card" button, the `CreateStripeCardFundingSourceViewController`
///         will be presented so the user can create a Stripe credit card based funding source.
///     - `CreateCheckoutBankAccountFundingSourceViewController`: If a user taps the
///     "Add Checkout Bank Account" button, the `CreateCheckoutBankAccountFundingSourceViewController`
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
        /// Used to navigate to the `CreateStripeCardFundingSourceViewController`.
        case navigateToAddStripeCreditCard
        /// Used to navigate to the `CreateCheckoutBankAccountFundingSourceViewController`.
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

    /// Virtual cards client used to get and create funding sources.
    var virtualCardsClient: SudoVirtualCardsClient {
        return AppDelegate.dependencies.virtualCardsClient
    }

    ///  funding source configuration data
    var haveConfig: Bool = false
    var stripeCardConfig: StripeCardClientConfiguration!
    var checkoutBankAccountConfig: CheckoutBankAccountClientConfiguration!

    /// Array of table view menu items used on the view.
    var tableData: [MenuItem] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureTableView()

        if !haveConfig {
            Task { @MainActor in
                presentActivityAlert(message: "Loading funding source configuration")
                let virtualCardsConfig = try? await virtualCardsClient.getVirtualCardsConfig()
                guard let virtualCardsConfig else {
                    return
                }
                let configs = virtualCardsConfig.fundingSourceClientConfiguration
                for config in configs {
                    switch config {
                    case .checkoutBankAccount(let config):
                        tableData.append(.addCheckoutBankAccount)
                        checkoutBankAccountConfig = config

                    case .stripeCard(let config):
                        tableData.append(.addStripeCreditCard)
                        stripeCardConfig = config

                    case .unknown:
                        break
                    }
                }
                haveConfig = true

                tableView.reloadData()
                dismissActivityAlert()
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard
            let segueIdentifier = segue.identifier,
            Segue(rawValue: segueIdentifier) == .navigateToAddStripeCreditCard,
            let createStripeCardFundingSource = segue.destination as? CreateStripeCardFundingSourceViewController
        else {
            return
        }
        createStripeCardFundingSource.configuration = stripeCardConfig
    }

    // MARK: - Actions

    /// Action associated with tapping the "Info" button on the navigation bar.
    ///
    /// This action will present an informative alert with the option to to "Learn more".
    @objc func didTapInfoButton() {
        showInfoAlert()
    }

    /// Action associated with returning to this view from a segue.
    @IBAction func returnToCreateFundingSourceMenu(segue: UIStoryboardSegue) {
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
