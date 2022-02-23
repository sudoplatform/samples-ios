
//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import UIKit
import SudoDIRelay
@testable import DIRelayExample

class PostboxViewControllerTests: XCTestCase {

    // MARK: - Properties

    var testUtility: DIRelayExampleTestUtility!
    var instanceUnderTest: PostboxViewController!

    // MARK: - Lifecycle

    override func setUp() {
        do {
            testUtility = try DIRelayExampleTestUtility()
        } catch {
            XCTFail(error.localizedDescription)
        }
        instanceUnderTest = testUtility.storyBoard.resolveViewController(identifier: "postboxList")
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

    func test_DeletePostboxFromRelayAndCache_DeletePostbox() {
        let postboxId = DataFactory.RelaySDK.randomConnectionId()
        instanceUnderTest.postboxIds = [postboxId]
        waitForAsync()
        waitUntil(timeout: 5.0) { done in
            defer { done() }
            let _ = self.instanceUnderTest.deletePostboxFromRelayAndCache(postBoxId: postboxId)
        }
        XCTAssertTrue(testUtility.relayClient.deletePostboxCalled)
    }

    func test_PostboxRowSwipeOnZeroIndexReturnsNil() {
        instanceUnderTest.postboxIds = [DataFactory.RelaySDK.randomConnectionId()]
        let res = self.instanceUnderTest.tableView(self.instanceUnderTest.tableView, trailingSwipeActionsConfigurationForRowAt: [0, 0])
        XCTAssertNil(res)
    }

    func test_PostboxDeletionSucceeds() {
        testUtility.relayClient.deletePostboxResult = .success(())
        waitForAsync()
        waitUntil { done in
            defer { done() }
            let id = DataFactory.RelaySDK.randomConnectionId()
            self.instanceUnderTest.deletePostboxFromRelayAndCache(postBoxId: id)
            XCTAssertTrue(self.testUtility.relayClient.deletePostboxCalled)
        }
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
}
