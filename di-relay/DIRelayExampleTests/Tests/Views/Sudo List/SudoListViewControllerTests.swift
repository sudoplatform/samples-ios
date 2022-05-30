
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

class SudoListViewControllerTests: XCTestCase {

    // MARK: - Properties

    var testUtility: DIRelayExampleTestUtility!
    var instanceUnderTest: SudoListViewController!

    // MARK: - Lifecycle

    override func setUp() {
        testUtility = DIRelayExampleTestUtility()
        instanceUnderTest = testUtility.storyBoard.resolveViewController(identifier: "listSudos")
        instanceUnderTest.loadViewIfNeeded()
        testUtility.window.rootViewController = instanceUnderTest
        testUtility.window.makeKeyAndVisible()
    }

    override func tearDown() {
        do {
            try testUtility.relayClient.reset()
        } catch {
            print("Unable to tear down after test. \(error)")
        }
    }

    func test_tableView_didSelectRowAt_ZeroIndexCreatesPostbox() {
        instanceUnderTest.tableView(instanceUnderTest.tableView, didSelectRowAt: [0, 0])
        waitForAsync()
        if instanceUnderTest.presentedViewController == nil {
            return XCTFail("Failed to get presented view controller")
        }
        guard let resultTableViewController = instanceUnderTest.presentedViewController else {
            return XCTFail("Failed to get UITableView as presented view controller")
        }
        XCTAssertTrue(resultTableViewController is CreateSudoViewController)
    }

    func test_SudoListDeleteSudoSucceeds() async throws {
        await instanceUnderTest.viewWillAppear(true)
        let testSudo = Sudo()
        let status = await instanceUnderTest.deleteSudo(sudo: testSudo)
        XCTAssertTrue(status)
    }


    func test_performSegue_SeguesToCreateSudoView() {
        instanceUnderTest.performSegue(withIdentifier: SudoListViewController.Segue.navigateToCreateSudo.rawValue , sender: instanceUnderTest.self)
        waitForAsync()
        guard let resultTableViewController = instanceUnderTest.presentedViewController else {
            return XCTFail("Failed to get UITableView as presented view controller")
        }
        XCTAssertTrue(resultTableViewController is CreateSudoViewController)
    }

    func test_loadCacheSudosAndFetchRemote_CallsListSudos() async {
        await instanceUnderTest.loadCacheSudosAndFetchRemote()
        XCTAssertTrue(testUtility.profilesClient.listSudosCalled)
    }

    func test_deleteSudo_callsDeleteSudo() async {
        _ = await instanceUnderTest.deleteSudo(sudo: Sudo())
        XCTAssertTrue(testUtility.profilesClient.deleteSudoCalled)
    }
}
