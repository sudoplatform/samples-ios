
//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import UIKit
import SudoDIRelay
@testable import SudoProfiles
@testable import DIRelayExample

class PostboxesViewControllerTests: XCTestCase {

    // MARK: - Properties

    var testUtility: DIRelayExampleTestUtility!
    var instanceUnderTest: PostboxesViewController!
    let sudo = Sudo(id: "id", claims: [], metadata: [:], createdAt: Date(), updatedAt: Date(), version: 0)

    // MARK: - Lifecycle

    override func setUp() {
        testUtility = DIRelayExampleTestUtility()
        instanceUnderTest = testUtility.storyBoard.resolveViewController(identifier: "postboxList")
        instanceUnderTest.sudo = sudo
        instanceUnderTest.ownershipProofs = [sudo.id: "proof"]
        instanceUnderTest.loadViewIfNeeded()
        testUtility.window.rootViewController = instanceUnderTest
        testUtility.window.makeKeyAndVisible()
    }

    func test_tableView_CellForRowAt_SinglePostboxIsDisplayed() throws {
        let postboxId = DataFactory.RelaySDK.randomId()
        instanceUnderTest.postboxIds = [postboxId]
        let result = instanceUnderTest.tableView(instanceUnderTest.tableView, cellForRowAt: IndexPath(row: 1, section: 0))
        XCTAssertEqual(result.textLabel?.text, postboxId)
    }


    @MainActor func test_tableView_didSelectRowAt_ZeroIndexCreatesPostbox() async {
        let postboxId = DataFactory.RelaySDK.randomId()
        testUtility.relayClient.createPostboxResult = DataFactory.RelaySDK.fromPostboxId(postboxId: postboxId)
        instanceUnderTest.tableView(instanceUnderTest.tableView, didSelectRowAt: [0, 0])
        await instanceUnderTest.createPostboxTask?.value
        XCTAssertTrue(testUtility.relayClient.createPostboxCalled)
    }

    @MainActor func test_tableView_didSelectRowAt_ZeroIndexShowsAlert() async {
        instanceUnderTest.tableView(instanceUnderTest.tableView, didSelectRowAt: [0, 0])
        await instanceUnderTest.createPostboxTask?.value
        guard let resultTableViewController = instanceUnderTest.presentedViewController else {
            return XCTFail("Failed to get presented view controller")
        }

        XCTAssertTrue(resultTableViewController is UIAlertController)
    }

    func test_tableView_didSelectRowAt_PostboxIndexSeguesToPostboxView() {
        instanceUnderTest.postboxIds = [DataFactory.RelaySDK.randomId()]
        instanceUnderTest.tableView(instanceUnderTest.tableView, didSelectRowAt: [0, 1])
        waitForAsync()
        guard let presentedViewController = instanceUnderTest.presentedViewController else {
            return XCTFail("Failed to get UITableView as presented view controller")
        }
        XCTAssertTrue(presentedViewController is PostboxViewController)
    }

    func test_PostboxRowSwipeOnZeroIndexReturnsNil() {
        instanceUnderTest.postboxIds = [DataFactory.RelaySDK.randomId()]
        let res = self.instanceUnderTest.tableView(self.instanceUnderTest.tableView, trailingSwipeActionsConfigurationForRowAt: [0, 0])
        XCTAssertNil(res)
    }

    func test_performSegue_SeguesToPostboxView() {
        instanceUnderTest.performSegue(withIdentifier: "navigateToPostbox" , sender: instanceUnderTest.self)
        waitForAsync()
        guard let resultTableViewController = instanceUnderTest.presentedViewController else {
            return XCTFail("Failed to get UITableView as presented view controller")
        }
        XCTAssertTrue(resultTableViewController is PostboxViewController)
    }

    @MainActor func test_createPostBoxAndSaveToCache_CallsCreatePostbox() async {
        let postboxId = DataFactory.RelaySDK.randomId()
        testUtility.relayClient.createPostboxResult = DataFactory.RelaySDK.fromPostboxId(postboxId: postboxId)
        await instanceUnderTest.createPostbox()
        XCTAssertTrue(testUtility.relayClient.createPostboxCalled)
    }
}
