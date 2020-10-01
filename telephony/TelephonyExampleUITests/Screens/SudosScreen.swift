//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

enum SudoScreen: String {
    case deregisterButton = "Deregister"
    case createSudoButton = "Create Sudo"
    case sudosLabel = "Sudos"
    case uiTestSudoDeatilsButton = "Sudo_UITest"
    
    var element: XCUIElement {
        switch self {
        case .deregisterButton:
            return XCUIApplication().buttons[self.rawValue]
        case .createSudoButton:
            return XCUIApplication().staticTexts[self.rawValue]
        case .sudosLabel:
            return XCUIApplication().staticTexts[self.rawValue]
        case .uiTestSudoDeatilsButton:
            return XCUIApplication().staticTexts[self.rawValue]
        }
    }
    
    static func deregister() {
        let registerButton: XCUIElement
        let deregisterButton: XCUIElement
        let deregisterAlertButton: XCUIElement
        
        deregisterButton = SudoScreen.deregisterButton.element
        XCTAssert(deregisterButton.waitForExistence(timeout: Constants.TimeOut), "Cannot locate Deregister Button")
        deregisterButton.tap()
        
        deregisterAlertButton = DeregisterAlert.deregisterButton.element
        XCTAssert(deregisterAlertButton.waitForExistence(timeout: Constants.TimeOut), "Cannot locate Dergister Alert Button")
        deregisterAlertButton.tap()
        
        registerButton = LoginScreen.registerLoginButton.element
        XCTAssert(registerButton.waitForExistence(timeout: Constants.TimeOut), "Cannot locate Register Button")
    }
    
}
