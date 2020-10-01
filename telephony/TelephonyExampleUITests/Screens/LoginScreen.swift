//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

enum LoginScreen: String {
    // registerLoginButton has an accessibility identifier set
    case registerLoginButton = "registerLoginButtonIdentifier"
    case telephonyStaticText = "Telephony"
    
    var element: XCUIElement {
        switch self {
        case .registerLoginButton:
            return XCUIApplication().buttons[self.rawValue]
        case .telephonyStaticText:
            return XCUIApplication().staticTexts[self.rawValue]
        }
    }
    
    static func register() {
        let registerButton: XCUIElement
        let deregisterButton: XCUIElement
        
        deregisterButton = SudoScreen.deregisterButton.element
        registerButton = LoginScreen.registerLoginButton.element
        
        if deregisterButton.exists {
            SudoScreen.deregister()
        }
        
        XCTAssert(registerButton.waitForExistence(timeout: Constants.TimeOut), "Cannot locate Register Button")
        registerButton.tap()
        XCTAssert(deregisterButton.waitForExistence(timeout: Constants.TimeOut), "Cannot locate Deregister Button")
    }
    
}
