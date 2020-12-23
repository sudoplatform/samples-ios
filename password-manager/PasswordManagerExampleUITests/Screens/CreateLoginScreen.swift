//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

enum CreateLoginScreen: String {
    case cancelButton = "Cancel"
    case saveButton = "Save"
    case loginTitleTextField = "Enter name or title of the website"
    case webAddressTextField = "Enter the URL of the website login"
    case usernameTextField = "Enter the username you use to sign in"
    case passwordTextField = "Enter or create a password"

    var element: XCUIElement {
        switch self {
        case .cancelButton, .saveButton:
            return XCUIApplication().buttons[self.rawValue]
        case .loginTitleTextField, .webAddressTextField, .usernameTextField, .passwordTextField:
            return XCUIApplication().textFields[self.rawValue]
        }
    }

    static func createLogin(title: String, webAddress: String, username: String, password: String) {
        let saveButton: XCUIElement = CreateLoginScreen.saveButton.element
        let loginTitleTextField: XCUIElement = CreateLoginScreen.loginTitleTextField.element
        let webAddressTextField: XCUIElement = CreateLoginScreen.webAddressTextField.element
        let usernameTextField: XCUIElement = CreateLoginScreen.usernameTextField.element
        let passwordTextField: XCUIElement = CreateLoginScreen.passwordTextField.element
        let backToVaultsButton: XCUIElement = LoginsScreen.backToVaultsButton.element

        XCTAssertTrue(saveButton.waitForExistence(timeout: Constants.timeout), "Cannot locate \(CreateLoginScreen.saveButton)")
        XCTAssertTrue(loginTitleTextField.waitForExistence(timeout: Constants.timeout), "Cannot locate \(CreateLoginScreen.loginTitleTextField)")
        XCTAssertTrue(webAddressTextField.waitForExistence(timeout: Constants.timeout), "Cannot locate \(CreateLoginScreen.webAddressTextField)")
        XCTAssertTrue(usernameTextField.waitForExistence(timeout: Constants.timeout), "Cannot locate \(CreateLoginScreen.usernameTextField)")
        XCTAssertTrue(passwordTextField.waitForExistence(timeout: Constants.timeout), "Cannot locate \(CreateLoginScreen.passwordTextField)")

        loginTitleTextField.tap()
        loginTitleTextField.typeText(title)
        webAddressTextField.tap()
        webAddressTextField.typeText(webAddress)
        usernameTextField.tap()
        usernameTextField.typeText(username)
        passwordTextField.tap()
        passwordTextField.typeText(password)
        saveButton.tap()
        XCTAssertTrue(backToVaultsButton.waitForExistence(timeout: Constants.timeout), "Cannot locate \(LoginsScreen.backToVaultsButton)")
    }

    static func goBackToVaultsScreen() {
        let goBackToVaultsScreen: XCUIElement = LoginsScreen.backToVaultsButton.element
        let goBackToSudosScreen: XCUIElement = VaultsScreen.backToSudosButton.element

        XCTAssertTrue(goBackToVaultsScreen.waitForExistence(timeout: Constants.timeout), "Cannot locate \(LoginsScreen.backToVaultsButton)")
        goBackToVaultsScreen.tap()
        XCTAssertTrue(goBackToSudosScreen.waitForExistence(timeout: Constants.timeout), "Cannot locate \(VaultsScreen.backToSudosButton)")

    }
}
