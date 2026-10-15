//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoEntitlements
import SudoEntitlementsAdmin

/// Lists the user's site reputation entitlements. If an entitlements admin API key has been provided (see README.md)
/// each entitlement can also be granted or revoked.
class EntitlementsViewController: UITableViewController {

    private struct EntitlementConsumptionModel {
        let name: String
        let value: Int64
        let consumed: Int64
        let available: Int64
    }

    private enum Values {
        static let siteReputationEntitlementPrefix = "sudoplatform.sr."
        static let docsURL = URL(string: "https://docs.sudoplatform.com/guides/entitlements")!
    }

    private let entitlementsClient: SudoEntitlementsClient = Clients.entitlementsClient
    private let entitlementsAdminClient: SudoEntitlementsAdminClient? = Clients.entitlementsAdminClient
    private var entitlementsList: [EntitlementConsumptionModel] = []
    private var externalUserId = ""

    init() {
        super.init(style: .insetGrouped)
        title = "Entitlements"
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = makeFooterView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task { await performWithActivity { try await self.loadEntitlementsList() } }
    }

    // MARK: - Operations

    private func loadEntitlementsList() async throws {
        externalUserId = try await entitlementsClient.getExternalId()
        let entitlementsConsumption = try await entitlementsClient.getEntitlementsConsumption()
        var models = entitlementsConsumption.entitlements.entitlements
            .filter { $0.name.hasPrefix(Values.siteReputationEntitlementPrefix) }
            .map { entitlement in
                let consumption = entitlementsConsumption.consumption.first { $0.name == entitlement.name }
                return EntitlementConsumptionModel(
                    name: entitlement.name,
                    value: entitlement.value,
                    consumed: consumption?.consumed ?? 0,
                    available: consumption?.available ?? entitlement.value
                )
            }
        // Always show the main site reputation entitlement so it can be granted to users who don't have it yet.
        if !models.contains(where: { $0.name == Authenticator.siteReputationEntitlementName }) {
            models.insert(
                EntitlementConsumptionModel(name: Authenticator.siteReputationEntitlementName, value: 0, consumed: 0, available: 0),
                at: 0
            )
        }
        entitlementsList = models
        tableView.reloadData()
    }

    private func setEntitlement(_ entitlementName: String, value: Int64) async throws {
        guard let entitlementsAdminClient else { return }
        // Apply replaces the user's whole entitlement set, so carry over everything else unchanged.
        let currentEntitlements = try await entitlementsAdminClient
            .getEntitlementsForUserWithExternalId(externalUserId)?
            .entitlements.entitlements ?? []
        var newEntitlements = currentEntitlements
            .filter { $0.name != entitlementName }
            .map { SudoEntitlementsAdmin.Entitlement(name: $0.name, description: $0.description, value: $0.value) }
        newEntitlements.append(SudoEntitlementsAdmin.Entitlement(name: entitlementName, value: value))
        _ = try await entitlementsAdminClient.applyEntitlementsToUserWithExternalId(externalUserId, entitlements: newEntitlements)
        try await loadEntitlementsList()
    }

    private func performWithActivity(_ operation: @escaping () async throws -> Void) async {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.startAnimating()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: spinner)
        view.isUserInteractionEnabled = false
        do {
            try await operation()
        } catch {
            presentErrorAlert(message: "Failure", error: error)
        }
        navigationItem.rightBarButtonItem = nil
        view.isUserInteractionEnabled = true
    }

    // MARK: - Helpers

    private func makeFooterView() -> UIView {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .secondaryLabel
        label.text = "An entitlement specifies how much of a Sudo Platform resource a user is entitled to consume. " +
            "A user must be entitled to use the Site Reputation service."

        let learnMoreButton = UIButton(type: .system, primaryAction: UIAction(title: "Learn More") { _ in
            UIApplication.shared.open(Values.docsURL)
        })

        let stack = UIStackView(arrangedSubviews: [label, learnMoreButton])
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20)
        stack.frame.size = stack.systemLayoutSizeFitting(
            CGSize(width: view.bounds.width, height: 0),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        return stack
    }

    // MARK: - UITableView

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entitlementsList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = entitlementsList[indexPath.row]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.selectionStyle = .none
        cell.textLabel?.text = model.name
        cell.detailTextLabel?.text = "Limit: \(model.value)   Used: \(model.consumed)   Available: \(model.available)"
        cell.detailTextLabel?.textColor = .secondaryLabel

        if entitlementsAdminClient != nil {
            let currentlyEntitled = model.value > 0
            let button = UIButton(type: .system, primaryAction: UIAction(title: currentlyEntitled ? "Revoke" : "Grant") { [weak self] _ in
                Task {
                    await self?.performWithActivity {
                        try await self?.setEntitlement(model.name, value: currentlyEntitled ? 0 : 1)
                    }
                }
            })
            button.sizeToFit()
            cell.accessoryView = button
        }
        return cell
    }
}
