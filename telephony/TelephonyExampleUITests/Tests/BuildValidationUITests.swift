//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

class BuildValidationUITests: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    override func tearDownWithError() throws {
    }
    
    func testSmokeTest() {
        LoginScreen.register()
        CreateSudoScreen.createSudo(sudoName: Constants.SudoName)
        SudoDetailsScreen.provisionPhoneNumber()
        SudoScreen.deregister()
        
    }
}
