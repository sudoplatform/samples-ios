//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import DIRelayExample

private class DataFactoryBundleLoader {}

extension DataFactory {

    enum TestData {

        static func generateInvitationString() -> String {
            return "{\"connectionId\":\"5FFD3D7A-B5F0-44B5-AB93-0BD1A8719446\",\"publicKey\":\"MIIBCgKCAQEA9SvsMW-XmkMKTSovqwSYIjMEeuNBg8TaY3nSD38PkBXltOLQPzzv75GSga7O6Q_rumGEKtrgSG4LUtvFIZh9hxgZeg2Gl_opY8cZWJ9TMX2Vh7JVgRQKlTLPrSenG5VspntBDBz4umuGyPnL2qdEzoH0LYmXAuiQ9pfUrgqJtm_9KMSZfiV8aSh7u7DxjuJxp7NMuDtmNIV9B7JOTQwlzenX_WvC4nUWd5eP6R8gKzlpruMVq0CxU73vkTnPfpadazX_S2EWyVcLeYs3z-Obj4w87J8O3sBUbOEjtj_kVMRb1-_W5qgPxUpy0J20zrvTtc49J1e7ubBEJ9EMw05tZQIDAQAB\"}"
        }

        static func generatePresentableMessage() -> PresentableMessage {
            return PresentableMessage(message: DataFactory.RelaySDK.generateRelayMessage(), encrypted: false)
        }

        static func generateTimestamp() -> String {
            return "Thu, 1 Jan 1970 00:00:00 GMT+00"
        }

    }
}
