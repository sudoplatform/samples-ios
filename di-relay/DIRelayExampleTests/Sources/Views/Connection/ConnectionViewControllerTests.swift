
//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import UIKit
import SudoDIRelay
@testable import DIRelayExample

class ConnectionViewControllerTests: XCTestCase {

    // MARK: - Properties

    var testUtility: DIRelayExampleTestUtility!
    var instanceUnderTest: ConnectionViewController!

    // MARK: - Lifecycle

    override func setUp() {
        do {
            testUtility = try DIRelayExampleTestUtility()
        } catch let error {
            XCTFail(error.localizedDescription)
        }
        instanceUnderTest = testUtility.storyBoard.resolveViewController(identifier: "connection")
        instanceUnderTest.loadViewIfNeeded()
        testUtility.window.rootViewController = instanceUnderTest
        testUtility.window.makeKeyAndVisible()

        instanceUnderTest.myPostboxId = DataFactory.RelaySDK.randomConnectionId()
    }

    override func tearDown() {
        do {
            try testUtility.relayClient.reset()
        } catch let error {
            print("Unable to tear down after test. \(error)")
        }
    }

    func test_tableView_CellForRowAt_FirstPresentsSummary() throws {
        let message = DataFactory.TestData.generatePresentableMessage()
        instanceUnderTest.messageLog = [message]

        let result = instanceUnderTest.tableView(instanceUnderTest.tableView, cellForRowAt: IndexPath(row: 0, section: 0))

        guard let resultAsSummaryCell = result as? ConnectionSummaryTableViewCell else {
            XCTFail("Unexpected cell found")
            return
        }
        XCTAssertTrue(((resultAsSummaryCell.summaryLabel.text?.contains("Connected to peer with postbox ID: ")) != nil))
    }

    func test_tableView_CellForRowAt_SingleMessageIsDisplayedAfterSummary() throws {
        let message = DataFactory.TestData.generatePresentableMessage()
        instanceUnderTest.messageLog = [message, message]
        let postboxId = DataFactory.RelaySDK.randomConnectionId()
        instanceUnderTest.myPostboxId = postboxId
        let result = instanceUnderTest.tableView(instanceUnderTest.tableView, cellForRowAt: [0,0])
        guard (result as? ConnectionMessageTableViewCell) != nil else {
            XCTFail("Unexpected cell found")
            return
        }
    }

    func test_ProcessMessagesReceived_AppendsDecryptedMessageToLog() {
        var message = DataFactory.RelaySDK.generateRelayMessage()
        message.messageId = "init"
        self.instanceUnderTest.processMessageReceived(message: message)
        waitForAsync()

        XCTAssert(self.instanceUnderTest.messageLog.count == 1)
        //XCTAssert(self.instanceUnderTest.messageLog[0].message == message)
    }

    func test_DecryptReceivedMessageOrPresentError_DoesNotDecryptInitMessage() {
        var message = DataFactory.RelaySDK.generateRelayMessage()
        message.messageId = "init"
        let decrypted = self.instanceUnderTest.decryptReceivedMessageOrPresentError(relayMessage: message)

        XCTAssertEqual(decrypted, "Test Subject")
    }

    func test_PrepareMetadataOnLoad_CallsSubscribeToMessagesReceived() {
        instanceUnderTest.prepareMetadataOnLoad()
        waitForAsync()
        XCTAssertTrue(testUtility.relayClient.subscribeToMessagesReceivedCalled)
    }

    func test_PrepareMetadataOnLoad_CallsGetMessages() {
        instanceUnderTest.prepareMetadataOnLoad()
        waitForAsync()
        XCTAssertTrue(testUtility.relayClient.getMessagesCalled)
    }


    func test_PerformSegue_SeguesToConnectionView() {
        instanceUnderTest.performSegue(withIdentifier: "navigateToConnectionDetails" , sender: instanceUnderTest.self)
        waitForAsync()
        guard let resultTableViewController = instanceUnderTest.presentedViewController else {
            return XCTFail("Failed to get UITableView as presented view controller")
        }
        XCTAssertTrue(resultTableViewController is ConnectionDetailsViewController)
    }

    func test_TransformDateFromRelay_CorrectlyTransformDate() {
        let timestamp = DataFactory.TestData.generateTimestamp()
        do {
            let date = try instanceUnderTest.transformDateFromRelay(timestamp: timestamp)
            XCTAssertEqual(date, Date(timeIntervalSince1970: 0))
        } catch let error {
            XCTFail("Unexpected error \(error)")
        }
    }

}
