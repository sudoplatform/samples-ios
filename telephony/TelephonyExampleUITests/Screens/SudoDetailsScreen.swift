//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

enum SudoDetailsScreen: String {
    case provisionPhoneNumberButton = "Provision Phone Number"
    case backToSudosScreenButton = "Sudos"
    
    var element: XCUIElement {
        switch self {
        case .provisionPhoneNumberButton:
            return XCUIApplication().staticTexts[self.rawValue]
        case .backToSudosScreenButton:
            return XCUIApplication().navigationBars[Constants.SudoName].buttons[self.rawValue]
        }
    }
    
    static func provisionPhoneNumber() {
        let sudoDetailsCell: XCUIElement
        let provisionPhoneNumberButton: XCUIElement
        let selectCountryButton: XCUIElement
        let areaCodeTextField: XCUIElement
        let selectCountryZZButton: XCUIElement
        let phoneNumberCell: XCUIElement
        let okButton: XCUIElement
        let backToSudosButton: XCUIElement
                
        sudoDetailsCell = SudoScreen.uiTestSudoDeatilsButton.element
        XCTAssert(sudoDetailsCell.waitForExistence(timeout: Constants.TimeOut), "Cannot locate Sudo Details Cell")
        sudoDetailsCell.tap()
        
        provisionPhoneNumberButton = SudoDetailsScreen.provisionPhoneNumberButton.element
        XCTAssert(provisionPhoneNumberButton.waitForExistence(timeout: Constants.TimeOut), "Cannot locate Provision Phone Number Button")
        provisionPhoneNumberButton.tap()
        
        selectCountryButton = XCUIApplication()/*@START_MENU_TOKEN@*/.staticTexts["Select Country"]/*[[".cells.staticTexts[\"Select Country\"]",".staticTexts[\"Select Country\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        XCTAssert(selectCountryButton.waitForExistence(timeout: Constants.TimeOut), "Cannot locate Select Country Button")
        selectCountryButton.tap()

        selectCountryZZButton = XCUIApplication().sheets["Select Country"].scrollViews.otherElements.buttons["ZZ"]
        XCTAssert(selectCountryZZButton.waitForExistence(timeout: Constants.TimeOut), "Cannot locate Country ZZ Button")
        selectCountryZZButton.tap()

        areaCodeTextField = XCUIApplication()/*@START_MENU_TOKEN@*/.textFields["Enter an Area Code"]/*[[".cells.textFields[\"Enter an Area Code\"]",".textFields[\"Enter an Area Code\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        areaCodeTextField.tap()
        areaCodeTextField.typeText(Constants.AreaCode)

        phoneNumberCell = XCUIApplication().tables.cells.element(boundBy: 2)
        XCTAssert(phoneNumberCell.waitForExistence(timeout: Constants.TimeOut), "Cannot locate Phone Number Cell")
        phoneNumberCell.tap()
        XCUIApplication().alerts["Provision"].scrollViews.otherElements.buttons["Provision"].tap()
        okButton = XCUIApplication().alerts["Success"].scrollViews.otherElements.buttons["OK"]
        XCTAssert(okButton.waitForExistence(timeout: Constants.TimeOut), "Cannot locate OK Button")
        okButton.tap()
        
        backToSudosButton = SudoDetailsScreen.backToSudosScreenButton.element
        XCTAssert(backToSudosButton.waitForExistence(timeout: Constants.TimeOut), "Cannot locate Back to Sudos Button")
        backToSudosButton.tap()
        
    }
}
