//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import EmailExample

class DateLabelTests: XCTestCase {

    // MARK: - Properties

    let calendar = Calendar(identifier: .iso8601)

    var instanceUnderTest: DateLabel!

    // MARK: - Lifecycle

    override func setUp() {
        instanceUnderTest = DateLabel( )
    }

    // MARK: - Utilities

    func performDateTest(inputDate: Date, expectedString: String, file: StaticString = #file, line: UInt = #line) {
        instanceUnderTest.date = inputDate
        let result = instanceUnderTest.text
        XCTAssertEqual(result, expectedString, file: file, line: line)
    }

    // MARK: - Tests

    func test_didSetDate_textLabel_now_ReturnsHourMinuteTimestamp() {
        let now = Date()
        let expectedString = now.getFormattedDate(format: "HH:mm")
        performDateTest(inputDate: now, expectedString: expectedString)
    }

    func test_didSetDate_textLabel_TodayMidnight_ReturnsHourMinuteTimestamp() {
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let expectedString = startOfToday.getFormattedDate(format: "HH:mm")
        performDateTest(inputDate: startOfToday, expectedString: expectedString)
    }

    func test_didSetDate_textLabel_YesterdayUpperLimit_ReturnsYesterdayLabel() {
        let now = Date()
        let endOfYesterday = calendar.startOfDay(for: now) - 1.0
        let expectedString = "Yesterday"
        performDateTest(inputDate: endOfYesterday, expectedString: expectedString)
    }

    func test_didSetDate_textLabel_YesterdayLowerLimit_ReturnsYesterdayLabel() {
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        guard let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday) else {
            return XCTFail("Failed to get start of yesterday date")
        }
        let expectedString = "Yesterday"
        performDateTest(inputDate: startOfYesterday, expectedString: expectedString)
    }

    func test_didSetDate_textLabel_DaysOfWeekUpperLimit_ReturnsNamedDayFormat() {
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        guard let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday) else {
            return XCTFail("Failed to get start of yesterday date")
        }
        let endOfTwoDaysAgo = startOfYesterday - 1.0
        let expectedString = endOfTwoDaysAgo.getFormattedDate(format: "EEEE")
        performDateTest(inputDate: endOfTwoDaysAgo, expectedString: expectedString)
    }

    func test_didSetDate_textLabel_DaysOfWeekLowerLimit_ReturnsNamedDayFormat() {
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        guard let startOfSevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: startOfToday) else {
            return XCTFail("Failed to get start of yesterday date")
        }
        let expectedString = startOfSevenDaysAgo.getFormattedDate(format: "MMM d, yyyy")
        performDateTest(inputDate: startOfSevenDaysAgo, expectedString: expectedString)
    }

    func test_didSetDate_textLabel_OuterLimitSevenDaysAgo_ReturnsHourMinuteFormat() {
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        guard let startOfSevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: startOfToday) else {
            return XCTFail("Failed to get start of yesterday date")
        }
        let endOfEightDaysAgo = startOfSevenDaysAgo - 1.0
        let expectedString = endOfEightDaysAgo.getFormattedDate(format: "MMM d, yyyy")
        performDateTest(inputDate: endOfEightDaysAgo, expectedString: expectedString)
    }

}
