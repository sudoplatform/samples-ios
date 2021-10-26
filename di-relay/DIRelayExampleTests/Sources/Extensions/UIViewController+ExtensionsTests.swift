
//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import UIKit
import SudoDIRelay
@testable import DIRelayExample

class UIViewControllerExtensionsTests: XCTestCase {


    var testUtility: DIRelayExampleTestUtility!
    var instanceUnderTest: WelcomeViewController!

    // MARK: - Lifecycle

    override func setUp() {
        do {
            testUtility = try DIRelayExampleTestUtility()
        } catch let error {
            XCTFail(error.localizedDescription)
        }
        instanceUnderTest = testUtility.storyBoard.instantiateViewController(identifier: "welcome")
        instanceUnderTest.loadViewIfNeeded()
        testUtility.window.rootViewController = instanceUnderTest
        testUtility.window.makeKeyAndVisible()
    }

    func test_PresentActivityAlert_ReturnsCorrectController() {
        waitForAsync()
        waitUntil { done in
            defer { done() }
            self.instanceUnderTest.presentActivityAlert(message: "test_PresentActivityAlert_ReturnsCorrectController")
            let presentedAlert = self.instanceUnderTest.presentedViewController as? UIAlertController
            XCTAssertNotNil(presentedAlert)
            XCTAssertEqual(presentedAlert?.message, "test_PresentActivityAlert_ReturnsCorrectController")
        }
    }

    func test_PresentErrorAlert_ReturnsCorrectController() {
        waitForAsync()
        waitUntil { done in
            defer { done() }
            self.instanceUnderTest.presentErrorAlert(message: "", error: SudoDIRelayError.serviceError)
            let presentedAlert = self.instanceUnderTest.presentedViewController as? UIAlertController
            XCTAssertNotNil(presentedAlert)
            XCTAssertEqual(presentedAlert?.title, "Error")
            XCTAssertEqual(presentedAlert?.message, ":\nrelay.errors.serviceError")
        }
    }
}
