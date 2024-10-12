//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import SudoEmail
@testable import EmailExample

class ReadEmailMessageViewControllerTests: XCTestCase {

    // MARK: - Properties

    var testUtility: EmailExampleTestUtility!
    var instanceUnderTest: ReadEmailMessageViewController!

    // MARK: - Lifecycle

    @MainActor
    override func setUp() {
        testUtility = EmailExampleTestUtility()
        instanceUnderTest = testUtility.storyBoard.instantiateViewController(identifier: "readEmailMessage")
        instanceUnderTest.loadViewIfNeeded()
        instanceUnderTest.emailClient = testUtility.emailClient
        let ownerId = UUID().uuidString
        let emailAddressId = UUID().uuidString
        let address = DataFactory.EmailSDK.randomEmailAddress()
        instanceUnderTest.emailAddress = DataFactory.EmailSDK.generateEmailAddress(
            id: emailAddressId,
            owner: ownerId,
            address: address
        )

        instanceUnderTest.emailMessage = DataFactory.EmailSDK.generateEmailMessage(
            owner: ownerId,
            emailAddressId: emailAddressId,
            fromAddresses: [.init(address: "from@test.org")],
            subject: "Test Message Subject"
        )
        testUtility.window.rootViewController = instanceUnderTest
        testUtility.window.makeKeyAndVisible()
    }

    override func tearDown() {
        testUtility.clearWindow()
    }

    // MARK: - Tests -> Reply

    func test_replyButton_isPresent() throws {
        XCTAssertEqual(instanceUnderTest.navigationItem.rightBarButtonItems?[0].accessibilityIdentifier, "replyButton")
    }

    func test_replyButton_willInvokeReplyToMessage() throws {
        XCTAssertEqual(instanceUnderTest.navigationItem.rightBarButtonItems?[0].action?.description, "replyToMessage:")
    }

    func test_constructReplyMessage_PreparesCorrectReply() {
        instanceUnderTest.bodyLabel.text = "How does this look"
        guard let result = instanceUnderTest.constructReplyInput() else {
            return XCTFail("Failed to construct reply message")
        }
        XCTAssertEqual(result.to, "from@test.org")
        XCTAssertEqual(result.subject, "Re: Test Message Subject")
        XCTAssertTrue(result.body.contains("\n\n---------------\n\nHow does this look"))
    }

    func test_constructReplyMessage_Drafts_PreparesCorrectReply() {
        instanceUnderTest.bodyLabel.text = "How does this look"
        instanceUnderTest.emailMessage.folderId = "01234_DRAFTS"
        instanceUnderTest.emailMessage.subject = "Re: " + (instanceUnderTest.emailMessage.subject ?? "")
        guard let result = instanceUnderTest.constructReplyInput() else {
            return XCTFail("Failed to construct reply message")
        }
        XCTAssertEqual(result.to, "to <to@example.com>")
        XCTAssertEqual(result.subject, " Test Message Subject")
        XCTAssertFalse(result.body.contains("\n\n---------------\n\nHow does this look"))
        XCTAssertTrue(result.body.contains("How does this look"))
    }

    // MARK: - Tests -> Forward

    func test_forwardButton_isPresent() throws {
        XCTAssertEqual(instanceUnderTest.navigationItem.rightBarButtonItems?[1].accessibilityIdentifier, "forwardButton")
    }

    func test_forwardButton_willInvokeForwardMessage() throws {
        XCTAssertEqual(instanceUnderTest.navigationItem.rightBarButtonItems?[1].action?.description, "forwardMessage:")
    }

    func test_constructForwardMessage_PreparesCorrectForwardMessage() {
        instanceUnderTest.bodyLabel.text = "How does THIS look"
        guard let result = instanceUnderTest.constructForwardInput() else {
            return XCTFail("Failed to construct forward message")
        }
        XCTAssertEqual(result.subject, "Fwd: Test Message Subject")
        XCTAssertTrue(result.body.contains("\n\n---------------\n\nHow does THIS look"))
    }

    func test_constructForwardMessage_Drafts_PreparesCorrectForwardMessage() {
        instanceUnderTest.bodyLabel.text = "How does THIS look"
        instanceUnderTest.emailMessage.folderId = "01234_DRAFTS"
        instanceUnderTest.emailMessage.subject = "Fwd: " + (instanceUnderTest.emailMessage.subject ?? "")
        guard let result = instanceUnderTest.constructForwardInput() else {
            return XCTFail("Failed to construct forward message")
        }
        XCTAssertEqual(result.subject, " Test Message Subject")
        XCTAssertFalse(result.body.contains("\n\n---------------\n\nHow does THIS look"))
        XCTAssertTrue(result.body.contains("How does THIS look"))
    }

    // MARK: - Tests -> Read

    func test_readDraftEmailMessage() async {
        do {
            let draft = try await instanceUnderTest.readDraftEmailMessage(
                messageId: "dummyDraftId"
            )
            XCTAssertFalse(draft.isEmpty)
            XCTAssertTrue(testUtility.emailClient.getDraftEmailMessageCalled)
            XCTAssertEqual(
                testUtility.emailClient.getDraftEmailMessageParameter?.id,
                "dummyDraftId"
            )
        } catch {
            return XCTFail("read draft threw error \(error)")
        }
    }

    func test_readEmailMessage() async {
        let messageId = "dummyMessageId"
        let dummyResult = DataFactory.EmailSDK.generateEmailMessageWithBody(id: messageId)
        testUtility.emailClient.getEmailMessageWithBodyResult = dummyResult
        do {
            let messageWithBody = try await instanceUnderTest.readEmailMessage(
                messageId: messageId
            )
            XCTAssertNotNil(messageWithBody)
            XCTAssertTrue(testUtility.emailClient.getEmailMessageWithBodyCalled)
            XCTAssertEqual(
                testUtility.emailClient.getEmailMessageWithBodyParameters?.id,
                messageId
            )
        } catch {
            return XCTFail("Unexpected error getting message with body: \(error)")
        }
    }

    @MainActor
    func test_loadEmailMessage_RetrievesAttachments() {
        let dummyAttachment = DataFactory.EmailSDK.generateEmailAttachment()
        testUtility.emailClient.getEmailMessageWithBodyResult = EmailMessageWithBody(
            id: "dummyMessageId",
            body: "dummyMessageBody",
            isHtml: false,
            attachments: [dummyAttachment],
            inlineAttachments: []
        )

        instanceUnderTest.loadEmailMessage(instanceUnderTest.emailMessage)

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 2.0))

        XCTAssertTrue(testUtility.emailClient.getEmailMessageWithBodyCalled)
        XCTAssertEqual(instanceUnderTest.attachments, [dummyAttachment])
    }
}
