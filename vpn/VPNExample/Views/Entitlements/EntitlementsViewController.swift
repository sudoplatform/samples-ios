//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoUser
import SudoEntitlements

/// This View Controller presents a table view so that a user can navigate through each of the menu items.
///
/// - Links From:
///     - `SettingsViewController`: A user taps the "Entitlements" button.
class EntitlementsViewController: UIViewController,
    UITableViewDelegate,
    UITableViewDataSource,
    EntitlementsFooterViewDelegate {

    // MARK: - Outlets

    /// Table view that lists the menu items.
    @IBOutlet var tableView: UITableView!

    // MARK: - Supplementary

    enum Values {
        static let vpnEntitlementPrefix = "sudoplatform.vpn."
    }

    // MARK: - Properties

    var vpnClient = AppDelegate.dependencies.vpnClient

    /// Authenticator used to perform authentication during de-registration.
    var authenticator = AppDelegate.dependencies.authenticator

    var entitlementsClient = AppDelegate.dependencies.entitlementsClient

    var entitlementsList: [EntitlementConsumptionModel] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureLearnMoreView()
        configureTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        presentActivityAlert(message: "Loading Entitlements") { [weak self] in
            Task { [weak self] in
                await self?.loadEntitlementsList()
            }
        }
        super.viewWillAppear(animated)
    }

    // MARK: - Operations

    func loadEntitlementsList() async {
        do {
            let entitlementsConsumption = try await entitlementsClient.getEntitlementsConsumption()
            let models: [EntitlementConsumptionModel] = entitlementsConsumption.entitlements.entitlements.map { entitlement in
                let consumed = entitlementsConsumption.consumption.first(where: { $0.name == entitlement.name })?.consumed
                return EntitlementConsumptionModel(
                    name: entitlement.name,
                    value: entitlement.value,
                    consumed: consumed ?? 0,
                    available: entitlement.value
                )
            }
            self.entitlementsList = self.filterVpnEntitlementConsumptionModels(models)
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
                self?.dismissActivityAlert()
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.dismissActivityAlert()
                self?.presentErrorAlert(message: "Failure", error: error)
            }
        }
    }

    // MARK: - Helpers: Configuration

    /// Configures the table view.
    func configureTableView() {
        let entitlementsTableViewCellNib = UINib(nibName: "EntitlementsTableViewCell", bundle: .main)
        tableView.register(entitlementsTableViewCellNib, forCellReuseIdentifier: "entitlementsCell")
    }

    /// Configures the table footer
    func configureLearnMoreView() {
        let entitlementsFooterViewNib = UINib(nibName: "EntitlementsFooterView", bundle: .main)
        tableView.register(entitlementsFooterViewNib, forHeaderFooterViewReuseIdentifier: "EntitlementsFooter")
        tableView.sectionFooterHeight = UITableView.automaticDimension
        tableView.estimatedSectionFooterHeight = 100
    }

    // MARK: - Helpers

    func filterVpnEntitlementConsumptionModels(_ models: [EntitlementConsumptionModel]) -> [EntitlementConsumptionModel] {
        return models.filter({ $0.name.contains(Values.vpnEntitlementPrefix) })
    }

    // MARK: - UITableView

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entitlementsList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "entitlementsCell") as? EntitlementsTableViewCell else {
            NSLog("Failed to get entitlementsCell")
            return EntitlementsTableViewCell()
        }
        let consumption = entitlementsList[indexPath.row]
        cell.setConsumption(consumption)
        return cell
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard !entitlementsList.isEmpty else {
            return nil
        }
        guard let footer = tableView.dequeueReusableHeaderFooterView(withIdentifier: "EntitlementsFooter") as? EntitlementsFooterView else {
            NSLog("Failed to get entitlements footer")
            return EntitlementsFooterView()
        }
        footer.moreInfoLabel.text = "An entitlement specifies how much of a Sudo Platform resource a user is entitled to consume. " +
        "A user must be entitled to use the various VPN features."
        footer.delegate = self
        return footer
    }

    // MARK: - Conformance: EntitlementsFooterViewDelegate

    func didTapLearnMoreButton() {
        guard let docURL = URL(string: "https://docs.sudoplatform.com/guides/virtual-private-network/vpn-entitlements") else {
            return
        }
        UIApplication.shared.open(docURL, options: [:], completionHandler: nil)
    }

}
