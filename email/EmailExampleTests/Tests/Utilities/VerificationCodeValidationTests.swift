//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import EmailExample

/// Property-based tests for VerificationCodeValidation.
///
/// Validates that whitespace-only or empty verification codes are rejected,
/// and codes with at least one non-whitespace character are accepted.
final class VerificationCodeValidationTests: XCTestCase {

    // MARK: - Helpers

    private let whitespaceCharacters: [Character] = [" ", "\t", "\n", "\r"]

    private func randomWhitespaceString(length: Int) -> String {
        guard length > 0 else { return "" }
        return String((0..<length).map { _ in whitespaceCharacters.randomElement()! })
    }

    private func randomNonWhitespaceCharacter() -> Character {
        let scalar = Unicode.Scalar(UInt32.random(in: 33...126))!
        return Character(scalar)
    }

    private func randomStringWithNonWhitespace(length: Int) -> String {
        guard length > 0 else { return String(randomNonWhitespaceCharacter()) }
        var chars: [Character] = (0..<length).map { _ in
            Bool.random() ? whitespaceCharacters.randomElement()! : randomNonWhitespaceCharacter()
        }
        chars[Int.random(in: 0..<chars.count)] = randomNonWhitespaceCharacter()
        return String(chars)
    }

    // MARK: - Tests

    func testEmptyStringIsRejected() {
        XCTAssertFalse(VerificationCodeValidation.isValid(""))
    }

    func testWhitespaceOnlyStringsAreRejected() {
        for _ in 0..<100 {
            let length = Int.random(in: 1...50)
            let ws = randomWhitespaceString(length: length)
            XCTAssertFalse(VerificationCodeValidation.isValid(ws),
                "Whitespace-only should be rejected: \(ws.debugDescription)")
        }
    }

    func testStringsWithNonWhitespaceAreAccepted() {
        for _ in 0..<100 {
            let length = Int.random(in: 1...50)
            let valid = randomStringWithNonWhitespace(length: length)
            XCTAssertTrue(VerificationCodeValidation.isValid(valid),
                "String with non-whitespace should be accepted: \(valid.debugDescription)")
        }
    }

    func testIndividualWhitespaceCharactersAreRejected() {
        let cases = [" ", "\t", "\n", "\r", "\r\n", "  ", "\t\t", " \t\n\r"]
        for ws in cases {
            XCTAssertFalse(VerificationCodeValidation.isValid(ws),
                "Should reject: \(ws.debugDescription)")
        }
    }
}
