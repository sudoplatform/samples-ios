//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import SudoEmailNotificationExtension
@testable import EmailExampleNotificationServiceExtension

final class EmailExampleNotificationServiceExtensionTests: XCTestCase {

    let mockSudoEmailNotifiableClient = SudoEmailNotifiableClientMock()

    var iut: EmailExampleNotificationService!

    override func setUpWithError() throws {
        iut = try EmailExampleNotificationService(
            sudoEmailNotifiableClient: mockSudoEmailNotifiableClient,
            bestAttemptContent: nil,
            contentHandler: nil
        )
    }

    func testDidReceiveReturnsDecodedMessageReceivedNotification() throws {
        let decodedNotification = EmailMessageReceivedNotification(
            owner: "owner",
            emailAddressId: "email-address-id",
            sudoId: "sudo-id",
            messageId: "message-id",
            folderId: "folder-id",
            encryptionStatus: EncryptionStatus.UNENCRYPTED,
            subject: "subject",
            from: EmailAddressAndName(address: "someboidy@address.com", displayName: "Some Body"),
            replyTo: nil,
            hasAttachments: true,
            sentAt: Date(),
            receivedAt: Date())

        mockSudoEmailNotifiableClient.decodeResult = decodedNotification

        let content = UNMutableNotificationContent()
        content.title = "Original title"
        content.subtitle = "Original subtitle"
        content.body = "Original body"
        content.userInfo = ["sudoplatform":["servicename":"emService","data":"some data"]]

        iut.didReceive(UNNotificationRequest(identifier: "test", content: content, trigger: nil)) { content in
            XCTAssertEqual(content.title, decodedNotification.from.displayName)
            XCTAssertEqual(content.subtitle, decodedNotification.subject)
            XCTAssertEqual(content.body, "")
        }

        XCTAssertEqual(mockSudoEmailNotifiableClient.decodeCalls, 1)
    }

    func testDidReceiveReturnsDoesNotModifyContentIfCantDecodeMessage() throws {
        let content = UNMutableNotificationContent()
        content.title = "Original title"
        content.subtitle = "Original subtitle"
        content.body = "Original body"
        content.userInfo = ["sudoplatform":["servicename":"otherService","data":"some data"]]

        iut.didReceive(UNNotificationRequest(identifier: "test", content: content, trigger: nil)) { content in
            XCTAssertEqual(content.title, "Original title")
            XCTAssertEqual(content.subtitle, "Original subtitle")
            XCTAssertEqual(content.body, "Original body")
        }

        XCTAssertEqual(mockSudoEmailNotifiableClient.decodeCalls, 0)
    }
}
