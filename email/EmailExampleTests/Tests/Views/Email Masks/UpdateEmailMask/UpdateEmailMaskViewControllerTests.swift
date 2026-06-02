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
class UpdateEmailMaskViewControllerTests: XCTestCase {

    // MARK: - Properties

    var testUtility: EmailExampleTestUtility!
    var instanceUnderTest: UpdateEmailMaskViewController!

    // MARK: - Lifecycle

    override func setUp() async throws {
        testUtility = EmailExampleTestUtility()
        instanceUnderTest = testUtility.storyBoard.instantiateViewController(identifier: "updateEmailMask")
        instanceUnderTest.emailMask = DataFactory.EmailSDK.generateEmailMask(
            expiresAt: Date().addingTimeInterval(86400),
            metadata: ["key1": "value1", "key2": "value2"]
        )
        instanceUnderTest.loadViewIfNeeded()
        testUtility.window.rootViewController = instanceUnderTest
        testUtility.window.makeKeyAndVisible()
    }

    override func tearDown() {
        testUtility.clearWindow()
    }

    // MARK: - Tests: Form Pre-population

    func test_viewWillAppear_PrePopulatesMetadataTextField() async throws {
        instanceUnderTest.viewWillAppear(true)
        try await waitForAsync()
        let text = instanceUnderTest.metadataTextField.text ?? ""
        // Metadata should contain key-value pairs
        XCTAssertTrue(text.contains("key1"))
        XCTAssertTrue(text.contains("value1"))
        XCTAssertTrue(text.contains("key2"))
        XCTAssertTrue(text.contains("value2"))
    }

    func test_viewWillAppear_PrePopulatesExpiryDatePicker() async throws {
        instanceUnderTest.viewWillAppear(true)
        try await waitForAsync()
        XCTAssertTrue(instanceUnderTest.expirySwitch.isOn)
        XCTAssertFalse(instanceUnderTest.expiryDatePicker.isHidden)
    }

    func test_viewWillAppear_NoExpiry_SwitchIsOff() async throws {
        instanceUnderTest.emailMask = DataFactory.EmailSDK.generateEmailMask(expiresAt: nil)
        instanceUnderTest.viewWillAppear(true)
        try await waitForAsync()
        XCTAssertFalse(instanceUnderTest.expirySwitch.isOn)
        XCTAssertTrue(instanceUnderTest.expiryDatePicker.isHidden)
    }

    func test_viewWillAppear_NoMetadata_TextFieldIsEmpty() async throws {
        instanceUnderTest.emailMask = DataFactory.EmailSDK.generateEmailMask(metadata: nil)
        instanceUnderTest.viewWillAppear(true)
        try await waitForAsync()
        let text = instanceUnderTest.metadataTextField.text ?? ""
        XCTAssertTrue(text.isEmpty)
    }

    func test_viewWillAppear_EmptyMetadata_TextFieldIsEmpty() async throws {
        instanceUnderTest.emailMask = DataFactory.EmailSDK.generateEmailMask(metadata: [:])
        instanceUnderTest.viewWillAppear(true)
        try await waitForAsync()
        let text = instanceUnderTest.metadataTextField.text ?? ""
        XCTAssertTrue(text.isEmpty)
    }

    // MARK: - Tests: Save Button Behavior

    func test_didTapSaveButton_NoChanges_PresentsError() async throws {
        instanceUnderTest.viewWillAppear(true)
        try await waitForAsync()
        // Tap save without making changes
        instanceUnderTest.didTapSaveButton(instanceUnderTest.saveButton!)
        try await waitForAsync()
        guard let presentedAlert = instanceUnderTest.presentedViewController as? UIAlertController else {
            return XCTFail("No presented alert")
        }
        XCTAssertEqual(presentedAlert.title, "Error")
        XCTAssertTrue(presentedAlert.message?.contains("No changes detected") ?? false)
    }

    func test_didTapSaveButton_MetadataChanged_CallsUpdateEmailMask() async throws {
        instanceUnderTest.viewWillAppear(true)
        try await waitForAsync()
        // Change metadata
        instanceUnderTest.metadataTextField.text = "newKey: newValue"
        testUtility.emailClient.updateEmailMaskResult = DataFactory.EmailSDK.generateEmailMask()
        instanceUnderTest.didTapSaveButton(instanceUnderTest.saveButton!)
        try await waitForAsync()
        try await waitForAsync()
        XCTAssertTrue(testUtility.emailClient.updateEmailMaskCalled)
    }

    func test_didTapSaveButton_MetadataChanged_PassesCorrectInput() async throws {
        instanceUnderTest.viewWillAppear(true)
        try await waitForAsync()
        instanceUnderTest.metadataTextField.text = "name: test"
        testUtility.emailClient.updateEmailMaskResult = DataFactory.EmailSDK.generateEmailMask()
        instanceUnderTest.didTapSaveButton(instanceUnderTest.saveButton!)
        try await waitForAsync()
        try await waitForAsync()
        let parameter = testUtility.emailClient.updateEmailMaskParameter
        XCTAssertNotNil(parameter)
        XCTAssertEqual(parameter?.emailMaskId, instanceUnderTest.emailMask.id)
        XCTAssertEqual(parameter?.metadata?["name"], "test")
    }

    // MARK: - Tests: Expiry Switch

    func test_expirySwitchChanged_TurnsOn_ShowsDatePicker() async throws {
        instanceUnderTest.viewWillAppear(true)
        try await waitForAsync()
        instanceUnderTest.expirySwitch.isOn = true
        instanceUnderTest.expirySwitchChanged(instanceUnderTest.expirySwitch)
        XCTAssertFalse(instanceUnderTest.expiryDatePicker.isHidden)
        XCTAssertTrue(instanceUnderTest.expiryDatePicker.isUserInteractionEnabled)
    }

    func test_expirySwitchChanged_TurnsOff_HidesDatePicker() async throws {
        instanceUnderTest.viewWillAppear(true)
        try await waitForAsync()
        instanceUnderTest.expirySwitch.isOn = false
        instanceUnderTest.expirySwitchChanged(instanceUnderTest.expirySwitch)
        XCTAssertTrue(instanceUnderTest.expiryDatePicker.isHidden)
        XCTAssertFalse(instanceUnderTest.expiryDatePicker.isUserInteractionEnabled)
    }

    // MARK: - Tests: Metadata Parsing

    func test_didTapSaveButton_ParsesMultipleMetadataEntries() async throws {
        instanceUnderTest.viewWillAppear(true)
        try await waitForAsync()
        instanceUnderTest.metadataTextField.text = "key1: val1, key2: val2"
        testUtility.emailClient.updateEmailMaskResult = DataFactory.EmailSDK.generateEmailMask()
        instanceUnderTest.didTapSaveButton(instanceUnderTest.saveButton!)
        try await waitForAsync()
        try await waitForAsync()
        let parameter = testUtility.emailClient.updateEmailMaskParameter
        XCTAssertNotNil(parameter)
        XCTAssertEqual(parameter?.metadata?["key1"], "val1")
        XCTAssertEqual(parameter?.metadata?["key2"], "val2")
    }

    func test_didTapSaveButton_ClearedMetadata_SendsEmptyMap() async throws {
        instanceUnderTest.viewWillAppear(true)
        try await waitForAsync()
        // Clear the metadata text
        instanceUnderTest.metadataTextField.text = ""
        testUtility.emailClient.updateEmailMaskResult = DataFactory.EmailSDK.generateEmailMask()
        instanceUnderTest.didTapSaveButton(instanceUnderTest.saveButton!)
        try await waitForAsync()
        try await waitForAsync()
        let parameter = testUtility.emailClient.updateEmailMaskParameter
        XCTAssertNotNil(parameter)
        XCTAssertEqual(parameter?.metadata, [:])
    }
}
