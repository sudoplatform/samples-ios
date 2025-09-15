
//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import UIKit
import SudoDIRelay
@testable import DIRelayExample

class UIViewControllerExtensionsTests: XCTestCase {


    var testUtility: DIRelayExampleTestUtility!
    var instanceUnderTest: RegistrationViewController!

    // MARK: - Lifecycle

    override func setUp() {
        testUtility = DIRelayExampleTestUtility()
        instanceUnderTest = testUtility.storyBoard.instantiateViewController(identifier: "register")
        instanceUnderTest.loadViewIfNeeded()
        testUtility.window.rootViewController = instanceUnderTest
        testUtility.window.makeKeyAndVisible()
    }

    @MainActor func test_PresentActivityAlert_ReturnsCorrectController() async {
        await instanceUnderTest.presentActivityAlert(message: "test_PresentActivityAlert_ReturnsCorrectController")
        let presentedAlert = self.instanceUnderTest.presentedViewController as? UIAlertController
        XCTAssertNotNil(presentedAlert)
        XCTAssertEqual(presentedAlert?.message, "test_PresentActivityAlert_ReturnsCorrectController")
    }

    @MainActor func test_PresentErrorAlert_ReturnsCorrectController() async {
        await instanceUnderTest.presentErrorAlert(message: "", error: SudoDIRelayError.serviceError)
        let presentedAlert = instanceUnderTest.presentedViewController as? UIAlertController
        XCTAssertNotNil(presentedAlert)
        XCTAssertEqual(presentedAlert?.title, "Error")
        XCTAssertEqual(presentedAlert?.message, ":\nrelay.errors.serviceError")
    }
}
