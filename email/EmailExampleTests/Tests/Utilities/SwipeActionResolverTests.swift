//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import EmailExample
import SudoEmail

/// Property-based tests for SwipeActionResolver.
///
/// These tests generate randomized EmailMask inputs and verify that swipe actions
/// are correctly determined by realAddressType and status.
final class SwipeActionResolverTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeMockMask(
        id: String = UUID().uuidString,
        realAddressType: EmailMask.RealAddressType,
        status: EmailMask.EmailMaskStatus
    ) -> EmailMask {
        return EmailMask(
            id: id,
            owner: "test-owner",
            owners: [],
            identityId: "test-identity",
            maskAddress: "mask-\(id)@example.com",
            realAddress: "real-\(id)@example.com",
            realAddressType: realAddressType,
            status: status,
            inboundReceived: 0,
            inboundDelivered: 0,
            outboundReceived: 0,
            outboundDelivered: 0,
            spamCount: 0,
            virusCount: 0,
            createdAt: Date(),
            updatedAt: Date(),
            version: 1
        )
    }

    private func randomStatus() -> EmailMask.EmailMaskStatus {
        let statuses: [EmailMask.EmailMaskStatus] = [.enabled, .disabled, .pending, .locked]
        return statuses.randomElement()!
    }

    // MARK: - Tests

    /// External mask swipe actions are determined by status.
    func testExternalMaskSwipeActionsDeterminedByStatus() {
        for _ in 0..<100 {
            let status = randomStatus()
            let mask = makeMockMask(realAddressType: .external, status: status)
            let actions = SwipeActionResolver.actions(for: mask)

            let expectedActions: [String]
            switch status {
            case .pending:
                expectedActions = ["Verify", "Delete"]
            case .enabled:
                expectedActions = ["Disable", "Delete"]
            case .disabled:
                expectedActions = ["Enable", "Delete"]
            case .locked:
                expectedActions = ["Delete"]
            }

            XCTAssertEqual(actions, expectedActions,
                "External mask with status \(status) should have actions \(expectedActions), got \(actions)")
        }
    }

    /// Internal masks always return empty actions.
    func testInternalMasksAlwaysReturnEmptyActions() {
        for _ in 0..<100 {
            let status = randomStatus()
            let mask = makeMockMask(realAddressType: .internal, status: status)
            let actions = SwipeActionResolver.actions(for: mask)

            XCTAssertTrue(actions.isEmpty,
                "Internal mask with status \(status) should have empty actions, got \(actions)")
        }
    }

    /// Delete is always the last action for external masks (when actions exist).
    func testDeleteIsAlwaysLastActionForExternalMasks() {
        for _ in 0..<100 {
            let status = randomStatus()
            let mask = makeMockMask(realAddressType: .external, status: status)
            let actions = SwipeActionResolver.actions(for: mask)

            XCTAssertFalse(actions.isEmpty, "External masks should always have actions")
            XCTAssertEqual(actions.last, "Delete",
                "External mask should have 'Delete' as last action, got '\(actions.last ?? "nil")'")
        }
    }

    /// Each status produces a distinct first action for external masks.
    func testAllStatusesProduceDistinctFirstActions() {
        let statuses: [EmailMask.EmailMaskStatus] = [.pending, .enabled, .disabled]
        var firstActions: Set<String> = []

        for status in statuses {
            let mask = makeMockMask(realAddressType: .external, status: status)
            let actions = SwipeActionResolver.actions(for: mask)
            firstActions.insert(actions[0])
        }

        XCTAssertEqual(firstActions.count, 3,
            "Each status should produce a distinct first action. Got: \(firstActions)")
    }
}
