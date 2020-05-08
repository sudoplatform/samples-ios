//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit

/// `UIView` subclass that houses the stylised  virtual card and it's information
class CardView: UIView {

    // MARK: - Outlets

    /// The background view holding the stylised card shape
    @IBOutlet var backgroundImageView: UIImageView!

    /// The sudo branding icon on the top left of the card
    @IBOutlet var sudoIconImageView: UIImageView!

    /// Required card type logo that sits to the right of the account number
    @IBOutlet var debitMarkImageView: UIImageView!

    /// The label in the top right of the card
    @IBOutlet var headerDetailLabel: UILabel!

    /// The card name label. This sits above all details next to the sudo icon
    @IBOutlet var nameLabel: UILabel!

    /// The name of the sudo who owns the card. This sits below the main card information
    @IBOutlet var cardholderNameLabel: UILabel!

    /// Footer text label that sits at the bottom of the card. This will hold any legal disclaimers and other required info
    @IBOutlet var footerLabel: UILabel!

    /// The image view that will display the card network/provider
    @IBOutlet var cardNetworkImageView: UIImageView!

    /// The title label for the card/account number detail. This sits above the relative value label
    @IBOutlet var accountNumberTitleLabel: UILabel!

    /// The value label for the card/account number detail. This displays the actual number value.
    @IBOutlet var accountNumberValueLabel: UILabel!

    /// Stack view holding the security code and expriation detail views. These are within a stack view as the layout
    /// may need to change based on accessibility updates
    @IBOutlet var securityAndExpirationHolder: UIStackView!

    /// The title label for the cvc/security code detail. This sits above the relative value label
    @IBOutlet var securityCodeTitleLabel: UILabel!

    /// The value label for the cvc/security code detail. This displays the actual CVC code.
    @IBOutlet var securityCodeValueLabel: UILabel!

    /// The title label for the expiration/valid thru detail. This sits above the relative value label
    @IBOutlet var expirationTitleLabel: UILabel!

    /// The value label for the expiration/valid thru detail. This displays the actual expiration value.
    @IBOutlet var expirationValueLabel: UILabel!

    /// The stylised badge displayed the card is in the non-standard state
    @IBOutlet var statusImageView: UIImageView!

    // MARK: - Properties:

    /// The card detail information model. Updating these will update their respective display elements
    var viewModel: CardViewModel = CardViewModel.empty {
        didSet {
            reloadData()
        }
    }

    /// The radius to apply to the main, front, and back view containers
    let cornerRadius: CGFloat = 12

    // MARK: - Lifecycle

    override func awakeAfter(using aDecoder: NSCoder) -> Any? {
        if subviews.isEmpty {
            let view: CardView = .fromNib()
            view.backgroundColor = backgroundColor
            view.frame = frame
            view.translatesAutoresizingMaskIntoConstraints = false
            return view
        }
        return super.awakeAfter(using: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setupCardShape()
        assignDefaultTitles()
        reloadData()
    }

    // MARK: - Helpers

    func assignDefaultTitles() {
        accountNumberTitleLabel.text = "Account Number"
        securityCodeTitleLabel.text = "CVC"
        expirationTitleLabel.text = "Expiry"
    }

    func setupCardShape() {
        clipsToBounds = true
        layer.cornerRadius = cornerRadius
    }

    func reloadData() {
        cardNetworkImageView.image = viewModel.cardNetwork.brandingIcon
        // Titles
        footerLabel.text = viewModel.footer
        // General
        headerDetailLabel.text = viewModel.headerTitle
        nameLabel.text = viewModel.cardName
        cardholderNameLabel.text = viewModel.cardholderName
        expirationValueLabel.text = viewModel.formattedExpiration
        securityCodeValueLabel.text = viewModel.securityCode
        accountNumberValueLabel.text = viewModel.cardNumber
        // State tag/badge image
        statusImageView.image = viewModel.cardStatus.tagImage
        statusImageView.isHidden = (statusImageView.image == nil)
    }
}
