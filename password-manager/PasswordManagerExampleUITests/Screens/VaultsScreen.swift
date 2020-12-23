//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

enum VaultsScreen: String {
    case backToSudosButton = "Sudos"
    case settingsButton = "Settings"
    case createVaultButton = "Create Vault"

    var element: XCUIElement {
        switch self {
        case .backToSudosButton, .settingsButton:
            return XCUIApplication().buttons[self.rawValue]
        case .createVaultButton:
            return XCUIApplication().tables.staticTexts[self.rawValue]
        }
    }

    static func createVault() {
        let createVaultButton: XCUIElement = VaultsScreen.createVaultButton.element
        let settingsButton: XCUIElement = VaultsScreen.settingsButton.element
        let backToSudosButton: XCUIElement = VaultsScreen.backToSudosButton.element

        XCTAssertTrue(createVaultButton.waitForExistence(timeout: Constants.timeout), "Cannot locate \(VaultsScreen.createVaultButton)")
        XCTAssertTrue(settingsButton.waitForExistence(timeout: Constants.timeout), "Cannot locate \(VaultsScreen.settingsButton)")
        XCTAssertTrue(backToSudosButton.waitForExistence(timeout: Constants.timeout), "Cannot locate \(VaultsScreen.backToSudosButton)")
        createVaultButton.tap()
        let newCell: XCUIElement = XCUIApplication().tables.cells.element(boundBy: 1)
        XCTAssertTrue(newCell.waitForExistence(timeout: Constants.timeout), "Cannot confirm that a cell was added to the table")

    }

    static func goToLoginsScreen() {
        let newlyCreatedVaultCell: XCUIElement = XCUIApplication().tables.cells.element(boundBy: 0)
        
        XCTAssertTrue(newlyCreatedVaultCell.waitForExistence(timeout: Constants.timeout), "Cannot locate newly create cell")
        newlyCreatedVaultCell.tap()
    }

    static func goBackToSudosScreen() {
        let sudosButton: XCUIElement = VaultsScreen.backToSudosButton.element
        let lockButton: XCUIElement = SudosScreen.lockButton.element

        XCTAssertTrue(sudosButton.waitForExistence(timeout: Constants.timeout), "Cannot locate \(VaultsScreen.backToSudosButton)")
        sudosButton.tap()
        XCTAssertTrue(lockButton.waitForExistence(timeout: Constants.timeout), "Cannot locate \(SudosScreen.lockButton)")
    }
}
