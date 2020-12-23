//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

enum LoginsScreen: String {
    case backToVaultsButton = "Vaults"
    case genPasswordButton = "Gen Password"
    case createLoginButton = "Create Login"

    var element: XCUIElement {
        switch self {
        case .backToVaultsButton, .genPasswordButton:
            return XCUIApplication().buttons[self.rawValue]
        case .createLoginButton:
            return XCUIApplication().tables.staticTexts[self.rawValue]
        }
    }

    static func goToCreateLogin() {
        let backToVaultsButton: XCUIElement = LoginsScreen.backToVaultsButton.element
        let genPasswordButton: XCUIElement = LoginsScreen.genPasswordButton.element
        let createLoginButton: XCUIElement = LoginsScreen.createLoginButton.element

        XCTAssertTrue(backToVaultsButton.waitForExistence(timeout: Constants.timeout), "Cannot locate \(LoginsScreen.backToVaultsButton)")
        XCTAssertTrue(genPasswordButton.waitForExistence(timeout: Constants.timeout), "Cannot locate \(LoginsScreen.genPasswordButton)")
        XCTAssertTrue(createLoginButton.waitForExistence(timeout: Constants.timeout), "Cannot locate \(LoginsScreen.createLoginButton)")
        createLoginButton.tap()
        XCTAssertTrue(XCUIApplication().staticTexts["Create Login"].waitForExistence(timeout: Constants.timeout), "Cannot locate Create Login text")

    }
}
