
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
        testUtility = DIRelayExampleTestUtility()
        instanceUnderTest = testUtility.storyBoard.resolveViewController(identifier: "scanInvitation")
        instanceUnderTest.loadViewIfNeeded()
        testUtility.window.rootViewController = instanceUnderTest
        testUtility.window.makeKeyAndVisible()

        instanceUnderTest.postboxId = DataFactory.RelaySDK.randomConnectionId()
    }

    @MainActor func test_HandleInvitationObtained_CannotGenerateDetailsToSend() async {
        await self.instanceUnderTest.handleInvitationObtained("bad-invitation")
        let presentedAlert = self.instanceUnderTest.presentedViewController as? UIAlertController

        XCTAssertNotNil(presentedAlert)
        XCTAssertEqual(presentedAlert?.title, "Error")
        XCTAssertTrue(((presentedAlert?.message?.contains("Failed to parse invitation")) != nil))

    }

    @MainActor func test_HandleInvitationObtained_CanGenerateDetailsToSend() async {
        await self.instanceUnderTest.handleInvitationObtained(DataFactory.TestData.generateInvitationString())

        let presentedAlert = self.instanceUnderTest.presentedViewController as? UIAlertController
        XCTAssertNotNil(presentedAlert)
        XCTAssertEqual(presentedAlert?.title, nil)
        XCTAssertEqual(presentedAlert?.message, "Sending Request")
    }
}
