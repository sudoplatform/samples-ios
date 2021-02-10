//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// These tests require the TEST registration. FSSO is not supported.

import XCTest

class BuildValidationUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    func testSmokeTests() {
        let app = XCUIApplication()
        app.launch()

        // Register, create a Sudo, create a vault
        RegisterLoginScreen.register()
        SetMasterPasswordScreen.setPassword(password: Constants.password)
        SudosScreen.createSudo()
        SudosScreen.goToVaultsScreen()
        VaultsScreen.createVault()
        VaultsScreen.goToLoginsScreen()
        
        // Create a Login
        VaultItemsScreen.goToCreateItem()
        VaultItemsScreen.selectVaultItemTypeToCreate(vaultItemType: "Login")
        CreateLoginScreen.createLogin(title: "Anonyome Login", webAddress: "https://www.anonyome.com", username: "chip", password: "p@$$w0rd")
        
        // Create a bank account
        VaultItemsScreen.goToCreateItem()
        VaultItemsScreen.selectVaultItemTypeToCreate(vaultItemType: "BankAccount")
        CreateBankAccountScreen.createBankAccount(name: "Acme Bank Account", bankName: "Acme Bank", accountNumber: "123456789", routingNumber: "0909090909", accountType: "Checking")
        
        // Create a credit card
        VaultItemsScreen.goToCreateItem()
        VaultItemsScreen.selectVaultItemTypeToCreate(vaultItemType: "CreditCard")
        CreateCreditCardScreen.createCreditCard(name: "AMEX Credit Card", cardHolder: "Joe Schmoe", cardType: "AMEX", cardNumber: "1234 567890 12345", cardExpiry: "01/22", cardSecurityCode: "1234")
        
        // Lock and deregister
        CreateLoginScreen.goBackToVaultsScreen()
        VaultsScreen.goBackToSudosScreen()
        SudosScreen.lockVaults()
        SetMasterPasswordScreen.deregister()
        
    }
    
    

}
