//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import SudoEmail
@testable import EmailExample

class SendEmailMessageViewControllerTests: XCTestCase {

    // MARK: - Properties

    var testUtility: EmailExampleTestUtility!
    var instanceUnderTest: SendEmailMessageViewController!

    override func setUp() {
        testUtility = EmailExampleTestUtility()
        instanceUnderTest = testUtility.storyBoard.instantiateViewController(identifier: "sendEmailMessage")
        instanceUnderTest.loadViewIfNeeded()
        instanceUnderTest.emailClient = testUtility.emailClient
        instanceUnderTest.emailAddress = DataFactory.EmailSDK.generateEmailAddress()
        testUtility.window.rootViewController = instanceUnderTest
        testUtility.window.makeKeyAndVisible()
    }

    override func tearDown() {
        testUtility.clearWindow()
    }

    func test_segueIdentifiers_containsNavigateToEmailMessageList() throws {
        XCTAssertSegueIdentifierExists(identifier: SendEmailMessageViewController.Segue.returnToEmailMessageList.rawValue, in: instanceUnderTest)
    }

    func test_addressesToArray() {
        let addresses = "hi@example.com,hello@example.com"
        let addressList = instanceUnderTest.addressesToArray(addresses)
        XCTAssertEqual(2, addressList.count)
        XCTAssertEqual(EmailAddressAndName(address: "hi@example.com"), addressList[0])
        XCTAssertEqual(EmailAddressAndName(address: "hello@example.com"), addressList[1])
    }

    func test_validateEmail_valid() {
        let validAddresses = ["hello@example.com", "hi+me@example.com", "yay@subdomain.example.com"]
        for address in validAddresses {
            XCTAssertTrue(instanceUnderTest.validateEmail(address))
        }
    }

    func test_validateEmailDisplayName_valid() {
        let validAddresses = [
            "Hello <hello@example.com>",
            "Hi Me <hi+me@example.com>",
            "Oi Oi Oi <yay@subdomain.example.com>"
        ]
        for address in validAddresses {
            XCTAssertTrue(instanceUnderTest.validateEmail(address))
        }
    }

    func test_validateEmail_invalid() {
        let invalidAddresses = ["invalidAddress", "almostvalid@address.com@a"]
        for address in invalidAddresses {
            XCTAssertFalse(instanceUnderTest.validateEmail(address))
        }
    }

    func test_validateEmailDisplayName_invalid() {
        let invalidAddresses = [
            "Hello hello@example.com",
            "Hi Me <hi+me@example.com",
            "Oi Oi Oi yay@subdomain.example.com>",
            "Dispaly Name Only",
            "GoodName BadAddress <almostvalid@address.com@a>"
        ]
        for address in invalidAddresses {
            XCTAssertFalse(instanceUnderTest.validateEmail(address), "\(address) should be invalid")
        }
    }

    func test_validateEmailAddressList_valid() {
        let validAddresses = "hello@example.com, hi+me@example.com,yay@subdomain.example.com"
        XCTAssertTrue(instanceUnderTest.validateEmailAddressList(addresses: validAddresses))
    }

    func test_validateEmailAddressList_invalid() {
        let invalidAddresses = "invalidAddress,almostvalid@address.com@a"
        XCTAssertFalse(instanceUnderTest.validateEmailAddressList(addresses: invalidAddresses))
    }

    @MainActor
    func test_validateEncryptedEmailAddresses_valid() async {
        let emailAddressInput = "valid_address@sudomail.com"
        let emailAddresses = [emailAddressInput]
        let expectedResult = [EmailAddressPublicInfo(emailAddress: emailAddressInput, keyId: "keyId", publicKey: "publicKey")]

        testUtility.emailClient.lookupEmailAddressesPublicInfoResult = expectedResult
        do {
            let result = try await instanceUnderTest.validateEncryptedEmailAddresses(emailAddressInput)
            XCTAssertTrue(result, "\(emailAddressInput) should be valid")

            // Assert email client method was correctly invoked
            XCTAssertTrue(testUtility.emailClient.lookupEmailAddressesPublicInfoCalled)
            XCTAssertEqual(emailAddresses, testUtility.emailClient.lookupEmailAddressesPublicInfoParameter?.emailAddresses)
            XCTAssertEqual(expectedResult, testUtility.emailClient.lookupEmailAddressesPublicInfoResult)
        } catch {
            XCTFail("\(emailAddressInput) should be valid, but returned invalid result")
        }
    }

    @MainActor
    func test_validateEncryptedEmailAddresses_invalid() async {
        let emailAddressInput = "invalid_address@sudomail.com"
        let emailAddresses = [emailAddressInput]
        let expectedResult: [EmailAddressPublicInfo] = []

        testUtility.emailClient.lookupEmailAddressesPublicInfoResult = expectedResult
        do {
            let result = try await instanceUnderTest.validateEncryptedEmailAddresses(emailAddressInput)
            XCTAssertFalse(result, "\(emailAddressInput) should be invalid")

            // Assert email client method was correctly invoked
            XCTAssertTrue(testUtility.emailClient.lookupEmailAddressesPublicInfoCalled)
            XCTAssertEqual(emailAddresses, testUtility.emailClient.lookupEmailAddressesPublicInfoParameter?.emailAddresses)
            XCTAssertEqual(expectedResult, testUtility.emailClient.lookupEmailAddressesPublicInfoResult)
        } catch {
            XCTFail("\(emailAddressInput) should be invalid, but returned valid result")
        }
    }

    @MainActor
    func test_send() async {
        let from = EmailAddressAndName(address: "email@address.com")
        let addressId = "dummyId"
        let subject = "dummySubject"
        let body = "dummyBody"
        let emailMessageHeader = InternetMessageFormatHeader(
            from: from,
            to: [],
            cc: [],
            bcc: [],
            subject: subject
        )
        let sendEmailMessageInput = SendEmailMessageInput(
            senderEmailAddressId: addressId,
            emailMessageHeader: emailMessageHeader,
            body: body
        )
        testUtility.emailClient.sendEmailMessageResult = SendEmailMessageResult(id: "sentEmailId", createdAt: Date.now)
        _ = await instanceUnderTest.sendEmailMessage(sendEmailMessageInput)
        XCTAssertTrue(testUtility.emailClient.sendEmailMessageCalled)
        XCTAssertEqual(testUtility.emailClient.sendEmailMessageParameters?.senderEmailAddressId, addressId)
        XCTAssertEqual(testUtility.emailClient.sendEmailMessageParameters?.body, body)
        XCTAssertEqual(testUtility.emailClient.sendEmailMessageParameters?.emailMessageHeader.subject, subject)
        XCTAssertEqual(testUtility.emailClient.sendEmailMessageParameters?.emailMessageHeader.from, from)
    }

    @MainActor
    func test_send_DraftDeletesDraft() async {
        let draftId = "dummyDraftId"
        let from = EmailAddressAndName(address: "email@address.com")
        let addressId = "dummyId"
        let subject = "dummySubject"
        let body = "dummyBody"
        let emailMessageHeader = InternetMessageFormatHeader(
            from: from,
            to: [],
            cc: [],
            bcc: [],
            subject: subject
        )
        let sendEmailMessageInput = SendEmailMessageInput(
            senderEmailAddressId: addressId,
            emailMessageHeader: emailMessageHeader,
            body: body
        )

        testUtility.emailClient.sendEmailMessageResult = SudoEmail.SendEmailMessageResult(id: "sentEmailId", createdAt: Date.now)
        instanceUnderTest.inputData = SendEmailInputData(
            draftEmailMessageId: draftId,
            to: "dummyTo",
            cc: "dummyCC",
            subject: subject,
            body: body
        )
        _ = await instanceUnderTest.sendEmailMessage(sendEmailMessageInput)
        XCTAssertTrue(testUtility.emailClient.sendEmailMessageCalled)
        XCTAssertEqual(testUtility.emailClient.sendEmailMessageParameters?.senderEmailAddressId, addressId)
        XCTAssertEqual(testUtility.emailClient.sendEmailMessageParameters?.body, body)
        XCTAssertEqual(testUtility.emailClient.sendEmailMessageParameters?.emailMessageHeader.subject, subject)
        XCTAssertEqual(testUtility.emailClient.sendEmailMessageParameters?.emailMessageHeader.from, from)
        XCTAssertTrue(testUtility.emailClient.deleteDraftEmailMessagesCalled)
        XCTAssertEqual(
            testUtility.emailClient.deleteDraftEmailMessagesParameter?.ids,
            [draftId]
        )
    }

    @MainActor
    func test_saveDraft_NoDataPresentsAlert() async throws {
        await instanceUnderTest.saveDraft()
        try await waitForAsync()
        let presentedViewController = testUtility.window.rootViewController?.presentedViewController
        XCTAssertNotNil(presentedViewController)
        XCTAssertEqual(presentedViewController?.title, "Error")
        XCTAssertTrue(presentedViewController is UIAlertController)
    }

    @MainActor
    func test_saveDraft_WithDataCreatesDraft() async {
        instanceUnderTest.formData = [
            SendEmailMessageViewController.InputField.to: "to@test.org",
            SendEmailMessageViewController.InputField.cc: "cc@test.org",
            SendEmailMessageViewController.InputField.bcc: "",
            SendEmailMessageViewController.InputField.subject: "Draft Subject",
            SendEmailMessageViewController.InputField.body: "Draft Body"
        ]
        await instanceUnderTest.saveDraft()
        XCTAssertTrue(testUtility.emailClient.createDraftEmailMessageCalled)
    }

    @MainActor
    func test_saveDraft_WithExistingDraftUpdatesDraft() async {
        instanceUnderTest.formData = [
            SendEmailMessageViewController.InputField.to: "to@test.org",
            SendEmailMessageViewController.InputField.cc: "cc@test.org",
            SendEmailMessageViewController.InputField.bcc: "",
            SendEmailMessageViewController.InputField.subject: "Draft Subject",
            SendEmailMessageViewController.InputField.body: "Draft Body"
        ]
        instanceUnderTest.inputData = SendEmailInputData(
            draftEmailMessageId: "dummyDraftId",
            to: "dummyTo",
            cc: "dummyCC",
            subject: "dummySubject",
            body: "dummyBody"
        )
        await instanceUnderTest.saveDraft()
        XCTAssertTrue(testUtility.emailClient.updateDraftEmailMessageCalled)
        XCTAssertFalse(testUtility.emailClient.createDraftEmailMessageCalled)
    }

    @MainActor
    func test_CancelSend_PresentsAlert() async {
        instanceUnderTest.cancelSend()
        await waitForAsyncNoFail()
        let presentedViewController = testUtility.window.rootViewController?.presentedViewController
        XCTAssertNotNil(presentedViewController)
        XCTAssertEqual(presentedViewController?.title, "Cancel Sending")
        XCTAssertTrue(presentedViewController is UIAlertController)
    }

    @MainActor
    func test_handleEncryptedIndicatorView_togglesViewForEncryptedEmailAddress() async {
        let emailAddress = "valid_address@sudomail.com"
        let emailAddresses = [emailAddress]
        var expectedResult = [EmailAddressPublicInfo(emailAddress: emailAddress, keyId: "keyId", publicKey: "publicKey")]
        testUtility.emailClient.lookupEmailAddressesPublicInfoResult = expectedResult

        // Set the result status for 'cc' field to true, to mock a successful outcome of
        // `handleEncryptedIndicatorView(emailAddress, "cc").
        // This is so we can also test here if the view appears as it should when multiple input fields
        // contain valid encrypted email address strings.
        instanceUnderTest.encryptedInputStatuses["cc"] = true

        do {
            _ = try await instanceUnderTest.handleEncryptedIndicatorView(emailAddress, "to")
            await waitForAsyncNoFail()

            // Assert email client method was correctly invoked
            XCTAssertTrue(testUtility.emailClient.lookupEmailAddressesPublicInfoCalled)
            XCTAssertEqual(emailAddresses, testUtility.emailClient.lookupEmailAddressesPublicInfoParameter?.emailAddresses)
            XCTAssertEqual(expectedResult, testUtility.emailClient.lookupEmailAddressesPublicInfoResult)
        } catch {
            XCTFail("\(emailAddress) should be valid, but returned invalid result")
        }

        // Assert UI is showing indicator view
        XCTAssertTrue(instanceUnderTest.encryptedIndicatorViewVisible)
        XCTAssertNotNil(instanceUnderTest.tableView.tableHeaderView, "Encrypted indicator view should be shown")
        await waitForAsyncNoFail()

        // Now set the result to empty to test that the view is hidden
        expectedResult = []
        testUtility.emailClient.lookupEmailAddressesPublicInfoResult = expectedResult
        do {
            _ = try await instanceUnderTest.handleEncryptedIndicatorView(emailAddress, "to")
            await waitForAsyncNoFail()

            // Assert email client method was correctly invoked
            XCTAssertTrue(testUtility.emailClient.lookupEmailAddressesPublicInfoCalled)
            XCTAssertEqual(expectedResult, testUtility.emailClient.lookupEmailAddressesPublicInfoResult)
        } catch {
            XCTFail("\(emailAddress) should be invalid, but returned valid result")
        }

        // Assert UI has hidden indicator view
        XCTAssertFalse(instanceUnderTest.encryptedIndicatorViewVisible)
        XCTAssertNil(instanceUnderTest.tableView.tableHeaderView, "Encrypted indicator view should not be shown")
    }

    func test_buildAttachment_createsAttachment() {
        guard let fileURL = Bundle(for: type(of: self)).url(forResource: "anonyome", withExtension: "png") else {
            return XCTFail("Failed to get file as bundle")
        }
        var expectedFileData: Data!
        do {
            expectedFileData = try Data(contentsOf: fileURL)
        } catch {
            XCTFail("Failed to parse file")
        }
        guard let emailAttachment = instanceUnderTest.buildAttachment(withURL: fileURL) else {
            return XCTFail("Failed to build email attachment attachment")
        }

        XCTAssertEqual(emailAttachment.filename, "anonyome.png")
        XCTAssertEqual(emailAttachment.data, expectedFileData)
    }

    func test_addAttachment_updatesAttachmentsSet() {
        guard let fileURL = Bundle(for: type(of: self)).url(forResource: "anonyome", withExtension: "png") else {
            return XCTFail("Failed to get file as bundle")
        }
        var expectedFileData: Data!
        do {
            expectedFileData = try Data(contentsOf: fileURL)
        } catch {
            XCTFail("Failed to parse file")
        }

        instanceUnderTest.addAttachment(fileURL: fileURL)
        if let emailAttachment = instanceUnderTest.attachments.first {
            XCTAssertEqual(emailAttachment.filename, "anonyome.png")
            XCTAssertEqual(emailAttachment.data, expectedFileData)
        } else {
            XCTFail("No attachments in list")
        }
    }

}
