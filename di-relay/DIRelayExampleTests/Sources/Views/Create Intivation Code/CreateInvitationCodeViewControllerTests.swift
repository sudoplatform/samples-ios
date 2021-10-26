
//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import UIKit
import SudoDIRelay
@testable import DIRelayExample

class CreateInvitationCodeViewControllerTests: XCTestCase {

    // MARK: - Properties

    var testUtility: DIRelayExampleTestUtility!
    var instanceUnderTest: CreateInvitationCodeViewController!

    // MARK: - Lifecycle

    override func setUp() {
        do {
            testUtility = try DIRelayExampleTestUtility()
        } catch let error {
            XCTFail(error.localizedDescription)
        }
        instanceUnderTest = testUtility.storyBoard.resolveViewController(identifier: "createInvitation")
        instanceUnderTest.loadViewIfNeeded()
        testUtility.window.rootViewController = instanceUnderTest
        testUtility.window.makeKeyAndVisible()

        instanceUnderTest.myPostboxId = DataFactory.RelaySDK.randomConnectionId()
    }

    func test_CreateInvitationCode_CallsSubscription() {
        testUtility.relayClient.subscribeToMessagesReceivedResult = .success(DataFactory.RelaySDK.generateRelayMessage())
        waitUntil { done in
            defer { done() }
            self.instanceUnderTest.createInvitationCode()
        }
        XCTAssertTrue(self.testUtility.relayClient.subscribeToMessagesReceivedCalled)
    }

    func test_PerformSegue_SeguesToConnectionView() {
        instanceUnderTest.performSegue(withIdentifier: "navigateToConnection" , sender: instanceUnderTest.self)
        waitForAsync()
        guard let resultTableViewController = instanceUnderTest.presentedViewController else {
            return XCTFail("Failed to get UITableView as presented view controller")
        }
        XCTAssertTrue(resultTableViewController is ConnectionViewController)
    }
}
