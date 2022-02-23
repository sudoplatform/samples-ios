
//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import UIKit
import SudoDIRelay
@testable import DIRelayExample

class ScanInvitationCodeViewControllerTests: XCTestCase {

    // MARK: - Properties

    var testUtility: DIRelayExampleTestUtility!
    var instanceUnderTest: ScanInvitationViewController!

    // MARK: - Lifecycle

    override func setUp() {
        do {
            testUtility = try DIRelayExampleTestUtility()
        } catch {
            XCTFail(error.localizedDescription)
        }
        instanceUnderTest = testUtility.storyBoard.resolveViewController(identifier: "scanInvitation")
        instanceUnderTest.loadViewIfNeeded()
        testUtility.window.rootViewController = instanceUnderTest
        testUtility.window.makeKeyAndVisible()

        instanceUnderTest.postboxId = DataFactory.RelaySDK.randomConnectionId()
    }

    func test_HandleInvitationObtained_CannotGenerateDetailsToSend() {
        self.instanceUnderTest.handleInvitationObtained("bad-invitation")
        waitForAsync()
        let presentedAlert = self.instanceUnderTest.presentedViewController as? UIAlertController
        XCTAssertNotNil(presentedAlert)
        XCTAssertEqual(presentedAlert?.title, "Error")
        XCTAssertTrue(((presentedAlert?.message?.contains("Failed to parse invitation")) != nil))
    }

    func test_HandleInvitationObtained_CanGenerateDetailsToSend() {
        self.instanceUnderTest.handleInvitationObtained(DataFactory.TestData.generateInvitationString())
        waitForAsync()

        let presentedAlert = self.instanceUnderTest.presentedViewController as? UIAlertController
        XCTAssertNotNil(presentedAlert)
        XCTAssertEqual(presentedAlert?.title, nil)
        XCTAssertEqual(presentedAlert?.message, "Sending Request")
    }
}
