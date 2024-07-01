//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import MimeParser
@testable import EmailExample

class RFC822UtilTest: XCTestCase {

    // MARK: - Tests

    func test_BasicRFC822Message() throws {
        let from = "from@example.com"
        let to = ["to@example.com"]
        let cc = ["cc@example.com"]
        let bcc = ["bcc@example.com"]
        let subejct = "subject"
        let body = "This is the body!"
        let plainMessage = BasicRFC822Message(from: from, to: to, cc: cc, bcc: bcc, subject: subejct, body: body)
        guard let data = RFC822Util.fromBasicRFC822(plainMessage) else {
            XCTFail("Unable to obtain data")
            return
        }
        let parsedMessage = try RFC822Util.fromPlainText(data)
        XCTAssertEqual(parsedMessage.from, plainMessage.from)
        XCTAssertEqual(parsedMessage.to, plainMessage.to)
        XCTAssertEqual(parsedMessage.cc, plainMessage.cc)
        XCTAssertEqual(parsedMessage.bcc, plainMessage.bcc)
        XCTAssertEqual(parsedMessage.subject, plainMessage.subject)
        XCTAssertEqual(parsedMessage.body, plainMessage.body)
    }

    func test_ComplexB64Data() throws {
        let rfc822String = DataFactory.TestData.complexBase64Email
        guard let data = rfc822String.data(using: .utf8) else {
            XCTFail("Unable to convert string to utf8 bytes")
            return
        }

        let message = try RFC822Util.fromPlainText(data)
        XCTAssertEqual("Greg McCane <gmccane@anonyome.com>", message.from)
        XCTAssertEqual(["\"df3aaa6a@team-email-dev.com\" <df3aaa6a@team-email-dev.com>"], message.to)
        XCTAssertEqual([], message.cc)
        XCTAssertEqual([], message.bcc)
        XCTAssertEqual("Another email from outlook", message.subject)
        XCTAssertEqual("Do you see any of this?\r\n\r\n[signature_142797101]\r\n", message.body)
    }

    func test_ComplexData() throws {
        let rfc822String = DataFactory.TestData.complexDataEmail

        guard let data = rfc822String.data(using: .utf8) else {
            XCTFail("Unable to convert string to utf8 bytes")
            return
        }
        let message = try RFC822Util.fromPlainText(data)
        XCTAssertEqual("Ano Tessa <anotessa@sudomail.com>", message.from)
        XCTAssertEqual(["T3 Sudoplatz <77033823@team-email-dev.com>"], message.to)
        XCTAssertEqual([], message.cc)
        XCTAssertEqual([], message.bcc)
        XCTAssertEqual("Testing new parser", message.subject)
        // swiftlint:disable line_length
        XCTAssertEqual(
            "How does this look\r\n\r\nJtcitu Clu lu tf;utfiycluso EC it lurxkutxlutxkytdlu tl ur lutxlutslutdkyr prxpu. Bc itso tdp BC f p utf. Ltd p\r\n\r\nCheers,\r\nAno\r\n\r\n",
            message.body
        )
        // swiftlint:enable line_length
    }

    func test_Base64EncodedBody() throws {
        let rfc822String = DataFactory.TestData.base64EncodedBodyEmail
        guard let data = rfc822String.data(using: .utf8) else {
            XCTFail("Unable to convert string to utf8 bytes")
            return
        }
        let message = try RFC822Util.fromPlainText(data)
        // swiftlint:disable line_length
        XCTAssertEqual(
            "Test\r\n\r\n﻿On 23/7/20, 8:52 am, \"6f9385bf@team-email-dev.com\" <6f9385bf@team-email-dev.com> wrote:\r\n\r\n    Test\r\n\r\n    ---------------\r\n\r\n                    Initially sent from my Outlook address.\r\n\r\n",
            message.body
        )
        // swiftlint:enable line_length
    }

    // MARK: - FromPlainText

    func test_fromPlainText_MimeParserError() {
        let invalidMimeText = "faskjlfaksljjklfas"
        guard let data = invalidMimeText.data(using: .utf8) else {
            return XCTFail("Failed to encode data")
        }
        XCTAssertThrowsError(try RFC822Util.fromPlainText(data)) { error in
            guard let err = error as? RFC822Error else {
                return XCTFail("Failed to received expected error. Instead received: \(error)")
            }
            XCTAssertEqual(err, .mimeParserError)
        }
    }

}
