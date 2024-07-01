//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import SudoNotificationExtension
@testable import SudoEmailNotificationExtension

class SudoEmailNotifiableClientMock: SudoNotifiableClient {
    let serviceName = "emService"

    
    var decodeResult: SudoNotificationExtension.SudoNotification = EmailUnknownNotification(type: "Set SudoEmailNotifiableClientMock.decodeResult to the desired notification")
    var decodeCalls = 0

    func decode(data: String) -> any SudoNotificationExtension.SudoNotification {
        decodeCalls += 1
        return decodeResult
    }
}
