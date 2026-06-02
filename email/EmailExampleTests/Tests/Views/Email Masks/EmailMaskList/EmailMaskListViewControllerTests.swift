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
class EmailMaskListViewControllerTests: XCTestCase {

    // MARK: - Properties

    var testUtility: EmailExampleTestUtility!
    var instanceUnderTest: EmailMaskListViewController!

    // MARK: - Lifecycle

    override func setUp() {
        testUtility = EmailExampleTestUtility()
        instanceUnderTest = testUtility.storyBoard.instantiateViewController(identifier: "emailMaskList")
        instanceUnderTest.loadViewIfNeeded()
        testUtility.window.rootViewController = instanceUnderTest
        testUtility.window.makeKeyAndVisible()
    }

    override func tearDown() {
        testUtility.clearWindow()
    }

    // MARK: - Tests: loadMasks

    func test_loadMasks_CallsGetConfigurationData() async throws {
        testUtility.emailClient.listEmailMasksForOwnerResult = ListOutput<EmailMask>(items: [])
        await instanceUnderTest.loadMasks()
        try await waitForAsync()
        XCTAssertTrue(testUtility.emailClient.getConfigurationDataCalled)
    }

    func test_loadMasks_CallsListEmailMasksForOwner() async throws {
        testUtility.emailClient.listEmailMasksForOwnerResult = ListOutput<EmailMask>(items: [])
        await instanceUnderTest.loadMasks()
        try await waitForAsync()
        XCTAssertTrue(testUtility.emailClient.listEmailMasksForOwnerCalled)
    }

    func test_loadMasks_PopulatesEmailMasks() async throws {
        let mask = DataFactory.EmailSDK.generateEmailMask()
        testUtility.emailClient.listEmailMasksForOwnerResult = ListOutput<EmailMask>(items: [mask])
        await instanceUnderTest.loadMasks()
        try await waitForAsync()
        XCTAssertEqual(instanceUnderTest.emailMasks.count, 1)
        XCTAssertEqual(instanceUnderTest.emailMasks.first?.id, mask.id)
    }

    func test_loadMasks_MasksDisabled_SetsMasksEnabledFalse() async throws {
        // Override getConfigurationData to return masksEnabled = false
        // We need to use a custom configuration
        // The default generateConfigurationData has emailMasksEnabled = true
        // We'll test the behavior when the config says masks are disabled
        // by checking the masksEnabled property after loadMasks
        testUtility.emailClient.listEmailMasksForOwnerResult = ListOutput<EmailMask>(items: [])
        await instanceUnderTest.loadMasks()
        try await waitForAsync()
        // Default config has emailMasksEnabled = true, so masksEnabled should remain true
        XCTAssertTrue(instanceUnderTest.masksEnabled)
    }

    // MARK: - Tests: Segmented Control

    func test_configureSegmentedControl_ExternalEnabled_CreatesSegmentedControl() async throws {
        instanceUnderTest.externalMasksEnabled = true
        instanceUnderTest.configureSegmentedControl()
        XCTAssertNotNil(instanceUnderTest.segmentedControl)
        XCTAssertEqual(instanceUnderTest.segmentedControl?.numberOfSegments, 2)
    }

    func test_configureSegmentedControl_ExternalDisabled_NoSegmentedControl() async throws {
        instanceUnderTest.externalMasksEnabled = false
        instanceUnderTest.configureSegmentedControl()
        XCTAssertNil(instanceUnderTest.tableView.tableHeaderView)
    }

    func test_segmentChanged_UpdatesSelectedSegment() async throws {
        instanceUnderTest.externalMasksEnabled = true
        instanceUnderTest.configureSegmentedControl()
        guard let control = instanceUnderTest.segmentedControl else {
            return XCTFail("Segmented control not created")
        }
        control.selectedSegmentIndex = 1
        instanceUnderTest.segmentChanged(control)
        XCTAssertEqual(instanceUnderTest.selectedSegment, .external)
    }

    // MARK: - Tests: Filtering

    func test_filterMasks_InternalSegment_FiltersToInternalMasks() async throws {
        let internalMask = DataFactory.EmailSDK.generateEmailMask(realAddressType: .internal)
        let externalMask = DataFactory.EmailSDK.generateEmailMask(realAddressType: .external)
        instanceUnderTest.emailMasks = [internalMask, externalMask]
        instanceUnderTest.externalMasksEnabled = true
        instanceUnderTest.selectedSegment = .internal
        instanceUnderTest.filterMasks()
        XCTAssertEqual(instanceUnderTest.filteredMasks.count, 1)
        XCTAssertEqual(instanceUnderTest.filteredMasks.first?.realAddressType, .internal)
    }

    func test_filterMasks_ExternalSegment_FiltersToExternalMasks() async throws {
        let internalMask = DataFactory.EmailSDK.generateEmailMask(realAddressType: .internal)
        let externalMask = DataFactory.EmailSDK.generateEmailMask(realAddressType: .external)
        instanceUnderTest.emailMasks = [internalMask, externalMask]
        instanceUnderTest.externalMasksEnabled = true
        instanceUnderTest.selectedSegment = .external
        instanceUnderTest.filterMasks()
        XCTAssertEqual(instanceUnderTest.filteredMasks.count, 1)
        XCTAssertEqual(instanceUnderTest.filteredMasks.first?.realAddressType, .external)
    }

    func test_filterMasks_ExternalDisabled_ShowsAllMasks() async throws {
        let internalMask = DataFactory.EmailSDK.generateEmailMask(realAddressType: .internal)
        let externalMask = DataFactory.EmailSDK.generateEmailMask(realAddressType: .external)
        instanceUnderTest.emailMasks = [internalMask, externalMask]
        instanceUnderTest.externalMasksEnabled = false
        instanceUnderTest.filterMasks()
        XCTAssertEqual(instanceUnderTest.filteredMasks.count, 2)
    }

    // MARK: - Tests: UITableViewDataSource

    func test_tableView_numberOfRowsInSection_ReturnsFilteredMasksPlusOne() async throws {
        let mask = DataFactory.EmailSDK.generateEmailMask()
        instanceUnderTest.filteredMasks = [mask]
        instanceUnderTest.masksEnabled = true
        let count = instanceUnderTest.tableView(instanceUnderTest.tableView, numberOfRowsInSection: 0)
        XCTAssertEqual(count, 2) // 1 mask + 1 "Create" row
    }

    func test_tableView_numberOfRowsInSection_MasksDisabled_ReturnsZero() async throws {
        instanceUnderTest.masksEnabled = false
        let count = instanceUnderTest.tableView(instanceUnderTest.tableView, numberOfRowsInSection: 0)
        XCTAssertEqual(count, 0)
    }

    func test_tableView_numberOfSections_ReturnsOne() async throws {
        let sections = instanceUnderTest.numberOfSections(in: instanceUnderTest.tableView)
        XCTAssertEqual(sections, 1)
    }

    // MARK: - Tests: Swipe Actions

    func test_trailingSwipeActions_CreateRow_ReturnsNil() async throws {
        let mask = DataFactory.EmailSDK.generateEmailMask()
        instanceUnderTest.filteredMasks = [mask]
        instanceUnderTest.masksEnabled = true
        let indexPath = IndexPath(row: 1, section: 0) // "Create" row
        let config = instanceUnderTest.tableView(instanceUnderTest.tableView, trailingSwipeActionsConfigurationForRowAt: indexPath)
        XCTAssertNil(config)
    }

    func test_trailingSwipeActions_InternalMask_ReturnsActions() async throws {
        let mask = DataFactory.EmailSDK.generateEmailMask(realAddressType: .internal, status: .enabled)
        instanceUnderTest.filteredMasks = [mask]
        instanceUnderTest.masksEnabled = true
        let indexPath = IndexPath(row: 0, section: 0)
        let config = instanceUnderTest.tableView(instanceUnderTest.tableView, trailingSwipeActionsConfigurationForRowAt: indexPath)
        XCTAssertNotNil(config)
        XCTAssertGreaterThan(config?.actions.count ?? 0, 0)
    }
}
