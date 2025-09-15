
//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import UIKit
import SudoDIRelay

@testable import DIRelayExample

class MessageDetailsViewControllerTests: XCTestCase {

    // MARK: - Properties

    var testUtility: DIRelayExampleTestUtility!
    var instanceUnderTest: MessageDetailsViewController!

    // MARK: - Lifecycle

    override func setUp() {

        testUtility = DIRelayExampleTestUtility()
        instanceUnderTest = testUtility.storyBoard.resolveViewController(identifier: "messageDetails")
        instanceUnderTest.loadViewIfNeeded()
        testUtility.window.rootViewController = instanceUnderTest
        testUtility.window.makeKeyAndVisible()

        instanceUnderTest.messageId = DataFactory.RelaySDK.randomId()
        instanceUnderTest.message = DataFactory.RelaySDK.fromMessageId(messageId: instanceUnderTest.messageId)
    }

    override func tearDown() {
        do {
            try testUtility.relayClient.reset()
        } catch {
            print("Unable to tear down after test. \(error)")
        }
    }

    func test_tableView_Cells_AreDisplayed() throws {
        // We cannot access the text of the cells to verify them, so we just have to verify that the cells
        // are all present
        for i in 0...5  {
            let resultDataCell = instanceUnderTest.tableView(
                instanceUnderTest.tableView,
                cellForRowAt: IndexPath(row: i, section: 0))
            XCTAssertNotNil(resultDataCell)
        }

    }
}
