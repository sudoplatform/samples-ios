//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSAppSync
import AWSCore

/// Configuration for connecting to the Sudo Email Service via AppSync.
struct SudoDIRelayConfig: AWSAppSyncServiceConfigProvider {

    // MARK: - Conformance: AWSAppSyncServiceConfigProvider

    public var endpoint: URL

    public var region: AWSRegionType

    public var authType: AWSAppSyncAuthType = .amazonCognitoUserPools

    public var apiKey: String?

    public var clientDatabasePrefix: String?

    // MARK: - Lifecycle

    /// Initialize an instance of `SudoDIRelayConfig`.
    public init(
        endpoint: URL,
        region: AWSRegionType,
        authType: AWSAppSyncAuthType = .amazonCognitoUserPools,
        apiKey: String? = nil,
        clientDatabasePrefix: String? = nil
    ) {
        self.endpoint = endpoint
        self.region = region
        self.authType = authType
        self.apiKey = apiKey
        self.clientDatabasePrefix = clientDatabasePrefix
    }
}
