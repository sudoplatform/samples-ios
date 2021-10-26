//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSAppSync
@testable import SudoDIRelay

class MockAppSyncClientHelper: AppSyncClientHelper {

    // MARK: - Properties
    var getAppSyncClientCalled: Bool = false
    var getHttpEndpointCalled: Bool = false

    private var appSyncClient: MockAWSAppSyncClientGenerator!

    // MARK: - Lifecycle

    init() throws {
        appSyncClient = MockAWSAppSyncClientGenerator()
    }

    // MARK: - Conformance: AppSyncClientHelper

    func getAppSyncClient() -> AWSAppSyncClient? {
        getAppSyncClientCalled = true
        return MockAWSAppSyncClientGenerator.generateClient()
    }

    func getHttpEndpoint() -> String {
        getHttpEndpointCalled = true
        return "mockEndpoint"
    }
}
