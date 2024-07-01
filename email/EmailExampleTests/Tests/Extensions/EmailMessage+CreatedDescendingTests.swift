//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import EmailExample
@testable import SudoEmail

class EmailMessage_CreatedDescendingTests: XCTestCase {

    func test_sortedByCreatedDescending() {
        var emailMessages = [
            DataFactory.EmailSDK.generateEmailMessage(),
            DataFactory.EmailSDK.generateEmailMessage(),
            DataFactory.EmailSDK.generateEmailMessage()
        ]
        emailMessages[0].createdAt = Date(timeIntervalSince1970: 1.0)
        emailMessages[1].createdAt = Date(timeIntervalSince1970: 2.0)
        emailMessages[2].createdAt = Date(timeIntervalSince1970: 3.0)
        let result = emailMessages.sortedByCreatedDescending()
        XCTAssertEqual(result.first, emailMessages.last)
        XCTAssertEqual(result.last, emailMessages.first)
    }

    func test_sortByCreatedDescending() {
        var emailMessages = [
            DataFactory.EmailSDK.generateEmailMessage(),
            DataFactory.EmailSDK.generateEmailMessage(),
            DataFactory.EmailSDK.generateEmailMessage()
        ]
        emailMessages[0].createdAt = Date(timeIntervalSince1970: 1.0)
        emailMessages[1].createdAt = Date(timeIntervalSince1970: 2.0)
        emailMessages[2].createdAt = Date(timeIntervalSince1970: 3.0)
        var emailMessageCopy = emailMessages
        emailMessageCopy.sortByCreatedDescending()
        XCTAssertEqual(emailMessageCopy.first, emailMessages.last)
        XCTAssertEqual(emailMessageCopy.last, emailMessages.first)
    }

}
