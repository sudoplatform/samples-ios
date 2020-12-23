//
//  EntitlementCell.swift
//  PasswordManagerExample
//
//  Created by Buster Townsend on 10/9/20.
//  Copyright © 2020 Sudo Platform. All rights reserved.
//

import UIKit
import SudoPasswordManager

class EntitlementCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var limitLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    
    func setEntitlement(_ entitlement: EntitlementState) {
        nameLabel.text = entitlement.name.rawValue
        limitLabel.text = String(entitlement.limit)
        valueLabel.text = String(entitlement.value)
    }
}
