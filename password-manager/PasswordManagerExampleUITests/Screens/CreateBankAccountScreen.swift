//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

enum CreateBankAccountScreen: String {
    case cancelButton = "Cancel"
    case saveButton = "Save"
    case bankAccountNameTextField = "Enter a name for the Bank Account"
    case bankNameTextField = "Name of the bank this account belongs to"
    case accountNumberTextField = "Bank account number"
    case routingNumberTextField = "Routing number for holding bank"
    case accountTypeTextField = "Checking, Savings, etc."

    var element: XCUIElement {
        switch self {
        case .cancelButton, .saveButton:
            return XCUIApplication().buttons[self.rawValue]
        case .bankAccountNameTextField, .bankNameTextField, .accountNumberTextField, .routingNumberTextField, .accountTypeTextField:
            return XCUIApplication().textFields[self.rawValue]
        }
    }

    static func createBankAccount(name: String, bankName: String, accountNumber: String, routingNumber: String, accountType: String) {
        let saveButton: XCUIElement = CreateBankAccountScreen.saveButton.element
        let bankAccountNameTextField: XCUIElement = CreateBankAccountScreen.bankAccountNameTextField.element
        let bankNameTextField: XCUIElement = CreateBankAccountScreen.bankNameTextField.element
        let accountNumberTextField: XCUIElement = CreateBankAccountScreen.accountNumberTextField.element
        let routingNumberTextField: XCUIElement = CreateBankAccountScreen.routingNumberTextField.element
        let accountTypeTextField: XCUIElement = CreateBankAccountScreen.accountTypeTextField.element
        let backToVaultsButton: XCUIElement = VaultItemsScreen.backToVaultsButton.element

        XCTAssertTrue(saveButton.waitForExistence(timeout: Constants.timeout), "Cannot locate \(CreateBankAccountScreen.saveButton)")
        XCTAssertTrue(bankAccountNameTextField.waitForExistence(timeout: Constants.timeout), "Cannot locate \(CreateBankAccountScreen.bankAccountNameTextField)")
        XCTAssertTrue(bankNameTextField.waitForExistence(timeout: Constants.timeout), "Cannot locate \(CreateBankAccountScreen.bankNameTextField)")
        XCTAssertTrue(accountNumberTextField.waitForExistence(timeout: Constants.timeout), "Cannot locate \(CreateBankAccountScreen.accountNumberTextField)")
        XCTAssertTrue(routingNumberTextField.waitForExistence(timeout: Constants.timeout), "Cannot locate \(CreateBankAccountScreen.routingNumberTextField)")
        XCTAssertTrue(accountTypeTextField.waitForExistence(timeout: Constants.timeout), "Cannot locate \(CreateBankAccountScreen.accountTypeTextField)")

        bankAccountNameTextField.tap()
        bankAccountNameTextField.typeText(name)
        bankNameTextField.tap()
        bankNameTextField.typeText(bankName)
        accountNumberTextField.tap()
        accountNumberTextField.typeText(accountNumber)
        routingNumberTextField.tap()
        routingNumberTextField.typeText(routingNumber)
        accountTypeTextField.tap()
        accountTypeTextField.typeText(accountType)
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

