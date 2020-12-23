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

        RegisterLoginScreen.register()
        SetMasterPasswordScreen.setPassword(password: Constants.password)
        SudosScreen.createSudo()
        SudosScreen.goToVaultsScreen()
        VaultsScreen.createVault()
        VaultsScreen.goToLoginsScreen()
        LoginsScreen.goToCreateLogin()
        CreateLoginScreen.createLogin(title: "Anonyome", webAddress: "https://www.anonyome.com", username: "chip", password: "password")
        CreateLoginScreen.goBackToVaultsScreen()
        VaultsScreen.goBackToSudosScreen()
        SudosScreen.lockVaults()
        SetMasterPasswordScreen.deregister()
    }

}
