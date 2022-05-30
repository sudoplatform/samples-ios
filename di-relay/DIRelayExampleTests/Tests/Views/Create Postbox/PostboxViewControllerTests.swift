
//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
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
    let sudo = Sudo()

    // MARK: - Lifecycle

    override func setUp() {
        testUtility = DIRelayExampleTestUtility()
        instanceUnderTest = testUtility.storyBoard.resolveViewController(identifier: "postboxList")
        instanceUnderTest.sudo = sudo
        instanceUnderTest.ownershipProofs = [sudo.id ?? "": "proof"]
        instanceUnderTest.loadViewIfNeeded()
        testUtility.window.rootViewController = instanceUnderTest
        testUtility.window.makeKeyAndVisible()
    }

    func test_tableView_CellForRowAt_SinglePostboxIsDisplayed() throws {
        let connectionId = DataFactory.RelaySDK.randomConnectionId()
        instanceUnderTest.postboxIds = [connectionId]
        let result = instanceUnderTest.tableView(instanceUnderTest.tableView, cellForRowAt: IndexPath(row: 1, section: 0))
        XCTAssertEqual(result.textLabel?.text, connectionId)
    }


    func test_tableView_didSelectRowAt_ZeroIndexCreatesPostbox() {
        instanceUnderTest.tableView(instanceUnderTest.tableView, didSelectRowAt: [0, 0])
        waitForAsync()
        if instanceUnderTest.presentedViewController == nil {
            return XCTFail("Failed to get presented view controller")
        }
        XCTAssertTrue(testUtility.relayClient.createPostboxCalled)
    }

    func test_tableView_didSelectRowAt_ZeroIndexShowsAlert() {
        instanceUnderTest.tableView(instanceUnderTest.tableView, didSelectRowAt: [0, 0])
        waitForAsync()
        guard let resultTableViewController = instanceUnderTest.presentedViewController else {
            return XCTFail("Failed to get presented view controller")
        }

        XCTAssertTrue(resultTableViewController is UIAlertController)
    }

    func test_tableView_didSelectRowAt_PostboxIndexSeguesToCreateView() {
        instanceUnderTest.postboxIds = [DataFactory.RelaySDK.randomConnectionId()]
        instanceUnderTest.tableView(instanceUnderTest.tableView, didSelectRowAt: [0, 1])
        waitForAsync()
        guard let presentedViewController = instanceUnderTest.presentedViewController else {
            return XCTFail("Failed to get UITableView as presented view controller")
        }
        XCTAssertTrue(presentedViewController is CreateConnectionViewController)
    }

    func test_PostboxRowSwipeOnZeroIndexReturnsNil() {
        instanceUnderTest.postboxIds = [DataFactory.RelaySDK.randomConnectionId()]
        let res = self.instanceUnderTest.tableView(self.instanceUnderTest.tableView, trailingSwipeActionsConfigurationForRowAt: [0, 0])
        XCTAssertNil(res)
    }

    func test_performSegue_SeguesToCreateConnectionView() {
        instanceUnderTest.performSegue(withIdentifier: "navigateToConnection" , sender: instanceUnderTest.self)
        waitForAsync()
        guard let resultTableViewController = instanceUnderTest.presentedViewController else {
            return XCTFail("Failed to get UITableView as presented view controller")
        }
        XCTAssertTrue(resultTableViewController is ConnectionViewController)
    }

    func test_performSegue_SeguesToConnectionView() {
        instanceUnderTest.performSegue(withIdentifier: "navigateToCreateConnection" , sender: instanceUnderTest.self)
        waitForAsync()
        guard let resultTableViewController = instanceUnderTest.presentedViewController else {
            return XCTFail("Failed to get UITableView as presented view controller")
        }
        XCTAssertTrue(resultTableViewController is CreateConnectionViewController)
    }

    func test_createPostBoxAndSaveToCache_CallsCreatePostbox() async {
        await instanceUnderTest.createPostBoxAndSaveToCache()
        if await instanceUnderTest.presentedViewController == nil {
            return XCTFail("Failed to get presented view controller")
        }
        XCTAssertTrue(testUtility.relayClient.createPostboxCalled)
    }
}
