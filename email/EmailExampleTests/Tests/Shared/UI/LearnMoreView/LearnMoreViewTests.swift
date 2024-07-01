//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import EmailExample

class LearnMoreViewTests: XCTestCase, LearnMoreViewDelegate {

    // MARK: - Properties

    var instanceUnderTest: LearnMoreView!

    // MARK: - Lifecycle

    override func setUp() {
        instanceUnderTest = LearnMoreView.fromNib()
    }

    // MARK: - Tests

    func test_awakeFromNib_SetsLabelTextToNil() throws {
        let instanceUnderTest: LearnMoreView = LearnMoreView.fromNib()
        XCTAssertNil(instanceUnderTest.label.text)
    }

    func test_awakeFromNib_SetsBackgroundColorToNone() throws {
        let instanceUnderTest: LearnMoreView = LearnMoreView.fromNib()
        XCTAssertEqual(instanceUnderTest.backgroundColor, .none)
    }

    func test_didTapLearnMoreButton_FiresDelegate() {
        instanceUnderTest.delegate = self
        let expectation = XCTestExpectation(description: "didTapLearnMoreButton")
        didTapLearnMoreButtonExpection = expectation
        instanceUnderTest.didTapLearnMoreButton()
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(didTapLearnMoreButtonCallCount, 1)
    }

    // MARK: - Conformance: LearnMoreViewDelegate

    var didTapLearnMoreButtonCallCount = 0
    var didTapLearnMoreButtonExpection: XCTestExpectation?
    func didTapLearnMoreButton() {
        didTapLearnMoreButtonCallCount += 1
        didTapLearnMoreButtonExpection?.fulfill()
    }

}
