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
        let expectedResult = [
            EmailAddressPublicInfo(
                emailAddress: emailAddressInput,
                keyId: "keyId",
                publicKeyDetails: EmailAddressPublicKey(
                    publicKey: "publicKey",
                    keyFormat: .rsaPublicKey,
                    algorithm: "RSAEncryptionOAEPAESCBC"
                )
            )
        ]

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
        var expectedResult = [
            EmailAddressPublicInfo(
                emailAddress: emailAddress,
                keyId: "keyId",
                publicKeyDetails: EmailAddressPublicKey(
                    publicKey: "publicKey",
                    keyFormat: .rsaPublicKey,
                    algorithm: "RSAEncryptionOAEPAESCBC"
                )
            )
        ]
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

    // MARK: - Tests: Send Aliased Email Message

    func test_sendAliasedEmailMessage_CallsSendAliasedEmailMessage() async {
        let aliasId = "dummyAliasId"
        let aliasAddress = "alias@example.com"
        let subject = "dummySubject"
        let body = "dummyBody"
        let aliasedHeader = InternetMessageFormatHeader(
            from: EmailAddressAndName(address: aliasAddress),
            to: [],
            cc: [],
            bcc: [],
            subject: subject
        )
        let aliasedInput = SendEmailMessageInput(
            senderAliasId: aliasId,
            emailMessageHeader: aliasedHeader,
            body: body
        )
        testUtility.emailClient.sendEmailMessageViaAliasResult = SendEmailMessageResult(id: "sentAliasedId", createdAt: Date.now)
        _ = await instanceUnderTest.sendAliasedEmailMessage(aliasedInput)
        XCTAssertTrue(testUtility.emailClient.sendEmailMessageViaAliasCalled)
        XCTAssertEqual(testUtility.emailClient.sendEmailMessageViaAliasParameter?.senderAliasId, aliasId)
        XCTAssertEqual(testUtility.emailClient.sendEmailMessageViaAliasParameter?.body, body)
        XCTAssertEqual(testUtility.emailClient.sendEmailMessageViaAliasParameter?.emailMessageHeader.subject, subject)
        XCTAssertEqual(testUtility.emailClient.sendEmailMessageViaAliasParameter?.emailMessageHeader.from.address, aliasAddress)
    }

    func test_sendAliasedEmailMessage_DeletesDraftOnSuccess() async {
        let draftId = "dummyDraftId"
        let aliasId = "dummyAliasId"
        let aliasAddress = "alias@example.com"
        let subject = "dummySubject"
        let body = "dummyBody"
        let aliasedHeader = InternetMessageFormatHeader(
            from: EmailAddressAndName(address: aliasAddress),
            to: [],
            cc: [],
            bcc: [],
            subject: subject
        )
        let aliasedInput = SendEmailMessageInput(
            senderAliasId: aliasId,
            emailMessageHeader: aliasedHeader,
            body: body
        )
        testUtility.emailClient.sendEmailMessageViaAliasResult = SendEmailMessageResult(id: "sentAliasedId", createdAt: Date.now)
        instanceUnderTest.inputData = SendEmailInputData(
            draftEmailMessageId: draftId,
            to: "to@test.org",
            subject: subject,
            body: body
        )
        _ = await instanceUnderTest.sendAliasedEmailMessage(aliasedInput)
        XCTAssertTrue(testUtility.emailClient.sendEmailMessageViaAliasCalled)
        XCTAssertTrue(testUtility.emailClient.deleteDraftEmailMessagesCalled)
        XCTAssertEqual(testUtility.emailClient.deleteDraftEmailMessagesParameter?.ids, [draftId])
    }

    // MARK: - Tests: Load Email Alias

    func test_loadEmailAliases_FiltersbyRealAddressAndEnabledStatus() async {
        let currentAddress = instanceUnderTest.emailAddress.emailAddress
        let matchingAlias = DataFactory.EmailSDK.generateEmailAlias(
            realAddress: currentAddress,
            status: .enabled
        )
        let differentAddressAlias = DataFactory.EmailSDK.generateEmailAlias(
            realAddress: "other@example.com",
            status: .enabled
        )
        let disabledAlias = DataFactory.EmailSDK.generateEmailAlias(
            realAddress: currentAddress,
            status: .disabled
        )
        testUtility.emailClient.listEmailAliasesForOwnerResult = ListOutput<EmailAlias>(
            items: [matchingAlias, differentAddressAlias, disabledAlias]
        )
        await instanceUnderTest.loadEmailAliases()
        XCTAssertEqual(instanceUnderTest.emailAlias.count, 1)
        XCTAssertEqual(instanceUnderTest.emailAlias.first?.id, matchingAlias.id)
    }

    func test_loadEmailAliases_RestoresAliasSelectionFromDraft() async {
        let currentAddress = instanceUnderTest.emailAddress.emailAddress
        let alias = DataFactory.EmailSDK.generateEmailAlias(
            id: "savedAliasId",
            realAddress: currentAddress,
            status: .enabled
        )
        testUtility.emailClient.listEmailAliasesForOwnerResult = ListOutput<EmailAlias>(items: [alias])
        instanceUnderTest.inputData = SendEmailInputData(
            draftEmailMessageId: "draftId",
            subject: "test",
            body: "test",
            emailAliasId: "savedAliasId"
        )
        await instanceUnderTest.loadEmailAliases()
        XCTAssertNotNil(instanceUnderTest.selectedAlias)
        XCTAssertEqual(instanceUnderTest.selectedAlias?.id, "savedAliasId")
    }

    func test_loadEmailAliases_DoesNotRestoreAliasWhenAlreadySelected() async {
        let currentAddress = instanceUnderTest.emailAddress.emailAddress
        let alias1 = DataFactory.EmailSDK.generateEmailAlias(
            id: "alias1",
            realAddress: currentAddress,
            status: .enabled
        )
        let alias2 = DataFactory.EmailSDK.generateEmailAlias(
            id: "alias2",
            realAddress: currentAddress,
            status: .enabled
        )
        testUtility.emailClient.listEmailAliasesForOwnerResult = ListOutput<EmailAlias>(items: [alias1, alias2])
        instanceUnderTest.selectedAlias = alias1
        instanceUnderTest.inputData = SendEmailInputData(
            draftEmailMessageId: "draftId",
            subject: "test",
            body: "test",
            emailAliasId: "alias2"
        )
        await instanceUnderTest.loadEmailAliases()
        // Should keep the already-selected alias, not override with draft's alias
        XCTAssertEqual(instanceUnderTest.selectedAlias?.id, "alias1")
    }

    // MARK: - Tests: Save Draft with Email Alias

    func test_saveDraft_WithAliasSelected_PassesAliasIdToCreateInput() async {
        let currentAddress = instanceUnderTest.emailAddress.emailAddress
        let alias = DataFactory.EmailSDK.generateEmailAlias(
            id: "selectedAliasId",
            realAddress: currentAddress,
            status: .enabled
        )
        instanceUnderTest.selectedAlias = alias
        instanceUnderTest.formData = [
            SendEmailMessageViewController.InputField.to: "to@test.org",
            SendEmailMessageViewController.InputField.cc: "",
            SendEmailMessageViewController.InputField.bcc: "",
            SendEmailMessageViewController.InputField.subject: "Draft Subject",
            SendEmailMessageViewController.InputField.body: "Draft Body"
        ]
        await instanceUnderTest.saveDraft()
        XCTAssertTrue(testUtility.emailClient.createDraftEmailMessageCalled)
        XCTAssertEqual(testUtility.emailClient.createDraftEmailMessageParameter?.emailAliasId, "selectedAliasId")
    }

    func test_saveDraft_WithoutAlias_PassesNilAliasId() async {
        instanceUnderTest.selectedAlias = nil
        instanceUnderTest.formData = [
            SendEmailMessageViewController.InputField.to: "to@test.org",
            SendEmailMessageViewController.InputField.cc: "",
            SendEmailMessageViewController.InputField.bcc: "",
            SendEmailMessageViewController.InputField.subject: "Draft Subject",
            SendEmailMessageViewController.InputField.body: "Draft Body"
        ]
        await instanceUnderTest.saveDraft()
        XCTAssertTrue(testUtility.emailClient.createDraftEmailMessageCalled)
        XCTAssertNil(testUtility.emailClient.createDraftEmailMessageParameter?.emailAliasId)
    }

    func test_saveDraft_UpdateExistingDraftWithAlias_PassesAliasIdToUpdateInput() async {
        let currentAddress = instanceUnderTest.emailAddress.emailAddress
        let alias = DataFactory.EmailSDK.generateEmailAlias(
            id: "updatedAliasId",
            realAddress: currentAddress,
            status: .enabled
        )
        instanceUnderTest.selectedAlias = alias
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
        XCTAssertEqual(testUtility.emailClient.updateDraftEmailMessageParameter?.emailAliasId, "updatedAliasId")
        XCTAssertEqual(testUtility.emailClient.updateDraftEmailMessageParameter?.id, "existingDraftId")
    }

    // MARK: - Tests: Show Alias Picker

    func test_showAliasPicker_LoadsAliasWhenEmpty() async throws {
        let currentAddress = instanceUnderTest.emailAddress.emailAddress
        let alias = DataFactory.EmailSDK.generateEmailAlias(
            realAddress: currentAddress,
            status: .enabled
        )
        testUtility.emailClient.listEmailAliasesForOwnerResult = ListOutput<EmailAlias>(items: [alias])
        instanceUnderTest.emailAlias = []
        instanceUnderTest.showAliasPicker()
        try await waitForAsync()
        try await waitForAsync()
        XCTAssertTrue(testUtility.emailClient.listEmailAliasesForOwnerCalled)
        XCTAssertEqual(instanceUnderTest.emailAlias.count, 1)
    }

    // MARK: - Tests: Delete Draft with Email Alias

    @MainActor
    func test_deleteDraft_WithAliasSelected_PassesAliasIdToDeleteInput() async {
        let currentAddress = instanceUnderTest.emailAddress.emailAddress
        let alias = DataFactory.EmailSDK.generateEmailAlias(
            id: "deleteAliasId",
            realAddress: currentAddress,
            status: .enabled
        )
        instanceUnderTest.selectedAlias = alias
        instanceUnderTest.inputData = SendEmailInputData(
            draftEmailMessageId: "draftToDelete",
            subject: "test",
            body: "test"
        )
        await instanceUnderTest.deleteDraft()
        XCTAssertTrue(testUtility.emailClient.deleteDraftEmailMessagesCalled)
        XCTAssertEqual(testUtility.emailClient.deleteDraftEmailMessagesParameter?.ids, ["draftToDelete"])
        XCTAssertEqual(testUtility.emailClient.deleteDraftEmailMessagesParameter?.emailAliasId, "deleteAliasId")
    }

    @MainActor
    func test_deleteDraft_WithAliasFromInputData_PassesAliasIdToDeleteInput() async {
        instanceUnderTest.selectedAlias = nil
        instanceUnderTest.inputData = SendEmailInputData(
            draftEmailMessageId: "draftToDelete",
            subject: "test",
            body: "test",
            emailAliasId: "inputDataAliasId"
        )
        await instanceUnderTest.deleteDraft()
        XCTAssertTrue(testUtility.emailClient.deleteDraftEmailMessagesCalled)
        XCTAssertEqual(testUtility.emailClient.deleteDraftEmailMessagesParameter?.ids, ["draftToDelete"])
        XCTAssertEqual(testUtility.emailClient.deleteDraftEmailMessagesParameter?.emailAliasId, "inputDataAliasId")
    }

    @MainActor
    func test_deleteDraft_WithoutAlias_PassesNilAliasId() async {
        instanceUnderTest.selectedAlias = nil
        instanceUnderTest.inputData = SendEmailInputData(
            draftEmailMessageId: "draftToDelete",
            subject: "test",
            body: "test"
        )
        await instanceUnderTest.deleteDraft()
        XCTAssertTrue(testUtility.emailClient.deleteDraftEmailMessagesCalled)
        XCTAssertEqual(testUtility.emailClient.deleteDraftEmailMessagesParameter?.ids, ["draftToDelete"])
        XCTAssertNil(testUtility.emailClient.deleteDraftEmailMessagesParameter?.emailAliasId)
    }

    // MARK: - Tests: Cancel Schedule with Email Alias

    @MainActor
    func test_cancelSchedule_WithAliasSelected_PassesAliasIdToInput() async throws {
        let currentAddress = instanceUnderTest.emailAddress.emailAddress
        let alias = DataFactory.EmailSDK.generateEmailAlias(
            id: "scheduleAliasId",
            realAddress: currentAddress,
            status: .enabled
        )
        instanceUnderTest.selectedAlias = alias
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
        XCTAssertEqual(testUtility.emailClient.cancelScheduledDraftMessageParameter?.emailAliasId, "scheduleAliasId")
    }

}
