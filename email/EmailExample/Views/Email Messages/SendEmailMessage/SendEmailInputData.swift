//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Message data that can be pre-populated in send, ie when replying or forwarding.
struct SendEmailInputData {
    /// Id of the draft email message this input is based on
    let draftEmailMessageId: String?

    /// To address
    let to: String

    /// Cc address
    let cc: String

    /// Message subject
    let subject: String

    /// Message body
    let body: String

    /// The datetime of when the message is scheduled to be sent
    let scheduledAt: Date?

    init(
        draftEmailMessageId: String? = nil,
        to: String = "",
        cc: String = "",
        subject: String,
        body: String,
        scheduledAt: Date? = nil
    ) {
        self.draftEmailMessageId = draftEmailMessageId
        self.to = to
        self.cc = cc
        self.subject = subject
        self.body = body
        self.scheduledAt = scheduledAt
    }
}
