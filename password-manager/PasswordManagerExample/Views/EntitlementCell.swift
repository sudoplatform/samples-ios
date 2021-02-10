//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoPasswordManager

class EntitlementCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var limitLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    
    func setEntitlement(_ entitlement: EntitlementState) {
        nameLabel.text = setName(entitlement.name)
        limitLabel.text = String(entitlement.limit)
        valueLabel.text = String(entitlement.value)
    }

    func setName(_ name: Entitlement.Name) -> String {
        switch name {
        case .maxVaultPerSudo:
            return "\(Entitlement.Name.maxVaultPerSudo)"
        }
    }
}
