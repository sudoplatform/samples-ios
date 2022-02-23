//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSAppSync
import SudoLogging
import AWSCore


/*
 A simple AppSync user client without Identity or Entitlements.
 */
public protocol AppSyncClientHelper {

    func getAppSyncClient() -> AWSAppSyncClient?

    func getHttpEndpoint() -> String
}
