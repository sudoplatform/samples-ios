//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoVPN

@MainActor
class ProtocolsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SudoVPNSubscriber {

    // MARK: - Outlets

    /// Table view that lists the menu items.
    @IBOutlet var tableView: UITableView!

    // MARK: - Properties

    let subscriberId = UUID().uuidString

    var vpnClient = AppDelegate.dependencies.vpnClient

    var supportedProtocols: [SudoVPNProtocol] = []

    var configuration: SudoVPNConfiguration?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        Task {
            await configureTableView()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task {
            await vpnClient.subscribe(id: subscriberId, subscriber: self)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Task {
            await vpnClient.unsubscribe(id: subscriberId)
        }
    }

    // MARK: - Helpers

    func displayTitleForProtocolType(_ protocolType: SudoVPNProtocol) -> String {
        switch protocolType {
        case .ipsec:
            return "Internet Protocol Security (IPSEC)"
        case .ikev2:
            return "Internet Key Exchange V2 (IKEv2)"
        case .wireGuard:
            return "WireGuard"
        case .unknown(let string):
            return "Unknown: \(String(describing: string))"
        }
    }

    // MARK: - Helpers: Configuration

    /// Configures the table view.
    func configureTableView() async {
        supportedProtocols = await vpnClient.supportedProtocols
        configuration = await vpnClient.configuration
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "default")
        tableView.tableFooterView = UIView()
        tableView.reloadData()
    }

    // MARK: - Conformance: UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return supportedProtocols.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let protocolType = supportedProtocols[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "default", for: indexPath)
        cell.textLabel?.text = displayTitleForProtocolType(protocolType)
        let currentProtocol = configuration?.protocolType ?? vpnClient.defaultProtocol
        if protocolType == currentProtocol {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }

    // MARK: - Conformance: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedProtocol = supportedProtocols[indexPath.row]
        Task {
            defer {
                tableView.deselectRow(at: indexPath, animated: true)
                tableView.reloadData()
            }
            let state = await vpnClient.state
            let existingConfig = await vpnClient.configuration
            guard existingConfig?.protocolType != selectedProtocol else {
                return
            }
            guard state == .disconnected else {
                presentAlert(title: "Invalid State", message: "Please disconnect from VPN first before updating protocol.")
                return
            }
            do {
                presentActivityAlert(message: "Updating protocol...")
                let updateInput = SudoVPNConfigurationUpdateInput(protocolType: .newValue(selectedProtocol))
                try await vpnClient.updateConfiguration(input: updateInput)
                dismissActivityAlert()
            } catch {
                dismissActivityAlert()
                presentAlert(title: "Failed to update protocol", message: error.localizedDescription)
            }
        }
    }

    // MARK: - Conformance: SudoVPNSubscriber

    func vpnConfigurationDidChange(_ configuration: SudoVPN.SudoVPNConfiguration?) {
        let existingConfiguration = self.configuration
        self.configuration = configuration
        if configuration?.protocolType != existingConfiguration?.protocolType {
            tableView.reloadData()
        }
    }
}
