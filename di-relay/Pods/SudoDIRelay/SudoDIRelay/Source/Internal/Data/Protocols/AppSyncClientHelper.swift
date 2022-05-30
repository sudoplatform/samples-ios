//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSAppSync
import SudoLogging
import AWSCore
import SudoApiClient

/*
 A simple AppSync user client without Identity or Entitlements.
 */
public protocol AppSyncClientHelper {

    func getHttpEndpoint() -> String

    func getSudoApiClient() -> SudoApiClient

}
