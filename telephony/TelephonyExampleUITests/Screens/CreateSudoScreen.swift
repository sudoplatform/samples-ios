//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

enum CreateSudoScreen: String {
    case backToSudosScreenButton = "Sudos"
    case sudoLabelTextField = "Enter Sudo Label"
    case createButton = "Create"
    
    var element: XCUIElement {
        switch self {
        case .backToSudosScreenButton:
            return XCUIApplication().buttons[self.rawValue]
        case .sudoLabelTextField:
            return XCUIApplication().textFields[self.rawValue]
        case .createButton:
            return XCUIApplication().buttons[self.rawValue]
        }
    }
    
    static func createSudo(sudoName: String) {
        
        let createSudoButton: XCUIElement
        let sudoLabel: XCUIElement
        let createButton: XCUIElement
        
        createSudoButton = SudoScreen.createSudoButton.element
        XCTAssert(createSudoButton.waitForExistence(timeout: Constants.TimeOut), "Cannot locate Create Sudo Button")
        createSudoButton.tap()
        
        sudoLabel = CreateSudoScreen.sudoLabelTextField.element
        XCTAssert(sudoLabel.waitForExistence(timeout: Constants.TimeOut), "Cannot locate Sudo Label Text Field")
        sudoLabel.tap()
        sudoLabel.typeText(sudoName)
        
        createButton = CreateSudoScreen.createButton.element
        XCTAssert(createButton.waitForExistence(timeout: Constants.TimeOut), "Cannot locate Create Button")
        createButton.tap()
    }
}
