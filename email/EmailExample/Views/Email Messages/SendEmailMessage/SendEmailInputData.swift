//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Message data that can be pre-populated in send, 1st use case is when replying
struct SendEmailInputData {
    /// id of the draft email message this input is based on
    var draftEmailMessageId: String?

    /// To address
    var to: String

    /// cc address
    var cc: String

    /// message subject
    var subject: String

    /// message body
    var body: String
}
