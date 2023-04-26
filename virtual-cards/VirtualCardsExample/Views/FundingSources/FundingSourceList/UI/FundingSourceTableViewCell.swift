//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import UIKit
import SudoVirtualCards

class FundingSourceTableViewCell: UITableViewCell {

    // MARK: - Outlets

    @IBOutlet var networkImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var subtitleLabel: UILabel!

    // MARK: - Supplementary

    /// Name of the class.
    static var name = "FundingSourceTableViewCell"

    // MARK: - Methods

    /// Formats the image view,  title and subtitle which represents a funding source and is displayed on the table view cell.
    ///
    /// - Parameter fundingSource: The funding source to display.
    func setFundingSource(_ fundingSource: FundingSource) {
        switch fundingSource {
        case .creditCardFundingSource(let creditCardFundingSource):
            let suffix = (creditCardFundingSource.state == .inactive) ? " - Cancelled" : ""
            let cardNetwork = creditCardFundingSource.network.string.capitalized
            titleLabel.text = "Card: \(cardNetwork)\(suffix)"
            subtitleLabel.text = "••••\(creditCardFundingSource.last4) (\(creditCardFundingSource.cardType))"
        case .bankAccountFundingSource(let bankAccountFundingSource):
            let suffix = (bankAccountFundingSource.state == .inactive) ? " - Cancelled" : ""
            let institutionName = bankAccountFundingSource.institutionName
            titleLabel.text = "Bank Account: \(institutionName)\(suffix)"
            subtitleLabel.text = "••••\(bankAccountFundingSource.last4) (\(bankAccountFundingSource.bankAccountType))"
        }
    }
}
