//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit

/// Protocol to assign for a delegate of `LearnMoreView`.
///
/// This is used to receive learn more button tap events.
protocol LearnMoreViewDelegate: class {

    /// Called when the learn more button is tapped.
    func didTapLearnMoreButton()
}

/// View that houses information for a Learn More view shown at the bottom of sample app views.
class LearnMoreView: UIView {

    // MARK: - Outlets

    /// Label that shows information related to learning more.
    @IBOutlet var label: UILabel!

    /// Button that typically launches a web page for learning more about a feature.
    @IBOutlet var learnMoreButton: UIButton!

    /// Delegate used to notify learn more button taps.
    weak var delegate: LearnMoreViewDelegate?

    // MARK: - Lifecycle

    override func awakeAfter(using aDecoder: NSCoder) -> Any? {
        if subviews.isEmpty {
            let view: LearnMoreView = .fromNib()
            view.backgroundColor = backgroundColor
            view.frame = frame
            view.translatesAutoresizingMaskIntoConstraints = false
            return view
        }
        return super.awakeAfter(using: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .none
        label.text = nil
    }

    // MARK: - Actions

    /// Action associated with the `didTouchUpInside` of the `learnMore` button.
    ///
    /// Notifes the delegate that the button was tapped.
    @IBAction func didTapLearnMoreButton() {
        delegate?.didTapLearnMoreButton()
    }

}
