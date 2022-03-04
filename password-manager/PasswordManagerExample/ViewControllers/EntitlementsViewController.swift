//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoPasswordManager

@MainActor
class EntitlementsViewController: UITableViewController {
    
    private let client = Clients.passwordManagerClient!
    private var entitlements: [EntitlementState] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Entitlements"
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.loadData()
    }
    
    private func loadData() {
        Task {
            do {
                let entitlements = try await client.getEntitlementState()
                self.entitlements = entitlements
                self.tableView.reloadData()
            }
            catch {
                self.presentErrorAlert(message: "Failed to list entitlements", error: error)
            }
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entitlements.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let entitlement = self.entitlements[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Entitlement", for: indexPath) as! EntitlementCell
        cell.setEntitlement(entitlement)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
}
