//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

enum CreateCreditCardScreen: String {
    case cancelButton = "Cancel"
    case saveButton = "Save"
    case creditCardNameTextField = "Enter a name for the credit card"
    case cardHolderTextField = "Card Holder"
    case cardTypeTextField = "VISA, Mastercard, etc."
    case cardNumberTextField = "4444 4444 4444 4444 4448"
    case cardExpiryTextField = "MM/YY"
    case cardSecurityCodeTextField = "Secret Code"

    var element: XCUIElement {
        switch self {
        case .cancelButton, .saveButton:
            return XCUIApplication().buttons[self.rawValue]
        case .creditCardNameTextField, .cardHolderTextField, .cardTypeTextField, .cardNumberTextField, .cardExpiryTextField, .cardSecurityCodeTextField:
            return XCUIApplication().textFields[self.rawValue]
        }
    }

    static func createCreditCard(name: String, cardHolder: String, cardType: String, cardNumber: String, cardExpiry: String, cardSecurityCode: String) {
        let saveButton: XCUIElement = CreateCreditCardScreen.saveButton.element
        let creditCardNameTextField: XCUIElement = CreateCreditCardScreen.creditCardNameTextField.element
        let cardHolderTextField: XCUIElement = CreateCreditCardScreen.cardHolderTextField.element
        let cardTypeTextField: XCUIElement = CreateCreditCardScreen.cardTypeTextField.element
        let cardNumberTextField: XCUIElement = CreateCreditCardScreen.cardNumberTextField.element
        let cardExpiryTextField: XCUIElement = CreateCreditCardScreen.cardExpiryTextField.element
        let cardSecurityCodeTextField: XCUIElement = CreateCreditCardScreen.cardSecurityCodeTextField.element
        let backToVaultsButton: XCUIElement = VaultItemsScreen.backToVaultsButton.element

        XCTAssertTrue(saveButton.waitForExistence(timeout: Constants.timeout), "Cannot locate \(CreateCreditCardScreen.saveButton)")
        XCTAssertTrue(creditCardNameTextField.waitForExistence(timeout: Constants.timeout), "Cannot locate \(CreateCreditCardScreen.creditCardNameTextField)")
        XCTAssertTrue(cardHolderTextField.waitForExistence(timeout: Constants.timeout), "Cannot locate \(CreateCreditCardScreen.cardHolderTextField)")
        XCTAssertTrue(cardTypeTextField.waitForExistence(timeout: Constants.timeout), "Cannot locate \(CreateCreditCardScreen.cardTypeTextField)")
        XCTAssertTrue(cardNumberTextField.waitForExistence(timeout: Constants.timeout), "Cannot locate \(CreateCreditCardScreen.cardNumberTextField)")
        XCTAssertTrue(cardExpiryTextField.waitForExistence(timeout: Constants.timeout), "Cannot locate \(CreateCreditCardScreen.cardExpiryTextField)")
        XCTAssertTrue(cardSecurityCodeTextField.waitForExistence(timeout: Constants.timeout), "Cannot locate \(CreateCreditCardScreen.cardSecurityCodeTextField)")

        creditCardNameTextField.tap()
        creditCardNameTextField.typeText(name)
        cardHolderTextField.tap()
        cardHolderTextField.typeText(cardHolder)
        cardTypeTextField.tap()
        cardTypeTextField.typeText(cardType)
        cardNumberTextField.tap()
        cardNumberTextField.typeText(cardNumber)
        cardExpiryTextField.tap()
        cardExpiryTextField.typeText(cardExpiry)
        cardSecurityCodeTextField.tap()
        cardSecurityCodeTextField.typeText(cardSecurityCode)
        saveButton.tap()
        XCTAssertTrue(backToVaultsButton.waitForExistence(timeout: Constants.timeout), "Cannot locate \(VaultItemsScreen.backToVaultsButton)")
    }

    static func goBackToVaultsScreen() {
        let goBackToVaultsScreen: XCUIElement = VaultItemsScreen.backToVaultsButton.element
        let goBackToSudosScreen: XCUIElement = VaultsScreen.backToSudosButton.element

        XCTAssertTrue(goBackToVaultsScreen.waitForExistence(timeout: Constants.timeout), "Cannot locate \(VaultItemsScreen.backToVaultsButton)")
        goBackToVaultsScreen.tap()
        XCTAssertTrue(goBackToSudosScreen.waitForExistence(timeout: Constants.timeout), "Cannot locate \(VaultsScreen.backToSudosButton)")

    }
}


