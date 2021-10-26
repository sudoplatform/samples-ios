//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoDIRelay

struct AppDependencies {
    let appSyncClientHelper: AppSyncClientHelper
    let sudoDIRelayClient: SudoDIRelayClient


    init(appSyncClientHelper: AppSyncClientHelper, sudoDIRelayClient: SudoDIRelayClient) {
        self.appSyncClientHelper = appSyncClientHelper
        self.sudoDIRelayClient = sudoDIRelayClient
    }


    init() throws {
        // If this line fails, this object is being initialized on a background thread.
        assert(Thread.isMainThread)
        appSyncClientHelper = try DefaultAppSyncClientHelper()

        // If this fails, check the config is set up
        sudoDIRelayClient = try DefaultSudoDIRelayClient(appSyncClientHelper: appSyncClientHelper)
    }
}
