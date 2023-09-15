//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoVPN
import SudoEntitlements

protocol EntitlementsTableViewCellDelegate: AnyObject {

    /// Called when the toggle entitlements button is tapped.
    func didTapToggleEntitlementsButton(_ entitlementName: String, _ currentlyEntitled: Bool)
}

class EntitlementsTableViewCell: UITableViewCell {

    var currentlyEntitled: Bool = false
    var entitlementName: String = ""

    weak var delegate: EntitlementsTableViewCellDelegate?

    // MARK: - Outlets

    @IBOutlet var entitlementLabel: UILabel!
    @IBOutlet var limitLabel: UILabel!
    @IBOutlet var usedLabel: UILabel!
    @IBOutlet var availableLabel: UILabel!

    @IBOutlet var toggleEntitlementsButton: UIButton!
    // MARK: - Operations

    func setConsumption(_ model: EntitlementConsumptionModel) {
        currentlyEntitled = model.value > 0
        entitlementName = model.name

        entitlementLabel.text = "Entitlement: \(model.name)"
        limitLabel.text = "Limit: \(model.value)"
        usedLabel.text = "Used: \(model.consumed)"
        availableLabel.text = "Available: \(model.available)"
    }

    // MARK: - Actions
    @IBAction func didTapToggleEntitlementsButton(_ sender: Any) {
        delegate?.didTapToggleEntitlementsButton(self.entitlementName, self.currentlyEntitled)
    }
}
