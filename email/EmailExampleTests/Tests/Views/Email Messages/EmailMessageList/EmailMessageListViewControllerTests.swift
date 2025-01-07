//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import UIKit
import SudoEmail
@testable import EmailExample

class EmailMessageListViewControllerTests: XCTestCase {

    // MARK: - Properties

    var testUtility: EmailExampleTestUtility!
    var instanceUnderTest: EmailMessageListViewController!

    var tableView: UITableViewMockSpy!

    var folderSwitcherView: FolderSwitcherView!

    // MARK: - Lifecycle

    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        testUtility = EmailExampleTestUtility()
        let message = DataFactory.EmailSDK.generateEmailMessage()
        let successResult = ListAPIResult<EmailMessage, PartialEmailMessage>.ListSuccessResult(
            items: [message]
        )
        testUtility.emailClient.listEmailMessagesForEmailFolderIdResult = ListAPIResult.success(successResult)
        instanceUnderTest = testUtility.storyBoard.instantiateViewController(identifier: "emailMessageList")
        instanceUnderTest.emailAddress = DataFactory.EmailSDK.generateEmailAddress()
        instanceUnderTest.loadViewIfNeeded()
        testUtility.window.rootViewController = instanceUnderTest
        testUtility.window.makeKeyAndVisible()
        await waitForAsyncNoFail()
        // Setup mocks and inject into instance.
        tableView = UITableViewMockSpy()
        instanceUnderTest.tableView = tableView
        folderSwitcherView = FolderSwitcherView()
        instanceUnderTest.folderNameSwitcher = folderSwitcherView
    }

    override func tearDown() {
        testUtility.clearWindow()
        testUtility = nil
        super.tearDown()
    }

    // MARK: - Helpers

    func waitForAlertController() async -> UIAlertController? {
        for _ in 0...5 {
            await waitForAsyncNoFail()
            guard let presentedAlertController = await instanceUnderTest.presentedViewController as? UIAlertController else {
                continue
            }
            return presentedAlertController
        }
        return nil
    }

    // MARK: - Tests: Lifecycle

    @MainActor
    func test_viewWillAppear_PresentErrorOnBadEmailAddress() async {
        instanceUnderTest.emailAddress = nil
        instanceUnderTest.viewWillAppear(true)
        await waitForAsyncNoFail()
        guard let presentedViewController = testUtility.window.rootViewController?.presentedViewController else {
            return XCTFail("No present view found")
        }
        XCTAssertTrue(presentedViewController is UIAlertController)
    }

    @MainActor
    func test_viewWillAppear_SubscribesToEmailCreatedAndDeleted() async {
        instanceUnderTest.emailAddress = DataFactory.EmailSDK.generateEmailAddress()
        instanceUnderTest.viewWillAppear(true)
        await waitForAsyncNoFail()
        XCTAssertTrue(testUtility.emailClient.subscribeToEmailMessageCreatedCalled)
        XCTAssertTrue(testUtility.emailClient.subscribeToEmailMessageDeletedCalled)
    }

    @MainActor
    func test_viewWillAppear_LoadsMessages() async {
        instanceUnderTest.emailAddress = DataFactory.EmailSDK.generateEmailAddress()
        instanceUnderTest.viewWillAppear(true)
        XCTAssertTrue(testUtility.emailClient.listEmailMessagesForEmailFolderIdCalled)
    }

    func test_viewWillDisappear_UnsubscribesToAllSubscriptions() {
        let createdToken = MockSubscriptionToken()
        let deletedToken = MockSubscriptionToken()
        instanceUnderTest.allEmailMessagesCreatedSubscriptionToken = createdToken
        instanceUnderTest.allEmailMessagesDeletedSubscriptionToken = deletedToken
        instanceUnderTest.viewWillDisappear(true)
        XCTAssertEqual(createdToken.cancelCallCount, 1)
        XCTAssertEqual(deletedToken.cancelCallCount, 1)
    }

    // MARK: - Tests: Operations

    @MainActor
    func test_deleteEmailMessage_CallsClient() async {
        testUtility.emailClient.deleteEmailMessageResult = SudoEmail.DeleteEmailMessageSuccessResult(id: "dummyId")
        do {
            _ = try await instanceUnderTest.deleteEmailMessage("dummyId")
        } catch {
            XCTFail("unexpected error \(error)")
        }
        XCTAssertTrue(testUtility.emailClient.deleteEmailMessageCalled)
        XCTAssertEqual(testUtility.emailClient.deleteEmailMessageParameter, "dummyId")
    }

    @MainActor
    func test_subscribeToAllEmailMessagesCreated() async throws {
        try await instanceUnderTest.subscribeToAllEmailMessagesCreated()
        XCTAssertTrue(testUtility.emailClient.subscribeToEmailMessageCreatedCalled)
        XCTAssertNotNil(instanceUnderTest.allEmailMessagesCreatedSubscriptionToken)
    }

    @MainActor
    func test_subscribeToAllEmailMessagesDeleted() async throws {
        try await instanceUnderTest.subscribeToAllEmailMessagesDeleted()
        XCTAssertTrue(testUtility.emailClient.subscribeToEmailMessageDeletedCalled)
        XCTAssertNotNil(instanceUnderTest.allEmailMessagesDeletedSubscriptionToken)
    }

    func test_unsubscribeToAllSubscriptions_UnsubscribesFromEmailMessageCreated() {
        let token = MockSubscriptionToken()
        instanceUnderTest.allEmailMessagesCreatedSubscriptionToken = token
        instanceUnderTest.unsubscribeToAllSubscriptions()
        XCTAssertEqual(token.cancelCallCount, 1)
    }

    func test_unsubscribeToAllSubscriptions_UnsubscribesFromEmailMessageDeleted() {
        let token = MockSubscriptionToken()
            instanceUnderTest.allEmailMessagesDeletedSubscriptionToken = token
            instanceUnderTest.unsubscribeToAllSubscriptions()
            XCTAssertEqual(token.cancelCallCount, 1)
    }

    // MARK: - Tests: Helpers

    @MainActor
    func test_configureTableView_RegistersEmailMessageCellAsNib() async {
        await waitForAsyncNoFail()
        instanceUnderTest.configureTableView()
        XCTAssertEqual(tableView.registerNibCallCount, 2)
        let identifiers = tableView.registerNibProperties.map { $0.identifier }
        XCTAssertTrue(identifiers.contains("emailMessageCell"))
        guard tableView.registerNibProperties.map({$0.nib}).first != nil else {
            return XCTFail("Failed to load nib")
        }
    }

    func test_configureTableView_SetsUIViewForFooter() {
        instanceUnderTest.configureTableView()
        XCTAssertNotNil(tableView.tableFooterView)
    }

    func test_loadCacheEmailMessagesAndFetchRemote_CallsCacheAndRemote() async {
        await waitForAsyncNoFail()
        await instanceUnderTest.loadCacheEmailMessagesAndFetchRemote()
        await waitForAsyncNoFail()
        let parameterCount = testUtility.emailClient.listEmailMessagesForEmailFolderIdParameters.count
        // 2nd last parameter
        XCTAssertEqual(testUtility.emailClient.listEmailMessagesForEmailFolderIdParameters[parameterCount - 2].cachePolicy, .cacheOnly)
        // last parameter
        XCTAssertEqual(testUtility.emailClient.listEmailMessagesForEmailFolderIdParameters[parameterCount - 1].cachePolicy, .remoteOnly)
    }

    @MainActor
    func test_loadCacheEmailMessagesAndFetchRemote_Drafts_CallsListDraftsOnly() async {
        instanceUnderTest.folderNameSwitcher.currentFolder = .special(.drafts)
        let listMessagesCalledCount = testUtility.emailClient.listEmailMessagesForEmailFolderIdCalledCount
        await instanceUnderTest.loadCacheEmailMessagesAndFetchRemote()
        XCTAssertTrue(testUtility.emailClient.listDraftEmailMessageMetadataForEmailAddressIdCalled)
        XCTAssertTrue(testUtility.emailClient.getDraftEmailMessageCalled)
        XCTAssertEqual(
            listMessagesCalledCount,
            testUtility.emailClient.listEmailMessagesForEmailFolderIdCalledCount
        )
    }

    func test_validateViewInputEmailAddress_ReturnsFalseIfEmailAddressIsNil() {
        instanceUnderTest.emailAddress = nil
        XCTAssertFalse(instanceUnderTest.validateViewInputEmailAddress())
    }

    func test_validateViewInputEmailAddress_ReturnsFalseIfEmailAddressIsEmpty() {
        let emailAddress = DataFactory.EmailSDK.generateEmailAddress(address: "")
        instanceUnderTest.emailAddress = emailAddress
        XCTAssertFalse(instanceUnderTest.validateViewInputEmailAddress())
    }

    func test_validateViewInputEmailAddress_ReturnsTrueIfEmailAddressExists() {
        let emailAddress = DataFactory.EmailSDK.generateEmailAddress(address: "test@example.com")
        instanceUnderTest.emailAddress = emailAddress
        XCTAssertTrue(instanceUnderTest.validateViewInputEmailAddress())
    }

    func test_filterEmailMessages_FiltersToContainsAddress() {
        let toAddress = DataFactory.EmailSDK.randomEmailAddress()
        let emailMessages = [
            DataFactory.EmailSDK.generateEmailMessage(toAddresses: [.init(address: toAddress)]),
            DataFactory.EmailSDK.generateEmailMessage(),
            DataFactory.EmailSDK.generateEmailMessage()
        ]
        let result = instanceUnderTest.filterEmailMessages(emailMessages, withEmailAddress: toAddress)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.to.first?.address, toAddress)
    }

    func test_filterEmailMessages_FiltersFromContainsAddress() {
        let fromAddress = DataFactory.EmailSDK.randomEmailAddress()
        let emailMessages = [
            DataFactory.EmailSDK.generateEmailMessage(fromAddresses: [.init(address: fromAddress)]),
            DataFactory.EmailSDK.generateEmailMessage(),
            DataFactory.EmailSDK.generateEmailMessage()
        ]
        let result = instanceUnderTest.filterEmailMessages(emailMessages, withEmailAddress: fromAddress)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.from.first?.address, fromAddress)
    }

    func test_filterEmailMessages_FiltersCcContainsAddress() {
        let ccAddress = DataFactory.EmailSDK.randomEmailAddress()
        let emailMessages = [
            DataFactory.EmailSDK.generateEmailMessage(ccAddresses: [.init(address: ccAddress)]),
            DataFactory.EmailSDK.generateEmailMessage(),
            DataFactory.EmailSDK.generateEmailMessage()
        ]
        let result = instanceUnderTest.filterEmailMessages(emailMessages, withEmailAddress: ccAddress)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.cc.first?.address, ccAddress)
    }

    func test_filterEmailMessages_FiltersBccContainsAddress() {
        let bccAddress = DataFactory.EmailSDK.randomEmailAddress()
        let emailMessages = [
            DataFactory.EmailSDK.generateEmailMessage(bccAddresses: [.init(address: bccAddress)]),
            DataFactory.EmailSDK.generateEmailMessage(),
            DataFactory.EmailSDK.generateEmailMessage()
        ]
        let result = instanceUnderTest.filterEmailMessages(emailMessages, withEmailAddress: bccAddress)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.bcc.first?.address, bccAddress)
    }

    func test_filterEmailMessages_FiltersAreRead() {
        var emailMessages = [
            DataFactory.EmailSDK.generateEmailMessage(),
            DataFactory.EmailSDK.generateEmailMessage(),
            DataFactory.EmailSDK.generateEmailMessage(),
            DataFactory.EmailSDK.generateEmailMessage(),
            DataFactory.EmailSDK.generateEmailMessage()
        ]
        let email = "test@example.com"
        emailMessages[1].to[0] = EmailAddressAndName(address: email, displayName: "To Display")
        emailMessages[2].cc[0] = EmailAddressAndName(address: email, displayName: "Cc Display")
        emailMessages[3].bcc[0] = EmailAddressAndName(address: email, displayName: "Bcc Display")
        let result = instanceUnderTest.filterEmailMessages(emailMessages, withEmailAddress: email)
        XCTAssertEqual(result.count, 3)
        XCTAssertFalse(result.contains(emailMessages[0]))
        XCTAssertTrue(result.contains(emailMessages[1]))
        XCTAssertTrue(result.contains(emailMessages[2]))
        XCTAssertTrue(result.contains(emailMessages[3]))
        XCTAssertFalse(result.contains(emailMessages[4]))
    }

    @MainActor
    func test_deleteEmailMessage_ForIndexPath_FromTrash_DeletesMessage() async {
        testUtility.emailClient.deleteEmailMessageResult = SudoEmail.DeleteEmailMessageSuccessResult(id: "dummyId")
        instanceUnderTest.folderNameSwitcher.currentFolder = .standard(.trash)
        instanceUnderTest.configureTableView()
        let emailMessage = DataFactory.EmailSDK.generateEmailMessage()
        instanceUnderTest.emailMessages.append(emailMessage)
        let emailMessagesCount = instanceUnderTest.emailMessages.count
        let successResult = ListAPIResult<EmailMessage, PartialEmailMessage>.ListSuccessResult(
            items: []
        )
        testUtility.emailClient.listEmailMessagesForEmailFolderIdResult = ListAPIResult.success(successResult)
        _ = await instanceUnderTest.deleteEmailMessage(forIndexPath: IndexPath(row: 0, section: 0))
        await waitForAsyncNoFail()
        XCTAssertEqual(instanceUnderTest.emailMessages.count, emailMessagesCount - 1)
    }

    @MainActor
    func test_deleteEmailMessage_ForIndexPath_FromTrash_ClientDeleteCalled() async {
        instanceUnderTest.configureTableView()
        instanceUnderTest.folderNameSwitcher.currentFolder = .standard(.trash)
        let emailMessage = DataFactory.EmailSDK.generateEmailMessage()
        testUtility.emailClient.deleteEmailMessageResult = SudoEmail.DeleteEmailMessageSuccessResult(id: "dummyId")
        instanceUnderTest.emailMessages.append(emailMessage)
        _ = await instanceUnderTest.deleteEmailMessage(
            forIndexPath: IndexPath(row: instanceUnderTest.emailMessages.count - 1, section: 0)
        )
        await waitForAsyncNoFail()
        XCTAssertTrue(testUtility.emailClient.deleteEmailMessageCalled)
        XCTAssertEqual(
            testUtility.emailClient.deleteEmailMessageParameter,
            emailMessage.id
        )
    }

    @MainActor
    func test_deleteEmailMessage_ForIndexPath_FromTrash_OnSuccessPerformsAList() async {
        instanceUnderTest.folderNameSwitcher.currentFolder = .standard(.trash)
        instanceUnderTest.configureTableView()
        let emailMessage = DataFactory.EmailSDK.generateEmailMessage()
        instanceUnderTest.emailMessages.append(emailMessage)
        testUtility.emailClient.deleteEmailMessageResult = SudoEmail.DeleteEmailMessageSuccessResult(id: "dummyId")
        _ = await instanceUnderTest.deleteEmailMessage(forIndexPath: IndexPath(row: 0, section: 0))
        XCTAssertEqual(testUtility.emailClient.listEmailMessagesForEmailFolderIdCalledCount, 3)
        XCTAssertEqual(
            testUtility.emailClient.listEmailMessagesForEmailFolderIdParameters.first?.cachePolicy,
            .cacheOnly
        )
    }

    @MainActor
    func test_deleteEmailMessage_ForIndexPath_FromTrash_OnSuccessCompletionReturnsTrue() async {
        instanceUnderTest.folderNameSwitcher.currentFolder = .standard(.trash)
        instanceUnderTest.configureTableView()
        let emailMessage = DataFactory.EmailSDK.generateEmailMessage()
        instanceUnderTest.emailMessages.append(emailMessage)
        testUtility.emailClient.deleteEmailMessageResult = SudoEmail.DeleteEmailMessageSuccessResult(id: "dummyId")
        let result = await instanceUnderTest.deleteEmailMessage(forIndexPath: IndexPath(row: 0, section: 0))
        XCTAssertTrue(result)
    }

    @MainActor
    func test_deleteEmailMessage_ForIndexPath_FromTrash_OnFailureReinsertsMessage() async {
        instanceUnderTest.folderNameSwitcher.currentFolder = .standard(.trash)
        instanceUnderTest.configureTableView()
        let emailMessage = DataFactory.EmailSDK.generateEmailMessage()
        instanceUnderTest.emailMessages.append(emailMessage)
        testUtility.emailClient.deleteEmailMessageError = AnyError("")
        instanceUnderTest.loadViewIfNeeded()
        let result = await self.instanceUnderTest.deleteEmailMessage(forIndexPath: IndexPath(row: 0, section: 0))
        XCTAssertFalse(result)
        XCTAssertFalse(instanceUnderTest.emailMessages.isEmpty)
    }

    @MainActor
    func test_deleteEmailMessage_ForIndexPath_FromTrash_ReloadsTableData() async {
        testUtility.emailClient.deleteEmailMessageResult = SudoEmail.DeleteEmailMessageSuccessResult(id: "dummyId")
        instanceUnderTest.folderNameSwitcher.currentFolder = .standard(.trash)
        instanceUnderTest.configureTableView()
        let emailMessage = DataFactory.EmailSDK.generateEmailMessage()
        instanceUnderTest.emailMessages.append(emailMessage)
        _ = await instanceUnderTest.deleteEmailMessage(forIndexPath: IndexPath(row: 0, section: 0))
        XCTAssertGreaterThan(tableView.reloadDataCallCount, 0)
    }

    @MainActor
    func test_deleteEmailMessage_ForIndexPath_FromInbox_MovesMessage() async {
        testUtility.emailClient.updateEmailMessagesResult = SudoEmail.BatchOperationResult(status: .success)
        instanceUnderTest.folderNameSwitcher.currentFolder = .standard(.inbox)
        instanceUnderTest.configureTableView()
        let emailMessage = DataFactory.EmailSDK.generateEmailMessage()
        instanceUnderTest.emailMessages.append(emailMessage)
        let emailMessagesCount = instanceUnderTest.emailMessages.count
        let successResult = ListAPIResult<EmailMessage, PartialEmailMessage>.ListSuccessResult(
            items: []
        )
        testUtility.emailClient.listEmailMessagesForEmailFolderIdResult = ListAPIResult.success(successResult)
        _ = await instanceUnderTest.deleteEmailMessage(forIndexPath: IndexPath(row: 0, section: 0))
        XCTAssertEqual(instanceUnderTest.emailMessages.count, emailMessagesCount - 1)
    }

    @MainActor
    func test_deleteEmailMessage_ForIndexPath_FromInbox_ClientUpdateCalled() async {
        instanceUnderTest.configureTableView()
        instanceUnderTest.folderNameSwitcher.currentFolder = .standard(.inbox)
        let emailMessage = DataFactory.EmailSDK.generateEmailMessage()
        testUtility.emailClient.updateEmailMessagesResult = SudoEmail.BatchOperationResult(status: .success)
        instanceUnderTest.emailMessages.append(emailMessage)
        _ = await instanceUnderTest.deleteEmailMessage(
            forIndexPath: IndexPath(row: instanceUnderTest.emailMessages.count - 1, section: 0)
        )
        XCTAssertTrue(testUtility.emailClient.updateEmailMessagesCalled)
        XCTAssertEqual(
            testUtility.emailClient.updateEmailMessagesParameter?.ids,
            [emailMessage.id]
        )
    }

    @MainActor
    func test_deleteEmailMessage_ForIndexPath_FromInbox_OnSuccessPerformsAList() async {
        instanceUnderTest.folderNameSwitcher.currentFolder = .standard(.inbox)
        instanceUnderTest.configureTableView()
        let emailMessage = DataFactory.EmailSDK.generateEmailMessage()
        instanceUnderTest.emailMessages.append(emailMessage)
        testUtility.emailClient.updateEmailMessagesResult = SudoEmail.BatchOperationResult(status: .success)
        _ = await instanceUnderTest.deleteEmailMessage(forIndexPath: IndexPath(row: 0, section: 0))
        XCTAssertEqual(testUtility.emailClient.listEmailMessagesForEmailFolderIdCalledCount, 3)
        XCTAssertEqual(
            testUtility.emailClient.listEmailMessagesForEmailFolderIdParameters.first?.cachePolicy,
            .cacheOnly
        )
    }

    @MainActor
    func test_deleteEmailMessage_ForIndexPath_FromInbox_OnSuccessCompletionReturnsTrue() async {
        instanceUnderTest.folderNameSwitcher.currentFolder = .standard(.inbox)
        instanceUnderTest.configureTableView()
        let emailMessage = DataFactory.EmailSDK.generateEmailMessage()
        instanceUnderTest.emailMessages.append(emailMessage)
        testUtility.emailClient.updateEmailMessagesResult = SudoEmail.BatchOperationResult(status: .success)
        let result = await instanceUnderTest.deleteEmailMessage(forIndexPath: IndexPath(row: 0, section: 0))
        XCTAssertTrue(result)
    }

    @MainActor
    func test_deleteEmailMessage_ForIndexPath_FromInbox_OnExceptionReinsertsMessage() async {
        instanceUnderTest.folderNameSwitcher.currentFolder = .standard(.inbox)
        instanceUnderTest.configureTableView()
        let emailMessage = DataFactory.EmailSDK.generateEmailMessage()
        instanceUnderTest.emailMessages.append(emailMessage)
        testUtility.emailClient.updateEmailMessagesWillThrow = true
        instanceUnderTest.loadViewIfNeeded()
        let result = await self.instanceUnderTest.deleteEmailMessage(forIndexPath: IndexPath(row: 0, section: 0))
        XCTAssertFalse(result)
        XCTAssertFalse(instanceUnderTest.emailMessages.isEmpty)
    }

    @MainActor
    func test_deleteEmailMessage_ForIndexPath_FromInbox_OnFailureReinsertsMessage() async {
        instanceUnderTest.folderNameSwitcher.currentFolder = .standard(.inbox)
        instanceUnderTest.configureTableView()
        let emailMessage = DataFactory.EmailSDK.generateEmailMessage()
        instanceUnderTest.emailMessages.append(emailMessage)
        testUtility.emailClient.updateEmailMessagesResult = SudoEmail.BatchOperationResult(status: .failure)
        instanceUnderTest.loadViewIfNeeded()
        let result = await self.instanceUnderTest.deleteEmailMessage(forIndexPath: IndexPath(row: 0, section: 0))
        XCTAssertFalse(result)
        XCTAssertFalse(instanceUnderTest.emailMessages.isEmpty)
    }

    @MainActor
    func test_deleteEmailMessage_ForIndexPath_FromInbox_ReloadsTableData() async {
        testUtility.emailClient.updateEmailMessagesResult = SudoEmail.BatchOperationResult(status: .success)
        instanceUnderTest.folderNameSwitcher.currentFolder = .standard(.inbox)
        instanceUnderTest.configureTableView()
        let emailMessage = DataFactory.EmailSDK.generateEmailMessage()
        instanceUnderTest.emailMessages.append(emailMessage)
        _ = await instanceUnderTest.deleteEmailMessage(forIndexPath: IndexPath(row: 0, section: 0))
        XCTAssertGreaterThan(tableView.reloadDataCallCount, 0)
    }

    // MARK: - Tests: UITableViewDataSource

    func test_numberOfSections() {
        XCTAssertEqual(instanceUnderTest.numberOfSections(in: tableView), 1)
    }

    func test_tableView_numberOfRowsInSection_ReturnsEmailMessageLength() {
        instanceUnderTest.emailMessages = []
        // Generate and inject 3 random email messages.
        instanceUnderTest.emailMessages.append(contentsOf: [
            DataFactory.EmailSDK.generateEmailMessage(),
            DataFactory.EmailSDK.generateEmailMessage(),
            DataFactory.EmailSDK.generateEmailMessage()
        ])
        XCTAssertEqual(instanceUnderTest.tableView(tableView, numberOfRowsInSection: 0), 3)
    }

    func test_tableView_cellForRowAt_EmailCell_DequeuesEmailMessageCell() {
        instanceUnderTest.configureTableView()
        let emailMessage = DataFactory.EmailSDK.generateEmailMessage()
        instanceUnderTest.emailMessages.append(emailMessage)
        let cell = instanceUnderTest.tableView(tableView, cellForRowAt: IndexPath(item: 0, section: 0))
        XCTAssertEqual(tableView.dequeueReusableCellCallCount, 1)
        XCTAssertEqual(tableView.dequeueReusableCellLastProperty, "emailMessageCell")
        XCTAssertTrue(cell is EmailMessageTableViewCell, "Cell is not EmailMessageCell.")
    }

    func test_tableView_cellForRowAt_EmailCell_UpdatesCellWithCorrectEmailMessage() {
        instanceUnderTest.emailMessages = []
        instanceUnderTest.configureTableView()
        let emailMessage1 = DataFactory.EmailSDK.generateEmailMessage()
        let emailMessage2 = DataFactory.EmailSDK.generateEmailMessage()
        instanceUnderTest.emailMessages.append(contentsOf: [emailMessage1, emailMessage2])
        guard let cell = instanceUnderTest.tableView(tableView, cellForRowAt: IndexPath(item: 1, section: 0)) as? EmailMessageTableViewCell else {
            return XCTFail("Failed to get email message cell")
        }
        XCTAssertEqual(cell.emailMessage?.emailAddressId, emailMessage2.emailAddressId)
    }

    func test_tableView_cellForRowAt_EmailCell_SetsCorrectAccessoryType() {
        instanceUnderTest.configureTableView()
        let emailMessage = DataFactory.EmailSDK.generateEmailMessage()
        instanceUnderTest.emailMessages.append(emailMessage)
        let cell = instanceUnderTest.tableView(tableView, cellForRowAt: IndexPath(item: 0, section: 0))
        XCTAssertEqual(cell.accessoryType, .disclosureIndicator)
    }

    // MARK: - Tests: UITableViewDelegate

    @MainActor
    func test_tableView_didSelelectRowAt_DeselectsRow() async {
        instanceUnderTest.tableView(tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
        XCTAssertEqual(tableView.deselectRowCallCount, 1)
        XCTAssertEqual(tableView.deselectRowLastProperties?.indexPath.row, 0)
        XCTAssertEqual(tableView.deselectRowLastProperties?.indexPath.section, 0)
        XCTAssertEqual(tableView.deselectRowLastProperties?.animated, true)
    }

    @MainActor
    func test_tableView_didSelelectRowAt_SeguesToReadEmailMessage() {
        let emailMessage = DataFactory.EmailSDK.generateEmailMessage()
        instanceUnderTest.emailMessages.append(emailMessage)
        instanceUnderTest.tableView(tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 2.0))
        let presentedViewController = testUtility.window.rootViewController?.presentedViewController
        XCTAssertNotNil(presentedViewController)
        XCTAssertTrue(presentedViewController is ReadEmailMessageViewController)
    }

    @MainActor
    func test_deleteEmailMessages_PresentsErrorAlertOnFailure() async {
        testUtility.emailClient.deleteEmailMessagesResult = SudoEmail.BatchOperationResult(status: .failure)
        await instanceUnderTest.deleteEmailMessages()
        let presentedViewController = await waitForAlertController()
        XCTAssertNotNil(presentedViewController)
        XCTAssertEqual(presentedViewController?.message, "Failed to empty Trash folder")
        let emailIdsToDelete = instanceUnderTest.emailMessages.map { $0.id }
        XCTAssertTrue(testUtility.emailClient.deleteEmailMessagesCalled)
        XCTAssertEqual(testUtility.emailClient.deleteEmailMessagesParameter, emailIdsToDelete)
    }

    @MainActor
    func test_deleteEmailMessages_DismissesActivityAlertOnSuccess() async {
        testUtility.emailClient.deleteEmailMessagesResult = SudoEmail.BatchOperationResult(status: .success)
        await instanceUnderTest.deleteEmailMessages()
        let presentedViewController = await waitForAlertController()
        XCTAssertNil(presentedViewController)
        let emailIdsToDelete = instanceUnderTest.emailMessages.map { $0.id }
        XCTAssertTrue(testUtility.emailClient.deleteEmailMessagesCalled)
        XCTAssertEqual(testUtility.emailClient.deleteEmailMessagesParameter, emailIdsToDelete)
    }

    @MainActor
    func test_deleteEmailMessages_PresentsErrorAlertOnPartialFailure() async {
        let partialResult = SudoEmail.BatchOperationResult(
            status: .partial,
            successItems: [SudoEmail.DeleteEmailMessageSuccessResult(id: "dummySuccessId")],
            failureItems: [SudoEmail.EmailMessageOperationFailureResult(id: "dummyFailureId", errorType: "error")]
        )
        testUtility.emailClient.deleteEmailMessagesResult = partialResult
        await instanceUnderTest.deleteEmailMessages()
        let emailIdsToDelete = instanceUnderTest.emailMessages.map { $0.id }
        XCTAssertTrue(testUtility.emailClient.deleteEmailMessagesCalled)
        XCTAssertEqual(testUtility.emailClient.deleteEmailMessagesParameter, emailIdsToDelete)
        let presentedViewController = await waitForAlertController()
        XCTAssertNotNil(presentedViewController)
        XCTAssertEqual(
            presentedViewController?.message,
            "Failed to delete email messages [SudoEmail.EmailMessageOperationFailureResult(id: \"dummyFailureId\", errorType: \"error\")]"
        )
    }

    @MainActor
    func test_deleteEmailMessages_PresentsErrorAlertOnException() async {
        testUtility.emailClient.deleteEmailMessagesWillThrow = true
        await instanceUnderTest.deleteEmailMessages()
        let emailIdsToDelete = instanceUnderTest.emailMessages.map { $0.id }
        XCTAssertTrue(testUtility.emailClient.deleteEmailMessagesCalled)
        XCTAssertEqual(testUtility.emailClient.deleteEmailMessagesParameter, emailIdsToDelete)
        let presentedViewController = await waitForAlertController()
        XCTAssertNotNil(presentedViewController)
        XCTAssertEqual(presentedViewController?.message, "Failed to empty Trash folder Test generated error")
    }

    @MainActor
    func test_deleteEmailMessage_FromDrafts_Succeeds() async {
        instanceUnderTest.folderNameSwitcher.currentFolder = .special(.drafts)
        let emailMessage = DataFactory.EmailSDK.generateEmailMessage()
        instanceUnderTest.emailMessages.append(emailMessage)
        let numberOfMessages = instanceUnderTest.emailMessages.count
        let result = await instanceUnderTest.deleteEmailMessage(
            forIndexPath: IndexPath(row: 0, section: 0)
        )
        XCTAssertTrue(testUtility.emailClient.deleteDraftEmailMessagesCalled)
        XCTAssertTrue(testUtility.emailClient.listEmailMessagesForEmailFolderIdCalled)
        XCTAssertEqual(instanceUnderTest.emailMessages.count, numberOfMessages - 1)
        XCTAssertTrue(result)
    }

    @MainActor
    func test_deleteEmailMessage_FromDrafts_ReplacesMessageOnException() async {
        instanceUnderTest.folderNameSwitcher.currentFolder = .special(.drafts)
        instanceUnderTest.emailMessages = [DataFactory.EmailSDK.generateEmailMessage()]
        testUtility.emailClient.deleteDraftEmailMessagesWillThrow = true
        let result = await instanceUnderTest.deleteEmailMessage(
            forIndexPath: IndexPath(row: 0, section: 0)
        )
        XCTAssertFalse(result)
        await waitForAsyncNoFail()
        XCTAssertEqual(instanceUnderTest.emailMessages.count, 1)
    }

    @MainActor
    func test_emptyTrash_PresentsAlert() async {
        instanceUnderTest.emptyTrash()
        let presentedViewController = await waitForAlertController()
        XCTAssertNotNil(presentedViewController)
        XCTAssertTrue(
            ((presentedViewController?.message?.starts(
                with: "Are you sure you want to empty the Trash folder?"
            )) != nil)
        )
        XCTAssertEqual(presentedViewController?.title, "Empty Trash Folder")
        XCTAssertEqual(presentedViewController?.actions.first?.title, "Cancel")
        XCTAssertEqual(presentedViewController?.actions.last?.title, "Empty Trash")
    }

    @MainActor
    func test_listDraftEmailMessages_ReturnsDraftsOnSuccess() async {
        do {
            let draftMessages = try await instanceUnderTest.listDraftEmailMessages()
            XCTAssertEqual(draftMessages.count, 1)
            XCTAssertTrue(testUtility.emailClient.listDraftEmailMessageMetadataForEmailAddressIdCalled)
            XCTAssertTrue(testUtility.emailClient.getDraftEmailMessageCalled)
            let draft = draftMessages[0]
            XCTAssertEqual(draft.clientRefId, "draftClientRefId")
            XCTAssertEqual(draft.owner, "draftOwnerId")
            XCTAssertTrue(draft.from[0].address.contains("anotessa@sudomail.com"))
            XCTAssertEqual(draft.subject, "Testing new parser")
        } catch {
            return XCTFail("list drafts threw \(error)")
        }
    }

    @MainActor
    func test_listDraftEmailMessages_ReturnsEmptyWhenNoSavedDrafts() async {
        testUtility.emailClient.listDraftEmailMessageMetadataForEmailAddressIdReturnsEmpty = true
        do {
            let draftMessages = try await instanceUnderTest.listDraftEmailMessages()
            XCTAssertTrue(draftMessages.isEmpty)
            XCTAssertTrue(testUtility.emailClient.listDraftEmailMessageMetadataForEmailAddressIdCalled)
        } catch {
            return XCTFail("list drafts threw \(error)")
        }
    }
}
