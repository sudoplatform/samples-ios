//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import EmailExample
import SudoEmail

/// Property-based tests for MaskListFilter.
///
/// These tests generate randomized inputs and verify that filtering by realAddressType
/// correctly partitions the mask list without losing or misclassifying any items.
final class MaskListFilterTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeMockMask(
        id: String,
        realAddressType: EmailMask.RealAddressType,
        status: EmailMask.EmailMaskStatus = .enabled
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

    private func randomRealAddressType() -> EmailMask.RealAddressType {
        return Bool.random() ? .internal : .external
    }

    private func generateRandomMasks(maxCount: Int = 50) -> [EmailMask] {
        let count = Int.random(in: 0...maxCount)
        return (0..<count).map { index in
            makeMockMask(
                id: "\(index)-\(UUID().uuidString.prefix(8))",
                realAddressType: randomRealAddressType()
            )
        }
    }

    // MARK: - Tests

    /// Filtering preserves and partitions by type.
    func testFilteringPreservesAndPartitionsByType() {
        for _ in 0..<100 {
            let masks = generateRandomMasks()

            let internalFiltered = MaskListFilter.filter(masks: masks, byType: .internal)
            let externalFiltered = MaskListFilter.filter(masks: masks, byType: .external)

            // Every item in .internal result has realAddressType == .internal
            for mask in internalFiltered {
                XCTAssertEqual(mask.realAddressType, .internal,
                    "Found mask '\(mask.id)' in internal results with wrong type")
            }

            // Every item in .external result has realAddressType == .external
            for mask in externalFiltered {
                XCTAssertEqual(mask.realAddressType, .external,
                    "Found mask '\(mask.id)' in external results with wrong type")
            }

            // Partition counts sum to total
            XCTAssertEqual(internalFiltered.count + externalFiltered.count, masks.count,
                "Partition counts don't sum to total")
        }
    }

    /// Empty list returns empty results.
    func testEmptyListReturnsEmptyResults() {
        let masks: [EmailMask] = []

        let internalFiltered = MaskListFilter.filter(masks: masks, byType: .internal)
        let externalFiltered = MaskListFilter.filter(masks: masks, byType: .external)

        XCTAssertTrue(internalFiltered.isEmpty)
        XCTAssertTrue(externalFiltered.isEmpty)
    }

    /// All same type partitions correctly.
    func testAllSameTypePartitionsCorrectly() {
        for _ in 0..<20 {
            let count = Int.random(in: 1...30)
            let type: EmailMask.RealAddressType = Bool.random() ? .internal : .external

            let masks = (0..<count).map { index in
                makeMockMask(id: "\(index)", realAddressType: type)
            }

            let internalFiltered = MaskListFilter.filter(masks: masks, byType: .internal)
            let externalFiltered = MaskListFilter.filter(masks: masks, byType: .external)

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
