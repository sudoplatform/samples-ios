//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

enum SudosScreen: String {
    case lockButton = "Lock"
    case infoButton = "More Info"
    case createSudoButton = "Create Sudo"
    case sudoNameButton = "Sudo 0"

    var element: XCUIElement {
        switch self {
        case .lockButton:
            return XCUIApplication().buttons[self.rawValue]
        case .infoButton:
            let sudosNavigationBar = XCUIApplication().navigationBars["Sudos"]
            return sudosNavigationBar.buttons[self.rawValue]
        case .createSudoButton, .sudoNameButton:
            return   XCUIApplication().tables.staticTexts[self.rawValue]
        }
    }

    static func createSudo() {
        let app = XCUIApplication()
        let createSudoButton: XCUIElement = self.createSudoButton.element

        XCTAssertTrue(createSudoButton.waitForExistence(timeout: Constants.timeout), "Cannot locate \(SudosScreen.createSudoButton)")
        createSudoButton.tap()
        XCTAssertTrue(app.tables.staticTexts[Constants.sudoName].waitForExistence(timeout: Constants.timeout), "Cannot locate the new Sudo cell")
    }

    static func goToVaultsScreen() {
        let sudoNameButton: XCUIElement = SudosScreen.sudoNameButton.element

        XCTAssertTrue(sudoNameButton.waitForExistence(timeout: Constants.timeout), "Cannot locate the \(SudosScreen.sudoNameButton)")
        sudoNameButton.tap()
    }

    static func lockVaults() {
        let lockButton: XCUIElement = SudosScreen.lockButton.element
        let deregisterButton: XCUIElement = SetMasterPasswordScreen.deregisterButton.element

        XCTAssertTrue(lockButton.waitForExistence(timeout: Constants.timeout), "Cannot locate the \(SudosScreen.lockButton)")
        lockButton.tap()
        XCTAssertTrue(deregisterButton.waitForExistence(timeout: Constants.timeout), "Cannot locate the \(SetMasterPasswordScreen.deregisterButton)")
    }
}
