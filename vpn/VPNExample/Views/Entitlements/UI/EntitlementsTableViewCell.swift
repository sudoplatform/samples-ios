//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoVPN
import SudoEntitlements

class EntitlementsTableViewCell: UITableViewCell {

    // MARK: - Outlets

    @IBOutlet var entitlementLabel: UILabel!
    @IBOutlet var limitLabel: UILabel!
    @IBOutlet var usedLabel: UILabel!
    @IBOutlet var availableLabel: UILabel!

    // MARK: - Operations

    func setConsumption(_ model: EntitlementConsumptionModel) {
        entitlementLabel.text = "Entitlement: \(model.name)"
        limitLabel.text = "Limit: \(model.value)"
        usedLabel.text = "Used: \(model.consumed)"
        availableLabel.text = "Available: \(model.available)"
    }
}
