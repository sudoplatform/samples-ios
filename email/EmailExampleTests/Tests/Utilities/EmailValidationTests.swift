//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import EmailExample

/// Property-based tests for EmailValidation.isValidFormat(_:).
///
/// Validates that the email format checker correctly identifies valid and invalid emails
/// based on RFC 5321 rules (single @, non-empty local part, domain with dot, max 254 chars).
final class EmailValidationTests: XCTestCase {

    // MARK: - Helpers

    private let iterations = 100

    private let localPartChars = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.!#$%&'*+/=?^_`{|}~-")
    private let domainLabelChars = Array("abcdefghijklmnopqrstuvwxyz0123456789-")

    private func randomString(from chars: [Character], minLength: Int = 1, maxLength: Int = 20) -> String {
        let length = Int.random(in: minLength...maxLength)
        return String((0..<length).map { _ in chars.randomElement()! })
    }

    private func generateValidEmail() -> String {
        let localPart = randomString(from: localPartChars, minLength: 1, maxLength: 30)
        let numSegments = Int.random(in: 2...4)
        let domainSegments = (0..<numSegments).map { _ in
            randomString(from: domainLabelChars, minLength: 1, maxLength: 10)
        }
        let domain = domainSegments.joined(separator: ".")
        let email = "\(localPart)@\(domain)"
        if email.count > 254 {
            return String(email.prefix(254))
        }
        return email
    }

    // MARK: - Tests

    func testValidEmailsReturnTrue() {
        for _ in 0..<iterations {
            let email = generateValidEmail()
            XCTAssertTrue(EmailValidation.isValidFormat(email), "Valid email should pass: \(email)")
        }
    }

    func testNoAtSignReturnsFalse() {
        let noAtChars = Array("abcdefghijklmnopqrstuvwxyz0123456789.")
        for _ in 0..<iterations {
            let input = randomString(from: noAtChars, minLength: 1, maxLength: 50)
            XCTAssertFalse(EmailValidation.isValidFormat(input), "String with no @ should fail: \(input)")
        }
    }

    func testMultipleAtSignsReturnsFalse() {
        for _ in 0..<iterations {
            let localPart = randomString(from: localPartChars, minLength: 1, maxLength: 15)
            let middle = randomString(from: localPartChars, minLength: 1, maxLength: 10)
            let domain = randomString(from: domainLabelChars, minLength: 1, maxLength: 10)
            let input = "\(localPart)@\(middle)@\(domain).com"
            XCTAssertFalse(EmailValidation.isValidFormat(input), "Multiple @ should fail: \(input)")
        }
    }

    func testEmptyLocalPartReturnsFalse() {
        for _ in 0..<iterations {
            let numSegments = Int.random(in: 2...4)
            let domainSegments = (0..<numSegments).map { _ in
                randomString(from: domainLabelChars, minLength: 1, maxLength: 10)
            }
            let domain = domainSegments.joined(separator: ".")
            let input = "@\(domain)"
            XCTAssertFalse(EmailValidation.isValidFormat(input), "Empty local part should fail: \(input)")
        }
    }

    func testDomainMissingDotReturnsFalse() {
        for _ in 0..<iterations {
            let localPart = randomString(from: localPartChars, minLength: 1, maxLength: 20)
            let domain = randomString(from: domainLabelChars, minLength: 1, maxLength: 20)
            let input = "\(localPart)@\(domain)"
            XCTAssertFalse(EmailValidation.isValidFormat(input), "Domain without dot should fail: \(input)")
        }
    }

    func testExceedingMaxLengthReturnsFalse() {
        for _ in 0..<iterations {
            let targetLength = Int.random(in: 255...400)
            let localPartLength = targetLength - 12
            let localPart = String(repeating: "a", count: max(localPartLength, 1))
            let input = "\(localPart)@example.com"
            XCTAssertGreaterThan(input.count, 254)
            XCTAssertFalse(EmailValidation.isValidFormat(input), "Email > 254 chars should fail")
        }
    }
}
