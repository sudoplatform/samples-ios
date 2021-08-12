//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoVPN

class ProtocolsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SudoVPNObserving {

    // MARK: - Outlets

    /// Table view that lists the menu items.
    @IBOutlet var tableView: UITableView!

    // MARK: - Properties

    var vpnClient = AppDelegate.dependencies.vpnClient

    var supportedProtocols: [SudoVPNProtocol] = []

    var currentProtocol: SudoVPNProtocol {
        get {

            guard
                let data = UserDefaults.standard.data(forKey: "currentProtocol"),
                let userSetting = try? JSONDecoder().decode(SudoVPNProtocol.self, from: data)
            else {
                return vpnClient.defaultProtocol
            }
            return userSetting
        }
        set {
            guard let encodedData = try? JSONEncoder().encode(newValue) else {
                NSLog("Failed to set default protocol")
                return
            }
            UserDefaults.standard.setValue(encodedData, forKey: "currentProtocol")
        }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        let protocols = vpnClient.supportedProtocols().filter({
            if case .unknown = $0 {
                return false
            }
            return true
        })
        supportedProtocols = protocols
        configureTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        vpnClient.addObserver(self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        vpnClient.removeObserver(self)
    }

    // MARK: - Helpers

    func displayTitleForProtocolType(_ protocolType: SudoVPNProtocol) -> String {
        switch protocolType {
        case .l2tp:
            return "Layer 2 Tunneling Protocol (L2TP)"
        case .pptp:
            return "Point-To-Point Tunneling Protocol (PPTP)"
        case .ipsec:
            return "Internet Protocol Security (IPSEC)"
        case .ikev2:
            return "Internet Key Exchange V2 (IKEv2)"
        case .openVpnUdp:
            return "Open VPN over UDP"
        case .openVpnTcp:
            return "Open VPN over TCP"
        case .wireGuard:
            return "WireGuard"
        case .unknown(let string):
            return "Unknown: \(String(describing: string))"
        }
    }

    // MARK: - Helpers: Configuration

    /// Configures the table view.
    func configureTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "default")
        tableView.tableFooterView = UIView()
    }

    // MARK: - Conformance: UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return vpnClient.supportedProtocols().count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let protocolType = supportedProtocols[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "default", for: indexPath)
        cell.textLabel?.text = displayTitleForProtocolType(protocolType)
        if protocolType == currentProtocol {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }

    // MARK: - Conformance: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 0 else {
            return
        }
        let selectedProtocol = supportedProtocols[indexPath.row]
        currentProtocol = selectedProtocol
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.reloadData()
    }

    // MARK: - Conformance: SudoVPNObserving

    func protocolDidChange(_ protocolType: SudoVPNProtocol) {
        currentProtocol = protocolType
        tableView.reloadData()
    }

}
