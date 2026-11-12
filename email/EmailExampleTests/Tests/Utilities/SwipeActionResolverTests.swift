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
/// These tests generate randomized EmailAlias inputs and verify that swipe actions
/// are correctly determined by realAddressType and status.
final class SwipeActionResolverTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeMockAlias(
        id: String = UUID().uuidString,
        realAddressType: EmailAlias.RealAddressType,
        status: EmailAlias.EmailAliasStatus
    ) -> EmailAlias {
        return EmailAlias(
            id: id,
            owner: "test-owner",
            owners: [],
            identityId: "test-identity",
            aliasAddress: "alias-\(id)@example.com",
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

    private func randomStatus() -> EmailAlias.EmailAliasStatus {
        let statuses: [EmailAlias.EmailAliasStatus] = [.enabled, .disabled, .pending, .locked]
        return statuses.randomElement()!
    }

    // MARK: - Tests

    /// External alias swipe actions are determined by status.
    func testExternalAliasSwipeActionsDeterminedByStatus() {
        for _ in 0..<100 {
            let status = randomStatus()
            let alias = makeMockAlias(realAddressType: .external, status: status)
            let actions = SwipeActionResolver.actions(for: alias)

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
                "External alias with status \(status) should have actions \(expectedActions), got \(actions)")
        }
    }

    /// Internal aliases always return empty actions.
    func testInternalAliasAlwaysReturnEmptyActions() {
        for _ in 0..<100 {
            let status = randomStatus()
            let alias = makeMockAlias(realAddressType: .internal, status: status)
            let actions = SwipeActionResolver.actions(for: alias)

            XCTAssertTrue(actions.isEmpty,
                "Internal alias with status \(status) should have empty actions, got \(actions)")
        }
    }

    /// Delete is always the last action for external aliases (when actions exist).
    func testDeleteIsAlwaysLastActionForExternalAlias() {
        for _ in 0..<100 {
            let status = randomStatus()
            let alias = makeMockAlias(realAddressType: .external, status: status)
            let actions = SwipeActionResolver.actions(for: alias)

            XCTAssertFalse(actions.isEmpty, "External aliases should always have actions")
            XCTAssertEqual(actions.last, "Delete",
                "External alias should have 'Delete' as last action, got '\(actions.last ?? "nil")'")
        }
    }

    /// Each status produces a distinct first action for external aliases.
    func testAllStatusesProduceDistinctFirstActions() {
        let statuses: [EmailAlias.EmailAliasStatus] = [.pending, .enabled, .disabled]
        var firstActions: Set<String> = []

        for status in statuses {
            let alias = makeMockAlias(realAddressType: .external, status: status)
            let actions = SwipeActionResolver.actions(for: alias)
            firstActions.insert(actions[0])
        }

        XCTAssertEqual(firstActions.count, 3,
            "Each status should produce a distinct first action. Got: \(firstActions)")
    }
}
