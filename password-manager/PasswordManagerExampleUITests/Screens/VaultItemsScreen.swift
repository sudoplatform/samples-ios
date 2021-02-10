//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

enum VaultItemsScreen: String {
    case backToVaultsButton = "Vaults"
    case genPasswordButton = "Gen Password"
    case createNewVaultItemButton = "Create Vault Item"
    case newBankAccountButton = "Bank Account"
    case newCreditCardButton = "Credit Card"
    case newLoginButton = "Login"
    case notNowButton = "Not Now"

    var element: XCUIElement {
        switch self {
        case .backToVaultsButton, .genPasswordButton:
            return XCUIApplication().buttons[self.rawValue]
        case .createNewVaultItemButton:
            return XCUIApplication().tables.staticTexts[self.rawValue]
        case .newBankAccountButton, .newCreditCardButton, .newLoginButton, .notNowButton:
            let elementsQuery = XCUIApplication().sheets["Create Vault Item"].scrollViews.otherElements
            return elementsQuery.buttons[self.rawValue]
            
        }
    }

    static func goToCreateItem() {
        let backToVaultsButton: XCUIElement = VaultItemsScreen.backToVaultsButton.element
        let genPasswordButton: XCUIElement = VaultItemsScreen.genPasswordButton.element
        let createNewVaultItemButton: XCUIElement = VaultItemsScreen.createNewVaultItemButton.element

        XCTAssertTrue(backToVaultsButton.waitForExistence(timeout: Constants.timeout), "Cannot locate \(VaultItemsScreen.backToVaultsButton)")
        XCTAssertTrue(genPasswordButton.waitForExistence(timeout: Constants.timeout), "Cannot locate \(VaultItemsScreen.genPasswordButton)")
        XCTAssertTrue(createNewVaultItemButton.waitForExistence(timeout: Constants.timeout), "Cannot locate \(VaultItemsScreen.createNewVaultItemButton)")
        createNewVaultItemButton.tap()
    }
    
    static func selectVaultItemTypeToCreate(vaultItemType: String = "Login") {
        switch vaultItemType {
        case "BankAccount":
            let newBankAccountButton: XCUIElement = VaultItemsScreen.newBankAccountButton.element
            XCTAssertTrue(newBankAccountButton.waitForExistence(timeout: Constants.timeout), "Cannot locate \(VaultItemsScreen.newBankAccountButton)")
            newBankAccountButton.tap()
        case "NotNow":
            let notNowButton: XCUIElement = VaultItemsScreen.notNowButton.element
            XCTAssertTrue(notNowButton.waitForExistence(timeout: Constants.timeout), "Cannot locate \(VaultItemsScreen.notNowButton)")
            notNowButton.tap()
        case "CreditCard":
            let newCreditCardButton: XCUIElement = VaultItemsScreen.newCreditCardButton.element
            XCTAssert(newCreditCardButton.waitForExistence(timeout: Constants.timeout), "Cannot locate \(VaultItemsScreen.newCreditCardButton)")
            newCreditCardButton.tap()
        case "Login":
            let newLoginButton: XCUIElement = VaultItemsScreen.newLoginButton.element
            XCTAssert(newLoginButton.waitForExistence(timeout: Constants.timeout), "Cannot locate \(VaultItemsScreen.newLoginButton)")
            newLoginButton.tap()
        default:
            print("Please enter one of the supported vault item types: BankAccount, NotNow, CreditCard or Login")
        }
    }
    
}
