//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

enum SetMasterPasswordScreen: String {
    case deregisterButton = "Deregister"
    case saveButton = "Save"
    case passwordTextBox = "Enter a Master Password"
    case confirmPasswordTextBox = "Confirm Password"

    var element: XCUIElement {
        switch self {
        case .deregisterButton, .saveButton:
            return XCUIApplication().buttons[self.rawValue]
        case .passwordTextBox, .confirmPasswordTextBox:
            return XCUIApplication().secureTextFields[self.rawValue]
        }
    }
    
    static func setPassword(password: String) {
        let app = XCUIApplication()
        let passwordTextField: XCUIElement = self.passwordTextBox.element
        let confirmPasswordTextField: XCUIElement = self.confirmPasswordTextBox.element
        let saveButton: XCUIElement = self.saveButton.element

        XCTAssertTrue(passwordTextField.waitForExistence(timeout: Constants.timeout), "Cannot locate \(SetMasterPasswordScreen.passwordTextBox)")
        passwordTextField.tap()
        passwordTextField.typeText(password)
        XCTAssertTrue(confirmPasswordTextField.waitForExistence(timeout: Constants.timeout), "Cannot locate \(SetMasterPasswordScreen.confirmPasswordTextBox)")
        confirmPasswordTextField.tap()
        confirmPasswordTextField.typeText(password)
        XCTAssertTrue(saveButton.waitForExistence(timeout: Constants.timeout), "Cannot locate \(SetMasterPasswordScreen.saveButton)")
        saveButton.tap()
        app.alerts["Your Secret Code & Rescue Kit"].scrollViews.otherElements.buttons["Not now"].waitForExistence(timeout: Constants.timeout)
        app.alerts["Your Secret Code & Rescue Kit"].scrollViews.otherElements.buttons["Not now"].tap()
    }

    static func deregister() {
        let app = XCUIApplication()
        let deregisterButton: XCUIElement = self.deregisterButton.element
        let registerLoginButton: XCUIElement = RegisterLoginScreen.registerLoginButton.element

        XCTAssertTrue(deregisterButton.waitForExistence(timeout: Constants.timeout), "Cannot locate \(SetMasterPasswordScreen.deregisterButton)")
        deregisterButton.tap()
        XCTAssertTrue(app.alerts["Are you sure?"].scrollViews.otherElements.buttons["Not now"].waitForExistence(timeout: Constants.timeout), "Cannot locate alert")
        app.alerts["Are you sure?"].scrollViews.otherElements.buttons["Not now"].tap()
        deregisterButton.tap()
        XCTAssertTrue(app.alerts["Are you sure?"].scrollViews.otherElements.buttons["Reset"].waitForExistence(timeout: Constants.timeout), "Cannot locate alert")
        app.alerts["Are you sure?"].scrollViews.otherElements.buttons["Reset"].tap()
        XCTAssertTrue(registerLoginButton.waitForExistence(timeout: Constants.timeout), "Cannot locate \(RegisterLoginScreen.registerLoginButton)")

    }
}
