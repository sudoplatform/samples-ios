//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoEmail

/// This TableView Cell presents as blocked email address
class BlockedAddressTableViewCell: UITableViewCell {
    
    // MARK: - Outlets
    
    @IBOutlet var addressLabel: UILabel!
    
    // MARK: - Properties
    
    var emailAddress: String? {
        didSet {
            addressLabel.text = emailAddress
        }
    }
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        addressLabel.text = nil
    }
}
