//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

enum RegisterLoginScreen: String {
    case registerLoginButton = "Register / Login"
    case resetButton = "Reset"
    case fssoPickerWheel = "Federated Sign In"

    var element: XCUIElement {
        switch self {
        case .registerLoginButton, .resetButton:
            return XCUIApplication().buttons[self.rawValue]
        case .fssoPickerWheel:
            return XCUIApplication().pickerWheels[self.rawValue]
        }
    }

    static func register() {
        let registerButton: XCUIElement = self.registerLoginButton.element
        let resetButton: XCUIElement = self.resetButton.element
        let deregisterButton: XCUIElement = SetMasterPasswordScreen.deregisterButton.element
        let fssoPickerWheel: XCUIElement = self.fssoPickerWheel.element

        if deregisterButton.waitForExistence(timeout: Constants.shortTimeout) {
            SetMasterPasswordScreen.deregister()
        }

        if fssoPickerWheel.waitForExistence(timeout: Constants.shortTimeout) {
            fssoPickerWheel.adjust(toPickerWheelValue: "TEST Registration")
        }
        
        XCTAssertTrue(registerButton.waitForExistence(timeout: Constants.timeout), "Unable to locate \(RegisterLoginScreen.registerLoginButton)")
        XCTAssertTrue(resetButton.waitForExistence(timeout: Constants.timeout), "Unable to locate \(RegisterLoginScreen.resetButton)")
        registerButton.tap()
        XCTAssertTrue(deregisterButton.waitForExistence(timeout: Constants.timeout), "Unable to locate \(SetMasterPasswordScreen.deregisterButton)")
    }
}
