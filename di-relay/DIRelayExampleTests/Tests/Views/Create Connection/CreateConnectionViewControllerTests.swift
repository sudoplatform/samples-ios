
//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import UIKit
import SudoDIRelay
@testable import DIRelayExample

class CreateConnectionViewControllerTests: XCTestCase {

    // MARK: - Properties

    var testUtility: DIRelayExampleTestUtility! 
    var instanceUnderTest: CreateConnectionViewController!

    // MARK: - Lifecycle

    override func setUp() {
        testUtility = DIRelayExampleTestUtility()
        instanceUnderTest = testUtility.storyBoard.resolveViewController(identifier: "createConnection")
        instanceUnderTest.loadViewIfNeeded()
        testUtility.window.rootViewController = instanceUnderTest
        testUtility.window.makeKeyAndVisible()
        instanceUnderTest.postboxId = DataFactory.RelaySDK.randomConnectionId()
    }

    func test_performSegue_SeguesToScanView() {
        instanceUnderTest.performSegue(withIdentifier: "navigateToScanInvitation" , sender: instanceUnderTest.self)
        waitForAsync()
        guard let resultTableViewController = instanceUnderTest.presentedViewController else {
            return XCTFail("Failed to get UITableView as presented view controller")
        }
        XCTAssertTrue(resultTableViewController is ScanInvitationViewController)
    }

    func test_performSegue_SeguesToCreateView() {
        instanceUnderTest.performSegue(withIdentifier: "navigateToCreateInvitation" , sender: instanceUnderTest.self)
        waitForAsync()
        guard let resultTableViewController = instanceUnderTest.presentedViewController else {
            return XCTFail("Failed to get UITableView as presented view controller")
        }
        XCTAssertTrue(resultTableViewController is CreateInvitationCodeViewController)
    }

}
