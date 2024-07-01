//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit

/// UILabel for formatting dates for emails.
class DateLabel: UILabel {

    // MARK: - Supplementary

    /// Formats for the label output.
    ///
    /// For more information, see [here](https://en.wikipedia.org/wiki/ISO_8601).
    enum DateFormat: String {
        case hourMinute = "HH:mm"
        case monthDayYear = "MMM d, yyyy"
        case day = "EEEE"
    }

    // MARK: - Properties

    /// Calendar object used to format dates.
    let calendar = Calendar(identifier: .iso8601)

    /// Date property used to format the label `text` itself.
    var date: Date? {
        didSet {
            updateText()
        }
    }

    // MARK: - Methods

    /// Updates the text of the label.
    ///
    /// If the `date` is nil, all text will be removed.
    private func updateText() {
        guard let date = date else {
            text = nil
            return
        }
        text = getFormattedStringForDate(date)
    }

    /// Get the formatted string for the input date.
    ///
    /// Formats the date as follows:
    /// - If the date is greater than tomorrow, or less than 7 days ago, the date will be formatted in month-date-year format. For example, `Jul 11, 2004`.
    /// - If the date falls within the bounds of today, the date will be formatted as hour-minute. For example, `11:52`.
    /// - If the date falls within the bounds of yesterday, the date will appear as `Yesterday`.
    /// - If the date is less than yesterday but greater than 7 days ago, the date will appear as the name of the day. For example, `Monday`.
    ///
    /// - Parameter date: Date to get formatted string for.
    /// - Returns: String formatted accordingly to rules.
    private func getFormattedStringForDate(_ date: Date) -> String {
        let now = Date()
        let calendar = Calendar(identifier: .gregorian)
        let startOfToday = calendar.startOfDay(for: now)
        guard
            let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday),
            let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday),
            let sixDaysAgo = calendar.date(byAdding: .day, value: -6, to: startOfToday)
        else {
            return date.formattedDate(.monthDayYear)
        }
        // Date is greater than now or less than 6 days.
        if date >= startOfTomorrow || date < sixDaysAgo {
            return date.formattedDate(.monthDayYear)
        // `startOfYesterday` < `date` < `startOfTomorrow`
        } else if date >= startOfToday {
            return date.formattedDate(.hourMinute)
        } else if date >= startOfYesterday {
            return "Yesterday"
        // `sixDaysAgo` < `date` < `startOfYesterday`
        } else {
            return date.formattedDate(.day)
        }
    }

}

fileprivate extension Date {

    /// Returns the formatted date for the input `dateFormat` type.
    func formattedDate(_ dateFormat: DateLabel.DateFormat) -> String {
        return self.getFormattedDate(format: dateFormat.rawValue)
    }
}
