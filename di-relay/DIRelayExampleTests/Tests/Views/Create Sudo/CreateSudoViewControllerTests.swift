
//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import UIKit
import SudoDIRelay

@testable import DIRelayExample

class CreateSudoViewControllerTests: XCTestCase {

    // MARK: - Properties

    var testUtility: DIRelayExampleTestUtility!
    var instanceUnderTest: CreateSudoViewController!

    // MARK: - Lifecycle

    override func setUp() {

        testUtility = DIRelayExampleTestUtility()
        instanceUnderTest = testUtility.storyBoard.resolveViewController(identifier: "createSudo")
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

    func test_createSudo_willCallCreateSudo() async {
        await instanceUnderTest.createSudo()
        XCTAssertTrue(testUtility.profilesClient.createSudoCalled)
    }

    func test_performSegue_SeguesToListPostboxView() {
        instanceUnderTest.performSegue(withIdentifier: CreateSudoViewController.Segue.navigateToSudoList.rawValue , sender: instanceUnderTest.self)
        waitForAsync()
        guard let resultTableViewController = instanceUnderTest.presentedViewController else {
            return XCTFail("Failed to get UITableView as presented view controller")
        }
        XCTAssertTrue(resultTableViewController is SudoListViewController)
    }
}
