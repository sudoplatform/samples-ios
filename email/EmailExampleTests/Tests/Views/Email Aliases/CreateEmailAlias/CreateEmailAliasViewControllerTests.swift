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
class CreateEmailAliasViewControllerTests: XCTestCase {

    // MARK: - Properties

    var testUtility: EmailExampleTestUtility!
    var instanceUnderTest: CreateEmailAliasViewController!

    // MARK: - Lifecycle

    override func setUp() async throws {
        testUtility = EmailExampleTestUtility()
        instanceUnderTest = testUtility.storyBoard.instantiateViewController(identifier: "createEmailAlias")
        instanceUnderTest.loadViewIfNeeded()
        testUtility.window.rootViewController = instanceUnderTest
        testUtility.window.makeKeyAndVisible()
    }

    override func tearDown() {
        testUtility.clearWindow()
    }

    // MARK: - Helpers

    func setupLoadedState() async throws {
        testUtility.emailClient.listEmailDomainsResult = [DataFactory.EmailSDK.generateEmailDomain(domain: "alias.example.com", isAliasDomain: true)]
        testUtility.emailClient.listEmailAddressesResult = ListOutput<EmailAddress>(
            items: [DataFactory.EmailSDK.generateEmailAddress(address: "test@example.com")]
        )
        testUtility.emailClient.checkEmailAddressAvailabilityResult = ["localpart@alias.example.com"]
        await instanceUnderTest.loadInitialData()
        try await waitForAsync()
    }

    // MARK: - Tests: loadInitialData

    func test_loadInitialData_CallsGetConfigurationData() async throws {
        testUtility.emailClient.listEmailDomainsResult = [DataFactory.EmailSDK.generateEmailDomain(domain: "alias.example.com", isAliasDomain: true)]
        testUtility.emailClient.listEmailAddressesResult = ListOutput<EmailAddress>(items: [])
        await instanceUnderTest.loadInitialData()
        try await waitForAsync()
        XCTAssertTrue(testUtility.emailClient.getConfigurationDataCalled)
    }

    func test_loadInitialData_CallsListEmailDomains() async throws {
        testUtility.emailClient.listEmailDomainsResult = [DataFactory.EmailSDK.generateEmailDomain(domain: "alias.example.com", isAliasDomain: true)]
        testUtility.emailClient.listEmailAddressesResult = ListOutput<EmailAddress>(items: [])
        await instanceUnderTest.loadInitialData()
        try await waitForAsync()
        XCTAssertTrue(testUtility.emailClient.listEmailDomainsCalled)
    }

    func test_loadInitialData_CallsListEmailAddresses() async throws {
        testUtility.emailClient.listEmailDomainsResult = [DataFactory.EmailSDK.generateEmailDomain(domain: "alias.example.com", isAliasDomain: true)]
        testUtility.emailClient.listEmailAddressesResult = ListOutput<EmailAddress>(items: [])
        await instanceUnderTest.loadInitialData()
        try await waitForAsync()
        XCTAssertTrue(testUtility.emailClient.listEmailAddressesCalled)
    }

    func test_loadInitialData_SetsDomain() async throws {
        testUtility.emailClient.listEmailDomainsResult = [DataFactory.EmailSDK.generateEmailDomain(domain: "alias.example.com", isAliasDomain: true)]
        testUtility.emailClient.listEmailAddressesResult = ListOutput<EmailAddress>(items: [])
        await instanceUnderTest.loadInitialData()
        try await waitForAsync()
        XCTAssertEqual(instanceUnderTest.domain, "alias.example.com")
    }

    func test_loadInitialData_SetsAvailableDomains() async throws {
        testUtility.emailClient.listEmailDomainsResult = [
            DataFactory.EmailSDK.generateEmailDomain(domain: "alias1.example.com", isAliasDomain: true),
            DataFactory.EmailSDK.generateEmailDomain(domain: "alias2.example.com", isAliasDomain: true)
        ]
        testUtility.emailClient.listEmailAddressesResult = ListOutput<EmailAddress>(items: [])
        await instanceUnderTest.loadInitialData()
        try await waitForAsync()
        XCTAssertEqual(instanceUnderTest.availableDomains.count, 2)
    }

    func test_loadInitialData_SetsEmailAddresses() async throws {
        let emailAddress = DataFactory.EmailSDK.generateEmailAddress(address: "test@example.com")
        testUtility.emailClient.listEmailDomainsResult = [DataFactory.EmailSDK.generateEmailDomain(domain: "alias.example.com", isAliasDomain: true)]
        testUtility.emailClient.listEmailAddressesResult = ListOutput<EmailAddress>(items: [emailAddress])
        await instanceUnderTest.loadInitialData()
        try await waitForAsync()
        XCTAssertEqual(instanceUnderTest.emailAddresses.count, 1)
        XCTAssertEqual(instanceUnderTest.emailAddresses.first?.emailAddress, "test@example.com")
    }

    // MARK: - Tests: Availability Check

    func test_checkAliasAddressAvailability_CallsClient() async throws {
        try await setupLoadedState()
        instanceUnderTest.localPartText = "testlocal"
        instanceUnderTest.domain = "alias.example.com"
        testUtility.emailClient.checkEmailAddressAvailabilityResult = ["testlocal@alias.example.com"]
        await instanceUnderTest.checkAliasAddressAvailability()
        try await waitForAsync()
        XCTAssertTrue(testUtility.emailClient.checkEmailAddressAvailabilityCalled)
    }

    func test_checkAliasAddressAvailability_Available_SetsIsAddressAvailableTrue() async throws {
        try await setupLoadedState()
        instanceUnderTest.localPartText = "testlocal"
        instanceUnderTest.domain = "alias.example.com"
        testUtility.emailClient.checkEmailAddressAvailabilityResult = ["testlocal@alias.example.com"]
        await instanceUnderTest.checkAliasAddressAvailability()
        try await waitForAsync()
        XCTAssertTrue(instanceUnderTest.isAddressAvailable)
    }

    func test_checkAliasAddressAvailability_NotAvailable_SetsIsAddressAvailableFalse() async throws {
        try await setupLoadedState()
        instanceUnderTest.localPartText = "testlocal"
        instanceUnderTest.domain = "alias.example.com"
        testUtility.emailClient.checkEmailAddressAvailabilityResult = []
        await instanceUnderTest.checkAliasAddressAvailability()
        try await waitForAsync()
        XCTAssertFalse(instanceUnderTest.isAddressAvailable)
    }

    // MARK: - Tests: Mode Switching

    func test_aliasTypeChanged_SwitchesToExternalMode() async throws {
        try await setupLoadedState()
        instanceUnderTest.externalAliasEnabled = true
        instanceUnderTest.configureTableHeader()
        let control = UISegmentedControl(items: ["Internal", "External"])
        control.selectedSegmentIndex = 1
        instanceUnderTest.aliasTypeChanged(control)
        XCTAssertTrue(instanceUnderTest.isExternalMode)
    }

    func test_aliasTypeChanged_SwitchesToInternalMode() async throws {
        try await setupLoadedState()
        instanceUnderTest.isExternalMode = true
        let control = UISegmentedControl(items: ["Internal", "External"])
        control.selectedSegmentIndex = 0
        instanceUnderTest.aliasTypeChanged(control)
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
        XCTAssertEqual(instanceUnderTest.title, "Create Email Alias")
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
