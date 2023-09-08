//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoUser

/// This View Controller presents the options associated with profiles.
///
/// - Links From:
///     - `SettingsViewController`: A user requests to update profiles settings.
/// - Links To:
///     -  `SettingsViewController`: If a user taps the "back" button, the `SettingsViewController`will be presented.
class ProfilesViewController: UITableViewController {

    // MARK: - Outlets
    @IBOutlet weak var connectOnDemandSwitch: UISwitch!
    // MARK: - Supplementary

    // MARK: - Properties

    var currentOnDemandSetting: Bool {
        get {
            guard
                let data = UserDefaults.standard.data(forKey: "currentOnDemand"),
                let userSetting = try? JSONDecoder().decode(Bool.self, from: data)
            else {
                return false
            }
            return userSetting
        }
        set {
            guard let encodedData = try? JSONEncoder().encode(newValue) else {
                NSLog("Failed to set on demand flag")
                return
            }
            UserDefaults.standard.setValue(encodedData, forKey: "currentOnDemand")
        }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        connectOnDemandSwitch.setOn(currentOnDemandSetting, animated: false)
    }

    // MARK: - View

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        /// Automatic cell height.
         return UITableView.automaticDimension
    }

    // MARK: - Actions

    @IBAction func onSwitchValueChanged(_ switch: UISwitch) {
        currentOnDemandSetting = connectOnDemandSwitch.isOn
   }

}
