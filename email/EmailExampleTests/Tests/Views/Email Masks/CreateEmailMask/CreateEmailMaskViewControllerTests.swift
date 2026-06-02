//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import UIKit
import SudoEmail
@testable import EmailExample

@MainActor
class CreateEmailMaskViewControllerTests: XCTestCase {

    // MARK: - Properties

    var testUtility: EmailExampleTestUtility!
    var instanceUnderTest: CreateEmailMaskViewController!

    // MARK: - Lifecycle

    override func setUp() async throws {
        testUtility = EmailExampleTestUtility()
        instanceUnderTest = testUtility.storyBoard.instantiateViewController(identifier: "createEmailMask")
        instanceUnderTest.loadViewIfNeeded()
        testUtility.window.rootViewController = instanceUnderTest
        testUtility.window.makeKeyAndVisible()
    }

    override func tearDown() {
        testUtility.clearWindow()
    }

    // MARK: - Helpers

    func setupLoadedState() async throws {
        testUtility.emailClient.getEmailMaskDomainsResult = ["mask.example.com"]
        testUtility.emailClient.listEmailAddressesResult = ListOutput<EmailAddress>(
            items: [DataFactory.EmailSDK.generateEmailAddress(address: "test@example.com")]
        )
        testUtility.emailClient.checkEmailAddressAvailabilityResult = ["localpart@mask.example.com"]
        await instanceUnderTest.loadInitialData()
        try await waitForAsync()
    }

    // MARK: - Tests: loadInitialData

    func test_loadInitialData_CallsGetConfigurationData() async throws {
        testUtility.emailClient.getEmailMaskDomainsResult = ["mask.example.com"]
        testUtility.emailClient.listEmailAddressesResult = ListOutput<EmailAddress>(items: [])
        await instanceUnderTest.loadInitialData()
        try await waitForAsync()
        XCTAssertTrue(testUtility.emailClient.getConfigurationDataCalled)
    }

    func test_loadInitialData_CallsGetEmailMaskDomains() async throws {
        testUtility.emailClient.getEmailMaskDomainsResult = ["mask.example.com"]
        testUtility.emailClient.listEmailAddressesResult = ListOutput<EmailAddress>(items: [])
        await instanceUnderTest.loadInitialData()
        try await waitForAsync()
        XCTAssertTrue(testUtility.emailClient.getEmailMaskDomainsCalled)
    }

    func test_loadInitialData_CallsListEmailAddresses() async throws {
        testUtility.emailClient.getEmailMaskDomainsResult = ["mask.example.com"]
        testUtility.emailClient.listEmailAddressesResult = ListOutput<EmailAddress>(items: [])
        await instanceUnderTest.loadInitialData()
        try await waitForAsync()
        XCTAssertTrue(testUtility.emailClient.listEmailAddressesCalled)
    }

    func test_loadInitialData_SetsDomain() async throws {
        testUtility.emailClient.getEmailMaskDomainsResult = ["mask.example.com"]
        testUtility.emailClient.listEmailAddressesResult = ListOutput<EmailAddress>(items: [])
        await instanceUnderTest.loadInitialData()
        try await waitForAsync()
        XCTAssertEqual(instanceUnderTest.domain, "mask.example.com")
    }

    func test_loadInitialData_SetsAvailableDomains() async throws {
        testUtility.emailClient.getEmailMaskDomainsResult = ["mask1.example.com", "mask2.example.com"]
        testUtility.emailClient.listEmailAddressesResult = ListOutput<EmailAddress>(items: [])
        await instanceUnderTest.loadInitialData()
        try await waitForAsync()
        XCTAssertEqual(instanceUnderTest.availableDomains.count, 2)
    }

    func test_loadInitialData_SetsEmailAddresses() async throws {
        let emailAddress = DataFactory.EmailSDK.generateEmailAddress(address: "test@example.com")
        testUtility.emailClient.getEmailMaskDomainsResult = ["mask.example.com"]
        testUtility.emailClient.listEmailAddressesResult = ListOutput<EmailAddress>(items: [emailAddress])
        await instanceUnderTest.loadInitialData()
        try await waitForAsync()
        XCTAssertEqual(instanceUnderTest.emailAddresses.count, 1)
        XCTAssertEqual(instanceUnderTest.emailAddresses.first?.emailAddress, "test@example.com")
    }

    // MARK: - Tests: Availability Check

    func test_checkMaskAddressAvailability_CallsClient() async throws {
        try await setupLoadedState()
        instanceUnderTest.localPartText = "testlocal"
        instanceUnderTest.domain = "mask.example.com"
        testUtility.emailClient.checkEmailAddressAvailabilityResult = ["testlocal@mask.example.com"]
        await instanceUnderTest.checkMaskAddressAvailability()
        try await waitForAsync()
        XCTAssertTrue(testUtility.emailClient.checkEmailAddressAvailabilityCalled)
    }

    func test_checkMaskAddressAvailability_Available_SetsIsAddressAvailableTrue() async throws {
        try await setupLoadedState()
        instanceUnderTest.localPartText = "testlocal"
        instanceUnderTest.domain = "mask.example.com"
        testUtility.emailClient.checkEmailAddressAvailabilityResult = ["testlocal@mask.example.com"]
        await instanceUnderTest.checkMaskAddressAvailability()
        try await waitForAsync()
        XCTAssertTrue(instanceUnderTest.isAddressAvailable)
    }

    func test_checkMaskAddressAvailability_NotAvailable_SetsIsAddressAvailableFalse() async throws {
        try await setupLoadedState()
        instanceUnderTest.localPartText = "testlocal"
        instanceUnderTest.domain = "mask.example.com"
        testUtility.emailClient.checkEmailAddressAvailabilityResult = []
        await instanceUnderTest.checkMaskAddressAvailability()
        try await waitForAsync()
        XCTAssertFalse(instanceUnderTest.isAddressAvailable)
    }

    // MARK: - Tests: Mode Switching

    func test_maskTypeChanged_SwitchesToExternalMode() async throws {
        try await setupLoadedState()
        instanceUnderTest.externalMasksEnabled = true
        instanceUnderTest.configureTableHeader()
        let control = UISegmentedControl(items: ["Internal", "External"])
        control.selectedSegmentIndex = 1
        instanceUnderTest.maskTypeChanged(control)
        XCTAssertTrue(instanceUnderTest.isExternalMode)
    }

    func test_maskTypeChanged_SwitchesToInternalMode() async throws {
        try await setupLoadedState()
        instanceUnderTest.isExternalMode = true
        let control = UISegmentedControl(items: ["Internal", "External"])
        control.selectedSegmentIndex = 0
        instanceUnderTest.maskTypeChanged(control)
        XCTAssertFalse(instanceUnderTest.isExternalMode)
    }

    // MARK: - Tests: Create Button State

    func test_setCreateButtonEnabled_True() async throws {
        instanceUnderTest.configureNavigationBar()
        instanceUnderTest.setCreateButtonEnabled(true)
        guard let isEnabled = instanceUnderTest.navigationItem.rightBarButtonItem?.isEnabled else {
            return XCTFail("Failed to get isEnabled")
        }
        XCTAssertTrue(isEnabled)
    }

    func test_setCreateButtonEnabled_False() async throws {
        instanceUnderTest.configureNavigationBar()
        instanceUnderTest.setCreateButtonEnabled(false)
        guard let isEnabled = instanceUnderTest.navigationItem.rightBarButtonItem?.isEnabled else {
            return XCTFail("Failed to get isEnabled")
        }
        XCTAssertFalse(isEnabled)
    }

    func test_updateCreateButtonState_NoLocalPart_DisablesButton() async throws {
        instanceUnderTest.configureNavigationBar()
        instanceUnderTest.localPartText = ""
        instanceUnderTest.isAddressAvailable = true
        instanceUnderTest.emailAddresses = [DataFactory.EmailSDK.generateEmailAddress()]
        instanceUnderTest.updateCreateButtonState()
        guard let isEnabled = instanceUnderTest.navigationItem.rightBarButtonItem?.isEnabled else {
            return XCTFail("Failed to get isEnabled")
        }
        XCTAssertFalse(isEnabled)
    }

    func test_updateCreateButtonState_AddressNotAvailable_DisablesButton() async throws {
        instanceUnderTest.configureNavigationBar()
        instanceUnderTest.localPartText = "test"
        instanceUnderTest.isAddressAvailable = false
        instanceUnderTest.emailAddresses = [DataFactory.EmailSDK.generateEmailAddress()]
        instanceUnderTest.updateCreateButtonState()
        guard let isEnabled = instanceUnderTest.navigationItem.rightBarButtonItem?.isEnabled else {
            return XCTFail("Failed to get isEnabled")
        }
        XCTAssertFalse(isEnabled)
    }

    // MARK: - Tests: configureNavigationBar

    func test_configureNavigationBar_SetsTitle() async throws {
        instanceUnderTest.configureNavigationBar()
        XCTAssertEqual(instanceUnderTest.title, "Create Email Mask")
    }

    func test_configureNavigationBar_SetsRightBarButtonItem() async throws {
        instanceUnderTest.configureNavigationBar()
        guard let buttonItem = instanceUnderTest.navigationItem.rightBarButtonItem else {
            return XCTFail("Failed to get button item")
        }
        XCTAssertEqual(buttonItem.title, "Create")
        XCTAssertEqual(buttonItem.style, .plain)
    }

    // MARK: - Tests: UITableViewDataSource

    func test_tableView_numberOfSections_ReturnsZero() async throws {
        let sections = instanceUnderTest.numberOfSections(in: instanceUnderTest.tableView)
        XCTAssertEqual(sections, 0)
    }

    func test_tableView_numberOfRowsInSection_ReturnsZero() async throws {
        let count = instanceUnderTest.tableView(instanceUnderTest.tableView, numberOfRowsInSection: 0)
        XCTAssertEqual(count, 0)
    }
}
