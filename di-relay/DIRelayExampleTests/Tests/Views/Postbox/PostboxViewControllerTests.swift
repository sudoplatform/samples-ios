
//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import UIKit
import SudoDIRelay
import SudoProfiles
@testable import DIRelayExample

class PostboxViewControllerTests: XCTestCase {

    // MARK: - Properties

    var testUtility: DIRelayExampleTestUtility!
    var instanceUnderTest: PostboxViewController!
    let postbox = DataFactory.RelaySDK.randomPostbox()
    
    let timeout = 10

    // MARK: - Lifecycle

    override func setUp() {
        testUtility = DIRelayExampleTestUtility()
        testUtility.relayClient.listPostboxesResult = ListOutput<Postbox>(items: [postbox], nextToken: nil)
        instanceUnderTest = testUtility.storyBoard.resolveViewController(identifier: "messageList")
        instanceUnderTest.postboxId = postbox.id
        instanceUnderTest.loadViewIfNeeded()
        testUtility.window.rootViewController = instanceUnderTest
        testUtility.window.makeKeyAndVisible()
    }

    func test_tableView_CellForRowAt_SingleMessageIsDisplayed() throws {
        let messageId = DataFactory.RelaySDK.randomId()
        instanceUnderTest.messageIds = [messageId]
        let result = instanceUnderTest.tableView(instanceUnderTest.tableView, cellForRowAt: IndexPath(row: 0, section: 0))
        XCTAssertEqual(result.textLabel?.text, messageId)
    }

    func test_tableView_didSelectRowAt_MessageIndexSeguesToMessageView() {
        instanceUnderTest.messageIds = [DataFactory.RelaySDK.randomId()]
        instanceUnderTest.tableView(instanceUnderTest.tableView, didSelectRowAt: [0, 0])
        waitForAsync()
        guard let presentedViewController = instanceUnderTest.presentedViewController else {
            return XCTFail("Failed to get UITableView as presented view controller")
        }
        XCTAssertTrue(presentedViewController is MessageDetailsViewController)
    }
}
