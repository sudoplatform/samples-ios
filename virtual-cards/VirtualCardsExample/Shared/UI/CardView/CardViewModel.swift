//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Basic struct holding the details that can be displayed on a `CardView`
struct CardViewModel: Equatable {

    /// The display value for the text at the top right of the card.
    let headerTitle: String = "Mastercard® Virtual Card"

    /// The display name for the card. i.e: "Online Shopping"
    let cardName: String

    /// The card network provider. This will alter what branding logo is displayed on the card. This is always `.mastercard` at the moment.
    let cardNetwork: CardNetwork = .mastercard

    /// The current status of the card. When not in the `.open` state, a stylised label will be shown on the card.
    let cardStatus: CardStatus

    /// The full name for the cardholder. i.e: "John Smith"
    let cardholderName: String

    /// The display value for the card number.
    let cardNumber: String

    /// The display value for the expiration date.
    let expiration: String

    /// The display value for the CVC/Security code.
    let securityCode: String

    /// Required footer text to display at the bottom of the card.
    let footer: String = "Powered by Sudo Platform"

    /// Whether the card details should be copied when tapped. Defaults to `true`.
    var isCopyCardDetailsOnTapEnabled: Bool = true

    /// Whether the card details will be copied when long pressed. Defaults to `true`.
    var isCopyCardDetailsOnLongPressEnabled: Bool = true

    var formattedExpiration: String {
        guard expiration.contains("/") else { return expiration }
        let components = expiration.components(separatedBy: "/")
        var month = components[0]
        if month.count == 1 {
            month = "0\(month)"
        }
        let year = components[1]
        let yearSubstring = String(year.suffix(2))
        return "\(month)/\(yearSubstring)"
    }

    /// Will return a copy of the current card number value with any non-digit characters removed
    var rawCardNumber: String {
        return cardNumber.filter { $0.isNumber }
    }

    // MARK: - Lifecycle

    /// Will return a model with any required strings empty
    static var empty: CardViewModel {
        return CardViewModel(
            cardName: "Card Name",
            cardStatus: .issued,
            cardholderName: "Card Holder",
            cardNumber: "",
            expiration: "",
            securityCode: "",
            isCopyCardDetailsOnTapEnabled: true,
            isCopyCardDetailsOnLongPressEnabled: true
        )
    }
}
