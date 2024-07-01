//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
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
            domain: "com.emailexample.tests",
            code: 0,
            userInfo: [NSLocalizedFailureReasonErrorKey: message]
        )
        return result as Error
    }

    /// Will create an expectation and fulfill it within a `DispatchQueue.main.async {}` call.
    func waitForAsync(_ seconds: UInt64 = 2) async throws {
        try await Task.sleep(nanoseconds: seconds * 1000000000)
    }

    /// Will create an expectation and fulfill it within a `DispatchQueue.main.async {}` call.
    /// Returns a Bool rather than causing calling tests to fail on error
    @discardableResult
    func waitForAsyncNoFail(_ seconds: UInt64 = 2) async -> Bool {
        do {
            try await waitForAsync(seconds)
            return true
        } catch {
            return false
        }
    }

    // MARK: - XCTWaiter based helpers

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
    ) async -> Bool {
        for _ in 0..<timeout {
            var currentAccessibilityIdentifier = await rootWindow.rootViewController?.presentedViewController?.view.accessibilityIdentifier
            if currentAccessibilityIdentifier != accessabilityIdentifier {
                return true
            }
            await waitForAsyncNoFail()
            currentAccessibilityIdentifier = await rootWindow.rootViewController?.presentedViewController?.view.accessibilityIdentifier
            if await rootWindow.rootViewController?.presentedViewController == nil {
                return true
            }
            if currentAccessibilityIdentifier != accessabilityIdentifier {
                return true
            }
        }
        return false
    }
}
