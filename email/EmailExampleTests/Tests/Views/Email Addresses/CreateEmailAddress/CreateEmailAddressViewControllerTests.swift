//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import UIKit
import SudoEmail
@testable import EmailExample

class CreateEmailAddressViewControllerTests: XCTestCase {

    // MARK: - Properties

    var testUtility: EmailExampleTestUtility!
    var instanceUnderTest: CreateEmailAddressViewController!

    var tableView: UITableViewMockSpy!
    var mockTimer: Timer?
    var isEnabled: Bool?

    // MARK: - Lifecycle

    @MainActor
    override func setUp() async throws {
        testUtility = EmailExampleTestUtility()
        instanceUnderTest = testUtility.storyBoard.instantiateViewController(identifier: "createEmailAddressList")
        instanceUnderTest.loadViewIfNeeded()
        testUtility.window.rootViewController = instanceUnderTest
        testUtility.window.makeKeyAndVisible()
        try await displayCreateEmailAddressViewController()
        // Setup mocks and inject into instance.
        tableView = UITableViewMockSpy()
        tableView.dataSource = instanceUnderTest
        instanceUnderTest.tableView = tableView
    }

    override func tearDown() {
        testUtility.clearWindow()
    }

    @MainActor
    func displayCreateEmailAddressViewController() async throws {
        testUtility.emailClient.getSupportedEmailDomainsResult = ["test.org"]
        testUtility.emailClient.checkEmailAddressAvailabilityResult = [
            "foo1@test.org",
            "foo2@test.org",
            "foo3@test.org",
            "foo4@test.org",
            "foo5@test.org"
        ]
        instanceUnderTest.viewWillAppear(true)
        try await waitForAsync()
        guard let rootWindow = testUtility.window else {
            return XCTFail("No root window found")
        }
        let result = await waitForAlertToDisappear(rootWindow: rootWindow, accessabilityIdentifier: "activity-spinner", timeout: 100)
        XCTAssertTrue(result)
    }

    @MainActor
    func generateInputFormTableViewCell() -> InputFormTableViewCell {
        let cell = InputFormTableViewCell()
        cell.awakeFromNib()
        cell.label = UILabel()
        cell.textField = UITextField()
        return cell
    }

    // MARK: - Tests

    @MainActor
    func test_checkInputEmailAddressAvailability_CallsClient() async {
        instanceUnderTest.domain = "domain.com"
        instanceUnderTest.formData[.localPart] = "localPart"
        await instanceUnderTest.checkInputEmailAddressAvailability()
        XCTAssertTrue(testUtility.emailClient.checkEmailAddressAvailabilityCalled)
        XCTAssertEqual(testUtility.emailClient.checkEmailAddressAvailabilityParameters?.localParts.count, 1)
        XCTAssertEqual(testUtility.emailClient.checkEmailAddressAvailabilityParameters?.localParts.first, "localPart")
        XCTAssertEqual(testUtility.emailClient.checkEmailAddressAvailabilityParameters?.domains?.count, 1)
        XCTAssertEqual(testUtility.emailClient.checkEmailAddressAvailabilityParameters?.domains?.first, "domain.com")
    }

    @MainActor
    func test_createEmailAddress_CallsClient() async {
        testUtility.profilesClient.getOwnershipProofResult = "dummyOwnershipProofToken"
        testUtility.emailClient.provisionEmailAddressResult = DataFactory.EmailSDK.generateEmailAddress()
        NSLog("provisionEmailAddressResult is \(String(describing: testUtility.emailClient.provisionEmailAddressResult))")
        instanceUnderTest.domain = "domain.com"
        instanceUnderTest.formData[.localPart] = "localPart"
        await instanceUnderTest.createEmailAddress()
        XCTAssertTrue(testUtility.emailClient.provisionEmailAddressCalled)
        XCTAssertEqual(testUtility.emailClient.provisionEmailAddressParameters?.emailAddress, "localPart@domain.com")
    }

    func test_configureNavigationBar_SetsRightBarButtonItemOnNavigationItem() {
        instanceUnderTest.configureNavigationBar()
        guard let buttonItem = instanceUnderTest.navigationItem.rightBarButtonItem else {
            return XCTFail("Failed to get button item")
        }
        XCTAssertEqual(buttonItem.title, "Create")
        XCTAssertEqual(buttonItem.style, .plain)
    }

    func test_configureTableView() {
        instanceUnderTest.configureTableView()
        XCTAssertEqual(tableView.registerNibCallCount, 1)
        XCTAssertEqual(tableView.registerNibProperties.first?.identifier, "inputFormCell")
        XCTAssertEqual(instanceUnderTest.tableFooterView.backgroundColor, .none)
        XCTAssertEqual(instanceUnderTest.tableFooterView.translatesAutoresizingMaskIntoConstraints, true)
        XCTAssertTrue(instanceUnderTest.tableView.tableFooterView === instanceUnderTest.tableFooterView)
    }

    @MainActor
    func test_configureFooterValues_NilSudoLabel_willPresentsError() async throws {
        instanceUnderTest.sudo.label = nil
        instanceUnderTest.configureFooterValues()
        try await waitForAsync()
        guard let presentedAlert = instanceUnderTest.presentedViewController as? UIAlertController else {
            return XCTFail("No presented alert")
        }
        XCTAssertEqual(presentedAlert.title, "Error")
        XCTAssertEqual(presentedAlert.message, "An error has occurred: no sudo label found")
        XCTAssertEqual(presentedAlert.actions.first?.title, "OK")
    }

    @MainActor
    func test_configureFooterValues_EmptySudoLabel_willPresentsError() async throws {
        instanceUnderTest.sudo.label = ""
        instanceUnderTest.configureFooterValues()
        try await waitForAsync()
        guard let presentedAlert = instanceUnderTest.presentedViewController as? UIAlertController else {
            return XCTFail("No presented alert")
        }
        XCTAssertEqual(presentedAlert.title, "Error")
        XCTAssertEqual(presentedAlert.message, "An error has occurred: no sudo label found")
        XCTAssertEqual(presentedAlert.actions.first?.title, "OK")
    }

    @MainActor
    func test_configureFooterValues_NilSudoId_willPresentsError() async throws {
        instanceUnderTest.sudo.label = "label"
        instanceUnderTest.sudo.id = nil
        instanceUnderTest.configureFooterValues()
        try await waitForAsync()
        guard let presentedAlert = instanceUnderTest.presentedViewController as? UIAlertController else {
            return XCTFail("No presented alert")
        }
        XCTAssertEqual(presentedAlert.title, "Error")
        XCTAssertEqual(presentedAlert.message, "An error has occurred: no sudo id found")
        XCTAssertEqual(presentedAlert.actions.first?.title, "OK")
    }

    @MainActor
    func test_configureFooterValues_EmptySudoId_willPresentsError() async throws {
        instanceUnderTest.sudo.label = "label"
        instanceUnderTest.sudo.id = ""
        instanceUnderTest.configureFooterValues()
        try await waitForAsync()
        guard let presentedAlert = instanceUnderTest.presentedViewController as? UIAlertController else {
            return XCTFail("No presented alert")
        }
        XCTAssertEqual(presentedAlert.title, "Error")
        XCTAssertEqual(presentedAlert.message, "An error has occurred: no sudo id found")
        XCTAssertEqual(presentedAlert.actions.first?.title, "OK")
    }

    @MainActor
    func test_configureFooterValues_SetsSudoLabel() async throws {
        instanceUnderTest.sudo.label = "label"
        instanceUnderTest.sudo.id = "id"
        instanceUnderTest.configureFooterValues()
        try await waitForAsync()
        XCTAssertNil(instanceUnderTest.presentedViewController)
        XCTAssertEqual(instanceUnderTest.sudoLabel.text, "label")
    }

    func test_setCreateButtonEnabled_True() {
        instanceUnderTest.setCreateButtonEnabled(true)
        guard let isEnabled = instanceUnderTest.navigationItem.rightBarButtonItem?.isEnabled else {
            return XCTFail("Failed to get isEnabled")
        }
        XCTAssertTrue(isEnabled)
    }

    func test_setCreateButtonEnabled_False() {
        instanceUnderTest.setCreateButtonEnabled(false)
        guard let isEnabled = instanceUnderTest.navigationItem.rightBarButtonItem?.isEnabled else {
            return XCTFail("Failed to get isEnabled")
        }
        XCTAssertFalse(isEnabled)
    }

    func test_getInputLabel_LocalPart() {
        let localPart = CreateEmailAddressViewController.InputField.localPart
        let index = IndexPath.init(row: localPart.rawValue, section: 0)
        XCTAssertEqual(instanceUnderTest.getInputLabel(forIndexPath: index), "Local Part")
    }

    func test_getInputLabel_Alias() {
        let localPart = CreateEmailAddressViewController.InputField.alias
        let index = IndexPath.init(row: localPart.rawValue, section: 0)
        XCTAssertEqual(instanceUnderTest.getInputLabel(forIndexPath: index), "Display Name")
    }

    func test_getInputLabel_Default() {
        let index = IndexPath(row: 100, section: 0)
        XCTAssertEqual(instanceUnderTest.getInputLabel(forIndexPath: index), "Field")
    }

    func test_getInputPlaceholder_LocalPart() {
        let localPart = CreateEmailAddressViewController.InputField.localPart
        let index = IndexPath.init(row: localPart.rawValue, section: 0)
        XCTAssertEqual(instanceUnderTest.getInputPlaceholder(forIndexPath: index), "Enter local part of the email address")
    }

    func test_getInputPlaceholder_Alias() {
        let localPart = CreateEmailAddressViewController.InputField.alias
        let index = IndexPath.init(row: localPart.rawValue, section: 0)
        XCTAssertEqual(instanceUnderTest.getInputPlaceholder(forIndexPath: index), "Enter display name (Optional)")
    }

    func test_getInputPlaceholder_Default() {
        let index = IndexPath(row: 100, section: 0)
        XCTAssertEqual(instanceUnderTest.getInputPlaceholder(forIndexPath: index), "Enter value")
    }

    func test_validateFormData_ReturnsFalseIfLocalPartIsNil() {
        instanceUnderTest.formData[.localPart] = nil
        XCTAssertFalse(instanceUnderTest.validateFormData())
    }

    func test_validateFormData_ReturnsFalseIfLocalPartIsLengthTwo() {
        instanceUnderTest.formData[.localPart] = "12"
        XCTAssertFalse(instanceUnderTest.validateFormData())
    }

    func test_validateFormData_ReturnsTrueIfLocalPartIsLengthThree() {
        instanceUnderTest.formData[.localPart] = "123"
        XCTAssertTrue(instanceUnderTest.validateFormData())
    }

    func test_validateFormData_ReturnsTrueIfAliasIsNil() {
        instanceUnderTest.formData[.localPart] = "abcd"
        instanceUnderTest.formData[.alias] = nil
        XCTAssertTrue(instanceUnderTest.validateFormData())
    }

    func test_tableView_numberOfSections_ReturnsSectionCountOfOne() {
        XCTAssertEqual(instanceUnderTest.numberOfSections(in: tableView), 1)
    }

    func test_tableView_numberOfRowsInSection_ReturnsInputFieldCount() {
        let expectedRowCount = CreateEmailAddressViewController.InputField.allCases.count
        XCTAssertEqual(instanceUnderTest.tableView(tableView, numberOfRowsInSection: 0), expectedRowCount)
    }

    func test_tableView_cellForRowAt_localPart_ConfiguresCellCorrectly() {
        instanceUnderTest.configureTableView()
        let localPart = CreateEmailAddressViewController.InputField.localPart
        let indexPath = IndexPath(row: localPart.rawValue, section: 0)
        guard let cell = instanceUnderTest.tableView(tableView, cellForRowAt: indexPath) as? InputFormTableViewCell else {
            return XCTFail("Failed to get cell")
        }
        XCTAssertTrue(cell.delegate === instanceUnderTest)
        XCTAssertEqual(cell.label.text, "Local Part")
        XCTAssertEqual(cell.textField.placeholder, "Enter local part of the email address")
    }

    func test_tableView_cellForRowAt_alias_ConfiguresCellCorrectly() {
        instanceUnderTest.configureTableView()
        let alias = CreateEmailAddressViewController.InputField.alias
        let indexPath = IndexPath(row: alias.rawValue, section: 0)
        guard let cell = instanceUnderTest.tableView(tableView, cellForRowAt: indexPath) as? InputFormTableViewCell else {
            return XCTFail("Failed to get cell")
        }
        XCTAssertTrue(cell.delegate === instanceUnderTest)
        XCTAssertEqual(cell.label.text, "Display Name")
        XCTAssertEqual(cell.textField.placeholder, "Enter display name (Optional)")
    }

    @MainActor
    func test_inputCell_didUpdateInput_InvalidatesTimer() async throws {
        mockTimer = Timer(fire: .distantFuture, interval: .infinity, repeats: false, block: { _ in})
        RunLoop.main.add(mockTimer!, forMode: .common)
        instanceUnderTest.checkEmailAddressTimer = mockTimer
        XCTAssertEqual(mockTimer?.isValid, true)
        let cell = generateInputFormTableViewCell()
        instanceUnderTest.inputCell(cell, didUpdateInput: nil)
        try await waitForAsync()
        XCTAssertEqual(mockTimer?.isValid, false)
    }

    @MainActor
    func test_inputCell_didUpdateInput_SetsCreateButtonEnabledToFalse() async throws {
        let cell = generateInputFormTableViewCell()
        instanceUnderTest.inputCell(cell, didUpdateInput: nil)
        instanceUnderTest.setCreateButtonEnabled(true)
        guard let isEnabled = instanceUnderTest.navigationItem.rightBarButtonItem?.isEnabled else {
            return XCTFail("Failed to get isEnabled")
        }
        XCTAssertTrue(isEnabled)
        try await waitForAsync()
        guard let isEnabled = instanceUnderTest.navigationItem.rightBarButtonItem?.isEnabled else {
            return XCTFail("Failed to get isEnabled")
        }
        XCTAssertFalse(isEnabled)
    }

    @MainActor
    func test_inputCell_didUpdateInput_SetsTextFieldColorToLabel() async throws {
        let cell = generateInputFormTableViewCell()
        instanceUnderTest.inputCell(cell, didUpdateInput: nil)
        instanceUnderTest.setCreateButtonEnabled(true)
        try await waitForAsync()
        instanceUnderTest.checkEmailAddressTimer?.invalidate()
        XCTAssertEqual(cell.textField.textColor, .label)
    }

    @MainActor
    func test_inputCell_didUpdateInput_localPart_SetsFormDataToNilIfInputNil() async throws {
        let localPart = CreateEmailAddressViewController.InputField.localPart
        let indexPath = IndexPath(row: localPart.rawValue, section: 0)
        tableView.indexPathForCellResult = indexPath
        let cell = generateInputFormTableViewCell()
        instanceUnderTest.inputCell(cell, didUpdateInput: nil)
        try await waitForAsync()
        XCTAssertNil(instanceUnderTest.formData[.localPart])
    }

    @MainActor
    func test_inputCell_didUpdateInput_localPart_SetsFormDataToNilIfInputEmpty() async throws {
        let localPart = CreateEmailAddressViewController.InputField.localPart
        let indexPath = IndexPath(row: localPart.rawValue, section: 0)
        tableView.indexPathForCellResult = indexPath
        let cell = generateInputFormTableViewCell()
        instanceUnderTest.inputCell(cell, didUpdateInput: "")
        try await waitForAsync()
        XCTAssertNil(instanceUnderTest.formData[.localPart])
    }

    @MainActor
    func test_inputCell_didUpdateInput_localPart_UpdatesFormData() async throws {
        let localPart = CreateEmailAddressViewController.InputField.localPart
        let indexPath = IndexPath(row: localPart.rawValue, section: 0)
        tableView.indexPathForCellResult = indexPath
        let cell = generateInputFormTableViewCell()
        instanceUnderTest.inputCell(cell, didUpdateInput: "Foobar")
        try await waitForAsync()
        XCTAssertEqual(instanceUnderTest.formData[.localPart], "Foobar")
    }

    @MainActor
    func test_inputCell_didUpdateInput_localPart_SetsUpTimerCorrectly() async throws {
        let localPart = CreateEmailAddressViewController.InputField.localPart
        let indexPath = IndexPath(row: localPart.rawValue, section: 0)
        tableView.indexPathForCellResult = indexPath
        let cell = generateInputFormTableViewCell()
        instanceUnderTest.inputCell(cell, didUpdateInput: "foobar")
        try await waitForAsync()
        guard let timer = instanceUnderTest.checkEmailAddressTimer else {
            return XCTFail("Failed to get timer")
        }
        timer.fire()
        XCTAssertTrue(testUtility.emailClient.checkEmailAddressAvailabilityCalled)
    }

}
