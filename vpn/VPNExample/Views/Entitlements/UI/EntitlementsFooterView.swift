//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit

/// Protocol to assign for a delegate of `EntitlementsFooterView`.
///
/// This is used to receive learn more button tap events.
protocol EntitlementsFooterViewDelegate: AnyObject {

    /// Called when the learn more button is tapped.
    func didTapLearnMoreButton()
}

class EntitlementsFooterView: UITableViewHeaderFooterView {

    // MARK: - Outlets

    @IBOutlet var moreInfoLabel: UILabel!

    // MARK: - Properties

    weak var delegate: EntitlementsFooterViewDelegate?

    // MARK: - Lifecycle

    @IBAction func learnMoreButtonTapped(_ sender: Any) {
        delegate?.didTapLearnMoreButton()
    }
}
