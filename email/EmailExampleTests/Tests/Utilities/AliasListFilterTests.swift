//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import EmailExample
import SudoEmail

/// Property-based tests for AliasListFilter.
///
/// These tests generate randomized inputs and verify that filtering by realAddressType
/// correctly partitions the alias list without losing or misclassifying any items.
final class AliasListFilterTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeMockAlias(
        id: String,
        realAddressType: EmailAlias.RealAddressType,
        status: EmailAlias.EmailAliasStatus = .enabled
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

    private func randomRealAddressType() -> EmailAlias.RealAddressType {
        return Bool.random() ? .internal : .external
    }

    private func generateRandomAlias(maxCount: Int = 50) -> [EmailAlias] {
        let count = Int.random(in: 0...maxCount)
        return (0..<count).map { index in
            makeMockAlias(
                id: "\(index)-\(UUID().uuidString.prefix(8))",
                realAddressType: randomRealAddressType()
            )
        }
    }

    // MARK: - Tests

    /// Filtering preserves and partitions by type.
    func testFilteringPreservesAndPartitionsByType() {
        for _ in 0..<100 {
            let aliases = generateRandomAlias()

            let internalFiltered = AliasListFilter.filter(aliases: aliases, byType: .internal)
            let externalFiltered = AliasListFilter.filter(aliases: aliases, byType: .external)

            // Every item in .internal result has realAddressType == .internal
            for alias in internalFiltered {
                XCTAssertEqual(alias.realAddressType, .internal,
                    "Found alias '\(alias.id)' in internal results with wrong type")
            }

            // Every item in .external result has realAddressType == .external
            for alias in externalFiltered {
                XCTAssertEqual(alias.realAddressType, .external,
                    "Found alias '\(alias.id)' in external results with wrong type")
            }

            // Partition counts sum to total
            XCTAssertEqual(internalFiltered.count + externalFiltered.count, aliases.count,
                "Partition counts don't sum to total")
        }
    }

    /// Empty list returns empty results.
    func testEmptyListReturnsEmptyResults() {
        let aliases: [EmailAlias] = []

        let internalFiltered = AliasListFilter.filter(aliases: aliases, byType: .internal)
        let externalFiltered = AliasListFilter.filter(aliases: aliases, byType: .external)

        XCTAssertTrue(internalFiltered.isEmpty)
        XCTAssertTrue(externalFiltered.isEmpty)
    }

    /// All same type partitions correctly.
    func testAllSameTypePartitionsCorrectly() {
        for _ in 0..<20 {
            let count = Int.random(in: 1...30)
            let type: EmailAlias.RealAddressType = Bool.random() ? .internal : .external

            let aliases = (0..<count).map { index in
                makeMockAlias(id: "\(index)", realAddressType: type)
            }

            let internalFiltered = AliasListFilter.filter(aliases: aliases, byType: .internal)
            let externalFiltered = AliasListFilter.filter(aliases: aliases, byType: .external)

            if type == .internal {
                XCTAssertEqual(internalFiltered.count, count)
                XCTAssertTrue(externalFiltered.isEmpty)
            } else {
                XCTAssertTrue(internalFiltered.isEmpty)
                XCTAssertEqual(externalFiltered.count, count)
            }
        }
    }
}
