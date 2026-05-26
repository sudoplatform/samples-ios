//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoUser
import SudoVPN

/// This View Controller presents the options associated with profiles.
///
/// - Links From:
///     - `SettingsViewController`: A user requests to update profiles settings.
/// - Links To:
///     -  `SettingsViewController`: If a user taps the "back" button, the `SettingsViewController`will be presented.
@MainActor
class ProfilesViewController: UITableViewController, SudoVPNSubscriber {

    // MARK: - Outlets

    @IBOutlet weak var connectOnDemandSwitch: UISwitch!

    @IBOutlet weak var killSwitch: UISwitch!

    // MARK: - Properties

    var vpnClient = AppDelegate.dependencies.vpnClient

    let subscriberId = UUID().uuidString

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task {
            await vpnClient.subscribe(id: subscriberId, subscriber: self)
            await updateSwitchState()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        Task {
            await vpnClient.unsubscribe(id: subscriberId)
        }
    }

    // MARK: - Actions

    @IBAction func onSwitchValueChanged(_ switch: UISwitch) {
        Task {
            await updateOnDemand(killSwitch.isOn)
        }
   }

    @IBAction func killSwitchValueChanged(_ switch: UISwitch) {
        Task {
            await updateKillSwitch(connectOnDemandSwitch.isOn)
        }
   }

    // MARK: - Conformance: SudoVPNSubscriber

    func vpnConfigurationDidChange(_ configuration: SudoVPNConfiguration?) {
        Task {
            await updateSwitchState()
        }
    }

    // MARK: - Helpers

    func updateKillSwitch(_ isOn: Bool) async {
        do {
            presentActivityAlert(message: "Updating kill switch...")
            let updateInput = SudoVPNConfigurationUpdateInput(isKillSwitchEnabled: .newValue(isOn))
            try await vpnClient.updateConfiguration(input: updateInput)
            await dismissActivityAlert(animated: true)
        } catch {
            await updateSwitchState()
            await dismissActivityAlert(animated: true)
            presentAlert(title: "Error updating kill switch", message: error.localizedDescription)
        }
    }

    func updateOnDemand(_ isOn: Bool) async {
        do {
            presentActivityAlert(message: "Updating on demand...")
            let updateInput = SudoVPNConfigurationUpdateInput(onDemand: .newValue(isOn))
            try await vpnClient.updateConfiguration(input: updateInput)
            await dismissActivityAlert(animated: true)
        } catch {
            await updateSwitchState(animated: true)
            await dismissActivityAlert(animated: true)
            presentAlert(title: "Error updating on demand", message: error.localizedDescription)
        }
    }

    func updateSwitchState(animated: Bool = false) async {
        let configuration = await vpnClient.configuration
        let onDemand = configuration?.onDemand ?? false
        let isKillSwitchEnabled = configuration?.isKillSwitchEnabled ?? false
        if onDemand != connectOnDemandSwitch.isOn {
            connectOnDemandSwitch.setOn(onDemand, animated: animated)
        }
        if isKillSwitchEnabled != killSwitch.isOn {
            killSwitch.setOn(isKillSwitchEnabled, animated: animated)
        }
    }
}
