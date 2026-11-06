//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

/// Marks something as having unread messages: a dot for a single message, or the count for a number with several. Shown at the
/// start of a row, with the same width whether shown or not, so rows line up.
struct UnreadIndicator: View {

    // MARK: - Properties

    let isUnread: Bool

    /// How many messages are unread, shown inside the indicator. `nil` shows a plain dot.
    var count: Int?

    // MARK: - View

    var body: some View {
        Group {
            if isUnread {
                if let count {
                    Text("\(count)")
                        .font(.caption2.bold())
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .frame(minWidth: 18, minHeight: 18)
                        .background(Capsule().fill(.tint))
                } else {
                    Circle()
                        .fill(.tint)
                        .frame(width: 10, height: 10)
                }
            } else {
                // Keeps the space when there's nothing to show; an empty group would collapse to nothing.
                Color.clear
                    .frame(width: 10, height: 10)
            }
        }
        .frame(minWidth: 18)
        .accessibilityLabel(isUnread ? (count.map { "\($0) unread" } ?? "Unread") : "")
    }
}
