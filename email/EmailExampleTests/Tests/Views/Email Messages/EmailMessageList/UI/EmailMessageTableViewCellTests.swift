//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import UIKit
import SudoEmail
@testable import EmailExample

class EmailMessageTableViewCellTests: XCTestCase {

    // MARK: - Properties

    var instanceUnderTest: EmailMessageTableViewCell!

    // MARK: - Lifecycle

    override func setUp() {
        continueAfterFailure = false
        defer { continueAfterFailure = true }
        let bundle = Bundle(for: EmailMessageTableViewCell.self)
        guard let cell = bundle.loadNibNamed("EmailMessageTableViewCell", owner: nil)?.first as? EmailMessageTableViewCell else {
            return XCTFail("Failed to load nib")
        }
        instanceUnderTest = cell
    }

    // MARK: - Utility

    func assertAllLabelsNil(_ instanceUnderTest: EmailMessageTableViewCell, file: StaticString = #file, line: UInt = #line) {
        XCTAssertNil(instanceUnderTest.recipientsLabel.text, file: file, line: line)
        XCTAssertNil(instanceUnderTest.dateLabel.text, file: file, line: line)
        XCTAssertNil(instanceUnderTest.subjectLabel.text, file: file, line: line)
    }

    // MARK: - Tests

    func test_awakeFromNib() throws {
        let bundle = Bundle(for: EmailMessageTableViewCell.self)
        guard let instanceUnderTest = bundle.loadNibNamed("EmailMessageTableViewCell", owner: nil)?.first as? EmailMessageTableViewCell else {
            return XCTFail("Failed to load nib")
        }
        assertAllLabelsNil(instanceUnderTest)
    }

    func test_emailMessage_DidSet_NilUpdateWillSetAllLabelsToNil() {
        let emailMessage = DataFactory.EmailSDK.generateEmailMessage()
        instanceUnderTest.emailMessage = emailMessage
        instanceUnderTest.emailMessage = nil
        assertAllLabelsNil(instanceUnderTest)
    }

    func test_emailMessage_DidSet_InboundDirectionStartsWithFrom() {
        let emailMessage = DataFactory.EmailSDK.generateEmailMessage(direction: .inbound)
        instanceUnderTest.emailMessage = emailMessage
        guard let recipientText = instanceUnderTest.recipientsLabel?.text else {
            return XCTFail("Failed to get recipient text")
        }
        XCTAssertTrue(
            recipientText.starts(with: "From: "),
            "Recipient label does not start with \"From: \": \(String(describing: instanceUnderTest.recipientsLabel?.text))"
        )
    }

    func test_emailMessage_DidSet_InboundDirectionAddsFirstFromAsText() {
        let emailMessage = DataFactory.EmailSDK.generateEmailMessage(
            direction: .inbound,
            fromAddresses: [EmailAddressAndName(address: "test@example.com", displayName: "Testie Tester")]
        )
        instanceUnderTest.emailMessage = emailMessage
        guard let recipientText = instanceUnderTest.recipientsLabel?.text else {
            return XCTFail("Failed to get recipient text")
        }
        XCTAssertEqual(recipientText, "From: Testie Tester")
    }

    func test_emailMessage_DidSet_OutboundDirectionStartsWithTo() {
        let emailMessage = DataFactory.EmailSDK.generateEmailMessage(direction: .outbound)
        instanceUnderTest.emailMessage = emailMessage
        guard let recipientText = instanceUnderTest.recipientsLabel?.text else {
            return XCTFail("Failed to get recipient text")
        }
        XCTAssertTrue(
            recipientText.starts(with: "To: "),
            "Recipient label does not start with \"To: \": \(String(describing: instanceUnderTest.recipientsLabel?.text))"
        )
    }

    func test_emailMessage_DidSet_OutboundDirectionConcatsAllToRecipientsAsText() {
        let emailMessage = DataFactory.EmailSDK.generateEmailMessage(
            direction: .outbound,
            toAddresses: [
                EmailAddressAndName(address: "email1@example.com", displayName: "email1"),
                EmailAddressAndName(address: "email2@example.com", displayName: "email2"),
                EmailAddressAndName(address: "email3@example.com")
            ]
        )
        instanceUnderTest.emailMessage = emailMessage
        guard let recipientText = instanceUnderTest.recipientsLabel?.text else {
            return XCTFail("Failed to get recipient text")
        }
        XCTAssertEqual(recipientText, "To: email1, email2, email3@example.com")
    }

    func test_emailMessage_DidSet_DateLabelFormattedCorrectly_SingularDay() {
        /// January 1, 1970
        let date = Date(timeIntervalSince1970: 0.0)
        let emailMessage = DataFactory.EmailSDK.generateEmailMessage(createdAt: date)
        instanceUnderTest.emailMessage = emailMessage
        guard let dateText = instanceUnderTest.dateLabel?.text else {
            return XCTFail("Failed to get date text")
        }
        XCTAssertEqual(dateText, "Jan 1, 1970")
    }

    func test_emailMessage_DidSet_DateLabelFormattedCorrectly_DoubleDigitDay() {
        let tenDaysInSeconds = 3600.0 * 24.0 * 10.0
        /// January 11, 1970
        let date = Date(timeIntervalSince1970: tenDaysInSeconds)
        let emailMessage = DataFactory.EmailSDK.generateEmailMessage(createdAt: date)
        instanceUnderTest.emailMessage = emailMessage
        guard let dateText = instanceUnderTest.dateLabel?.text else {
            return XCTFail("Failed to get date text")
        }
        XCTAssertEqual(dateText, "Jan 11, 1970")
    }

    func test_emailMessage_DidSet_SubjectLabelFormattedCorrectly_NoSubjectDefaultUsed() {
        let emailMessage = DataFactory.EmailSDK.generateEmailMessage(subject: nil)
        instanceUnderTest.emailMessage = emailMessage
        guard let subjectText = instanceUnderTest.subjectLabel?.text else {
            return XCTFail("Failed to get subject text")
        }
        XCTAssertEqual(subjectText, "No Subject")
    }

    func test_emailMessage_DidSet_SubjectLabelFormattedCorrectly() {
        let emailMessage = DataFactory.EmailSDK.generateEmailMessage(subject: "Hello, World!")
        instanceUnderTest.emailMessage = emailMessage
        guard let subjectText = instanceUnderTest.subjectLabel?.text else {
            return XCTFail("Failed to get subject text")
        }
        XCTAssertEqual(subjectText, "Hello, World!")
    }

    func test_emailMessage_DidSet_SubjectLabelFormattedCorrectly_EncryptionIconVisible() {
        let subject = "Encrypted message"
        let emailMessage = DataFactory.EmailSDK.generateEmailMessage(
            subject: subject,
            encryptionStatus: EncryptionStatus.ENCRYPTED
        )
        instanceUnderTest.emailMessage = emailMessage
        guard let subjectText = instanceUnderTest.subjectLabel?.text else {
            return XCTFail("Failed to get subject text")
        }
        // Can't string assert against a stringified system icon -
        // but the leading " " will not be present if the icon characters aren't
        XCTAssertNotEqual(subjectText, subject)
        XCTAssertTrue(subjectText.contains(subject))
        XCTAssertEqual(subjectText.count, subject.count + 2)
    }

    func test_emailMessage_DidSet_SubjectLabelFormattedCorrectly_EncryptionIconNotVisible() {
        let subject = "Unencrypted message"
        let emailMessage = DataFactory.EmailSDK.generateEmailMessage(
            subject: subject,
            encryptionStatus: EncryptionStatus.UNENCRYPTED
        )
        instanceUnderTest.emailMessage = emailMessage
        guard let subjectText = instanceUnderTest.subjectLabel?.text else {
            return XCTFail("Failed to get subject text")
        }
        // Can't string assert against a stringified system icon -
        // but the leading " " will not be present if the icon characters aren't
        XCTAssertEqual(subjectText, subject)
    }

    func test_emailMessage_DidSet_SubjectLabelFormattedCorrectly_AttachmentsIconVisible() {
        let subject = "Message with attachment"
        let emailMessage = DataFactory.EmailSDK.generateEmailMessage(
            subject: subject,
            hasAttachments: true
        )
        instanceUnderTest.emailMessage = emailMessage
        guard let subjectText = instanceUnderTest.subjectLabel?.text else {
            return XCTFail("Failed to get subject text")
        }
        // Can't string assert against a stringified system icon -
        // but the leading " " will not be present if the icon characters aren't
        XCTAssertNotEqual(subjectText, subject)
        XCTAssertTrue(subjectText.contains(subject))
        XCTAssertEqual(subjectText.count, subject.count + 2)
    }

    func test_emailMessage_DidSet_SubjectLabelFormattedCorrectly_AttachmentsIconNotVisible() {
        let subject = "Message without attachment"
        let emailMessage = DataFactory.EmailSDK.generateEmailMessage(
            subject: subject
        )
        instanceUnderTest.emailMessage = emailMessage
        guard let subjectText = instanceUnderTest.subjectLabel?.text else {
            return XCTFail("Failed to get subject text")
        }
        // Can't string assert against a stringified system icon -
        // but the leading " " will not be present if the icon characters aren't
        XCTAssertEqual(subjectText, subject)
    }
}
