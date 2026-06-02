//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import SudoEmail
@testable import EmailExample

@MainActor
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
        XCTAssertEqual("hi@example.com", addressList[0].address)
        XCTAssertEqual("hello@example.com", addressList[1].address)
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
        XCTAssertEqual(testUtility.emailClient.sendEmailMessageParameters?.emailMessageHeader.from.address, from.address)
        XCTAssertEqual(testUtility.emailClient.sendEmailMessageParameters?.replyingMessageId, nil)
        XCTAssertEqual(testUtility.emailClient.sendEmailMessageParameters?.forwardingMessageId, nil)
    }

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
        XCTAssertEqual(testUtility.emailClient.sendEmailMessageParameters?.emailMessageHeader.from.address, from.address)
        XCTAssertTrue(testUtility.emailClient.deleteDraftEmailMessagesCalled)
        XCTAssertEqual(
            testUtility.emailClient.deleteDraftEmailMessagesParameter?.ids,
            [draftId]
        )
    }

    func test_send_repliesToMessageWithId() async {
        let from = EmailAddressAndName(address: "email@address.com")
        let addressId = "dummyId"
        let subject = "dummySubject"
        let body = "dummyBody"
        let replyingMessageId = "dummyReplyingMessageId"
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
            body: body,
            replyingMessageId: replyingMessageId
        )
        testUtility.emailClient.sendEmailMessageResult = SendEmailMessageResult(id: "sentEmailId", createdAt: Date.now)
        _ = await instanceUnderTest.sendEmailMessage(sendEmailMessageInput)
        XCTAssertTrue(testUtility.emailClient.sendEmailMessageCalled)
        XCTAssertEqual(testUtility.emailClient.sendEmailMessageParameters?.senderEmailAddressId, addressId)
        XCTAssertEqual(testUtility.emailClient.sendEmailMessageParameters?.body, body)
        XCTAssertEqual(testUtility.emailClient.sendEmailMessageParameters?.emailMessageHeader.subject, subject)
        XCTAssertEqual(testUtility.emailClient.sendEmailMessageParameters?.emailMessageHeader.from.address, from.address)
        XCTAssertEqual(testUtility.emailClient.sendEmailMessageParameters?.replyingMessageId, replyingMessageId)
    }

    func test_send_forwardsMessageWithId() async {
        let from = EmailAddressAndName(address: "email@address.com")
        let addressId = "dummyId"
        let subject = "dummySubject"
        let body = "dummyBody"
        let forwardingMessageId = "dummyForwardingMessageId"
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
            body: body,
            forwardingMessageId: forwardingMessageId
        )
        testUtility.emailClient.sendEmailMessageResult = SendEmailMessageResult(id: "sentEmailId", createdAt: Date.now)
        _ = await instanceUnderTest.sendEmailMessage(sendEmailMessageInput)
        XCTAssertTrue(testUtility.emailClient.sendEmailMessageCalled)
        XCTAssertEqual(testUtility.emailClient.sendEmailMessageParameters?.senderEmailAddressId, addressId)
        XCTAssertEqual(testUtility.emailClient.sendEmailMessageParameters?.body, body)
        XCTAssertEqual(testUtility.emailClient.sendEmailMessageParameters?.emailMessageHeader.subject, subject)
        XCTAssertEqual(testUtility.emailClient.sendEmailMessageParameters?.emailMessageHeader.from.address, from.address)
        XCTAssertEqual(testUtility.emailClient.sendEmailMessageParameters?.forwardingMessageId, forwardingMessageId)
    }

    func test_saveDraft_NoDataPresentsAlert() async throws {
        await instanceUnderTest.saveDraft()
        try await waitForAsync()
        let presentedViewController = testUtility.window.rootViewController?.presentedViewController
        XCTAssertNotNil(presentedViewController)
        XCTAssertEqual(presentedViewController?.title, "Error")
        XCTAssertTrue(presentedViewController is UIAlertController)
    }

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

    func test_CancelSend_PresentsAlert() async {
        instanceUnderTest.cancelSend()
        await waitForAsyncNoFail()
        let presentedViewController = testUtility.window.rootViewController?.presentedViewController
        XCTAssertNotNil(presentedViewController)
        XCTAssertEqual(presentedViewController?.title, "Cancel Sending")
        XCTAssertTrue(presentedViewController is UIAlertController)
    }

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

    // MARK: - Tests: Send Masked Email Message

    func test_sendMaskedEmailMessage_CallsSendMaskedEmailMessage() async {
        let maskId = "dummyMaskId"
        let maskAddress = "mask@example.com"
        let subject = "dummySubject"
        let body = "dummyBody"
        let maskedHeader = InternetMessageFormatHeader(
            from: EmailAddressAndName(address: maskAddress),
            to: [],
            cc: [],
            bcc: [],
            subject: subject
        )
        let maskedInput = SendEmailMessageInput(
            senderMaskId: maskId,
            emailMessageHeader: maskedHeader,
            body: body
        )
        testUtility.emailClient.sendMaskedEmailMessageResult = SendEmailMessageResult(id: "sentMaskedId", createdAt: Date.now)
        _ = await instanceUnderTest.sendMaskedEmailMessage(maskedInput)
        XCTAssertTrue(testUtility.emailClient.sendMaskedEmailMessageCalled)
        XCTAssertEqual(testUtility.emailClient.sendMaskedEmailMessageParameter?.senderMaskId, maskId)
        XCTAssertEqual(testUtility.emailClient.sendMaskedEmailMessageParameter?.body, body)
        XCTAssertEqual(testUtility.emailClient.sendMaskedEmailMessageParameter?.emailMessageHeader.subject, subject)
        XCTAssertEqual(testUtility.emailClient.sendMaskedEmailMessageParameter?.emailMessageHeader.from.address, maskAddress)
    }

    func test_sendMaskedEmailMessage_DeletesDraftOnSuccess() async {
        let draftId = "dummyDraftId"
        let maskId = "dummyMaskId"
        let maskAddress = "mask@example.com"
        let subject = "dummySubject"
        let body = "dummyBody"
        let maskedHeader = InternetMessageFormatHeader(
            from: EmailAddressAndName(address: maskAddress),
            to: [],
            cc: [],
            bcc: [],
            subject: subject
        )
        let maskedInput = SendEmailMessageInput(
            senderMaskId: maskId,
            emailMessageHeader: maskedHeader,
            body: body
        )
        testUtility.emailClient.sendMaskedEmailMessageResult = SendEmailMessageResult(id: "sentMaskedId", createdAt: Date.now)
        instanceUnderTest.inputData = SendEmailInputData(
            draftEmailMessageId: draftId,
            to: "to@test.org",
            subject: subject,
            body: body
        )
        _ = await instanceUnderTest.sendMaskedEmailMessage(maskedInput)
        XCTAssertTrue(testUtility.emailClient.sendMaskedEmailMessageCalled)
        XCTAssertTrue(testUtility.emailClient.deleteDraftEmailMessagesCalled)
        XCTAssertEqual(testUtility.emailClient.deleteDraftEmailMessagesParameter?.ids, [draftId])
    }

    // MARK: - Tests: Load Email Masks

    func test_loadEmailMasks_FiltersbyRealAddressAndEnabledStatus() async {
        let currentAddress = instanceUnderTest.emailAddress.emailAddress
        let matchingMask = DataFactory.EmailSDK.generateEmailMask(
            realAddress: currentAddress,
            status: .enabled
        )
        let differentAddressMask = DataFactory.EmailSDK.generateEmailMask(
            realAddress: "other@example.com",
            status: .enabled
        )
        let disabledMask = DataFactory.EmailSDK.generateEmailMask(
            realAddress: currentAddress,
            status: .disabled
        )
        testUtility.emailClient.listEmailMasksForOwnerResult = ListOutput<EmailMask>(
            items: [matchingMask, differentAddressMask, disabledMask]
        )
        await instanceUnderTest.loadEmailMasks()
        XCTAssertEqual(instanceUnderTest.emailMasks.count, 1)
        XCTAssertEqual(instanceUnderTest.emailMasks.first?.id, matchingMask.id)
    }

    func test_loadEmailMasks_RestoresMaskSelectionFromDraft() async {
        let currentAddress = instanceUnderTest.emailAddress.emailAddress
        let mask = DataFactory.EmailSDK.generateEmailMask(
            id: "savedMaskId",
            realAddress: currentAddress,
            status: .enabled
        )
        testUtility.emailClient.listEmailMasksForOwnerResult = ListOutput<EmailMask>(items: [mask])
        instanceUnderTest.inputData = SendEmailInputData(
            draftEmailMessageId: "draftId",
            subject: "test",
            body: "test",
            emailMaskId: "savedMaskId"
        )
        await instanceUnderTest.loadEmailMasks()
        XCTAssertNotNil(instanceUnderTest.selectedMask)
        XCTAssertEqual(instanceUnderTest.selectedMask?.id, "savedMaskId")
    }

    func test_loadEmailMasks_DoesNotRestoreMaskWhenAlreadySelected() async {
        let currentAddress = instanceUnderTest.emailAddress.emailAddress
        let mask1 = DataFactory.EmailSDK.generateEmailMask(
            id: "mask1",
            realAddress: currentAddress,
            status: .enabled
        )
        let mask2 = DataFactory.EmailSDK.generateEmailMask(
            id: "mask2",
            realAddress: currentAddress,
            status: .enabled
        )
        testUtility.emailClient.listEmailMasksForOwnerResult = ListOutput<EmailMask>(items: [mask1, mask2])
        instanceUnderTest.selectedMask = mask1
        instanceUnderTest.inputData = SendEmailInputData(
            draftEmailMessageId: "draftId",
            subject: "test",
            body: "test",
            emailMaskId: "mask2"
        )
        await instanceUnderTest.loadEmailMasks()
        // Should keep the already-selected mask, not override with draft's mask
        XCTAssertEqual(instanceUnderTest.selectedMask?.id, "mask1")
    }

    // MARK: - Tests: Save Draft with Email Mask

    func test_saveDraft_WithMaskSelected_PassesMaskIdToCreateInput() async {
        let currentAddress = instanceUnderTest.emailAddress.emailAddress
        let mask = DataFactory.EmailSDK.generateEmailMask(
            id: "selectedMaskId",
            realAddress: currentAddress,
            status: .enabled
        )
        instanceUnderTest.selectedMask = mask
        instanceUnderTest.formData = [
            SendEmailMessageViewController.InputField.to: "to@test.org",
            SendEmailMessageViewController.InputField.cc: "",
            SendEmailMessageViewController.InputField.bcc: "",
            SendEmailMessageViewController.InputField.subject: "Draft Subject",
            SendEmailMessageViewController.InputField.body: "Draft Body"
        ]
        await instanceUnderTest.saveDraft()
        XCTAssertTrue(testUtility.emailClient.createDraftEmailMessageCalled)
        XCTAssertEqual(testUtility.emailClient.createDraftEmailMessageParameter?.emailMaskId, "selectedMaskId")
    }

    func test_saveDraft_WithoutMask_PassesNilMaskId() async {
        instanceUnderTest.selectedMask = nil
        instanceUnderTest.formData = [
            SendEmailMessageViewController.InputField.to: "to@test.org",
            SendEmailMessageViewController.InputField.cc: "",
            SendEmailMessageViewController.InputField.bcc: "",
            SendEmailMessageViewController.InputField.subject: "Draft Subject",
            SendEmailMessageViewController.InputField.body: "Draft Body"
        ]
        await instanceUnderTest.saveDraft()
        XCTAssertTrue(testUtility.emailClient.createDraftEmailMessageCalled)
        XCTAssertNil(testUtility.emailClient.createDraftEmailMessageParameter?.emailMaskId)
    }

    func test_saveDraft_UpdateExistingDraftWithMask_PassesMaskIdToUpdateInput() async {
        let currentAddress = instanceUnderTest.emailAddress.emailAddress
        let mask = DataFactory.EmailSDK.generateEmailMask(
            id: "updatedMaskId",
            realAddress: currentAddress,
            status: .enabled
        )
        instanceUnderTest.selectedMask = mask
        instanceUnderTest.inputData = SendEmailInputData(
            draftEmailMessageId: "existingDraftId",
            to: "to@test.org",
            subject: "Original Subject",
            body: "Original Body"
        )
        instanceUnderTest.formData = [
            SendEmailMessageViewController.InputField.to: "to@test.org",
            SendEmailMessageViewController.InputField.cc: "",
            SendEmailMessageViewController.InputField.bcc: "",
            SendEmailMessageViewController.InputField.subject: "Updated Subject",
            SendEmailMessageViewController.InputField.body: "Updated Body"
        ]
        await instanceUnderTest.saveDraft()
        XCTAssertTrue(testUtility.emailClient.updateDraftEmailMessageCalled)
        XCTAssertFalse(testUtility.emailClient.createDraftEmailMessageCalled)
        XCTAssertEqual(testUtility.emailClient.updateDraftEmailMessageParameter?.emailMaskId, "updatedMaskId")
        XCTAssertEqual(testUtility.emailClient.updateDraftEmailMessageParameter?.id, "existingDraftId")
    }

    // MARK: - Tests: Show Mask Picker

    func test_showMaskPicker_LoadsMasksWhenEmpty() async throws {
        let currentAddress = instanceUnderTest.emailAddress.emailAddress
        let mask = DataFactory.EmailSDK.generateEmailMask(
            realAddress: currentAddress,
            status: .enabled
        )
        testUtility.emailClient.listEmailMasksForOwnerResult = ListOutput<EmailMask>(items: [mask])
        instanceUnderTest.emailMasks = []
        instanceUnderTest.showMaskPicker()
        try await waitForAsync()
        try await waitForAsync()
        XCTAssertTrue(testUtility.emailClient.listEmailMasksForOwnerCalled)
        XCTAssertEqual(instanceUnderTest.emailMasks.count, 1)
    }

    // MARK: - Tests: Delete Draft with Email Mask

    @MainActor
    func test_deleteDraft_WithMaskSelected_PassesMaskIdToDeleteInput() async {
        let currentAddress = instanceUnderTest.emailAddress.emailAddress
        let mask = DataFactory.EmailSDK.generateEmailMask(
            id: "deleteMaskId",
            realAddress: currentAddress,
            status: .enabled
        )
        instanceUnderTest.selectedMask = mask
        instanceUnderTest.inputData = SendEmailInputData(
            draftEmailMessageId: "draftToDelete",
            subject: "test",
            body: "test"
        )
        await instanceUnderTest.deleteDraft()
        XCTAssertTrue(testUtility.emailClient.deleteDraftEmailMessagesCalled)
        XCTAssertEqual(testUtility.emailClient.deleteDraftEmailMessagesParameter?.ids, ["draftToDelete"])
        XCTAssertEqual(testUtility.emailClient.deleteDraftEmailMessagesParameter?.emailMaskId, "deleteMaskId")
    }

    @MainActor
    func test_deleteDraft_WithMaskFromInputData_PassesMaskIdToDeleteInput() async {
        instanceUnderTest.selectedMask = nil
        instanceUnderTest.inputData = SendEmailInputData(
            draftEmailMessageId: "draftToDelete",
            subject: "test",
            body: "test",
            emailMaskId: "inputDataMaskId"
        )
        await instanceUnderTest.deleteDraft()
        XCTAssertTrue(testUtility.emailClient.deleteDraftEmailMessagesCalled)
        XCTAssertEqual(testUtility.emailClient.deleteDraftEmailMessagesParameter?.ids, ["draftToDelete"])
        XCTAssertEqual(testUtility.emailClient.deleteDraftEmailMessagesParameter?.emailMaskId, "inputDataMaskId")
    }

    @MainActor
    func test_deleteDraft_WithoutMask_PassesNilMaskId() async {
        instanceUnderTest.selectedMask = nil
        instanceUnderTest.inputData = SendEmailInputData(
            draftEmailMessageId: "draftToDelete",
            subject: "test",
            body: "test"
        )
        await instanceUnderTest.deleteDraft()
        XCTAssertTrue(testUtility.emailClient.deleteDraftEmailMessagesCalled)
        XCTAssertEqual(testUtility.emailClient.deleteDraftEmailMessagesParameter?.ids, ["draftToDelete"])
        XCTAssertNil(testUtility.emailClient.deleteDraftEmailMessagesParameter?.emailMaskId)
    }

    // MARK: - Tests: Cancel Schedule with Email Mask

    @MainActor
    func test_cancelSchedule_WithMaskSelected_PassesMaskIdToInput() async throws {
        let currentAddress = instanceUnderTest.emailAddress.emailAddress
        let mask = DataFactory.EmailSDK.generateEmailMask(
            id: "scheduleMaskId",
            realAddress: currentAddress,
            status: .enabled
        )
        instanceUnderTest.selectedMask = mask
        instanceUnderTest.inputData = SendEmailInputData(
            draftEmailMessageId: "scheduledDraftId",
            subject: "test",
            body: "test",
            scheduledAt: Date().addingTimeInterval(3600)
        )
        testUtility.emailClient.cancelScheduledDraftMessageResult = "scheduledDraftId"
        instanceUnderTest.didTapCancelScheduleSendButton()
        try await waitForAsync()
        // Tap "Cancel" action in the alert to trigger the cancel
        if let alert = instanceUnderTest.presentedViewController as? UIAlertController,
           let cancelAction = alert.actions.first(where: { $0.title == "Cancel" }) {
            // Simulate tapping the action
            let handler = cancelAction.value(forKey: "handler")
            typealias ActionHandler = @convention(block) (UIAlertAction) -> Void
            if let handlerBlock = handler {
                let blockPtr = unsafeBitCast(handlerBlock as AnyObject, to: ActionHandler.self)
                blockPtr(cancelAction)
            }
        }
        try await waitForAsync()
        try await waitForAsync()
        XCTAssertTrue(testUtility.emailClient.cancelScheduledDraftMessageCalled)
        XCTAssertEqual(testUtility.emailClient.cancelScheduledDraftMessageParameter?.id, "scheduledDraftId")
        XCTAssertEqual(testUtility.emailClient.cancelScheduledDraftMessageParameter?.emailMaskId, "scheduleMaskId")
    }

}
