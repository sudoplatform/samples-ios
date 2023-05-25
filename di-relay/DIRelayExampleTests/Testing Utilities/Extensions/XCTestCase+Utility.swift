//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

/// Extension that contains convenience methods to aid in test readability
extension XCTestCase {

    // MARK: - Error Creation

    /// Creates a `NSError` using the given message and returns a casted `Error`
    /// - Parameter message: The failure reason to assign to the `userInfo`
    /// - Returns: Error
    func createError(message: String = "unit-test") -> Error {
        let result = NSError(
            domain: "com.DIrelay.tests",
            code: 0,
            userInfo: [NSLocalizedFailureReasonErrorKey: message]
        )
        return result as Error
    }

    // MARK: - XCTWaiter based helpers

    /// Will create an expectation and fulfill it within a `DispatchQueue.main.async {}` call.
    func waitForAsync(description: String? = nil, isInverted: Bool = false, file: StaticString = #file, line: UInt = #line) {

        let description = description ?? UUID().uuidString
        let expectation = self.expectation(description: description)
        DispatchQueue.main.async { expectation.fulfill() }
        let result = XCTWaiter.wait(for: [expectation], timeout: 2, enforceOrder: true)
        switch result {
        case .timedOut:
            XCTFail("Asynchronous wait failed: Exceeded timeout of 2.0 seconds, with unfulfilled expectations: \"\(description)\".", file: file, line: line)
        case .interrupted:
            XCTFail("Asynchronous wait failed: Wait was interrupted.", file: file, line: line)
        default:
            break
        }

    }

    /// Will create an expectation and fulfill it within a `DispatchQueue.main.async {}` call.
    /// Returns a Bool rather than causing calling tests to fail on error
    @discardableResult
    func waitForAsyncNoFail(description: String? = nil, isInverted: Bool = false) -> Bool {
        let description = description ?? UUID().uuidString
        let expectation = self.expectation(description: description)
        DispatchQueue.main.async { expectation.fulfill() }
        let result = XCTWaiter.wait(for: [expectation], timeout: 2, enforceOrder: true)
        switch result {
        case .timedOut:
            return false
        case .interrupted:
            return false
        default:
            return true
        }
    }

    private static let defaultTimeout = 1.0

    func waitUntil(
        file: StaticString = #file,
        line: UInt = #line,
        _ waitOn: @escaping (@escaping () -> Void) -> Void
    ) {
        waitUntil(file: file, line: line, timeout: XCTestCase.defaultTimeout, waitOn)
    }

    func waitUntil(
        file: StaticString = #file,
        line: UInt = #line,
        timeout: TimeInterval,
        _ waitOn: @escaping (@escaping () -> Void) -> Void
    ) {
        let waiter = XCTWaiter()
        let expectation = XCTestExpectation()
        waitOn {
            expectation.fulfill()
        }
        let result = waiter.wait(for: [expectation], timeout: timeout)
        switch result {
        case .timedOut:
            XCTFail("Asynchronous wait failed: Exceeded timeout of \(timeout) seconds", file: file, line: line)
        default:
            break
        }
    }

    func waitForAlertToDisappear(
        rootWindow: UIWindow,
        accessabilityIdentifier: String,
        timeout: Int
    ) -> Bool {
        for _ in 0..<timeout {
            var currentAccessibilityIdentifier = rootWindow.rootViewController?.presentedViewController?.view.accessibilityIdentifier
            if currentAccessibilityIdentifier != accessabilityIdentifier {
                return true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                currentAccessibilityIdentifier = rootWindow.rootViewController?.presentedViewController?.view.accessibilityIdentifier
            }
            waitForAsyncNoFail()
            if rootWindow.rootViewController?.presentedViewController == nil {
                return true
            }
            if currentAccessibilityIdentifier != accessabilityIdentifier {
                return true
            }
        }
        return false
    }
}
