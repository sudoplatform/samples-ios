//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSAppSync
import SudoApiClient
import SudoUser
@testable import SudoDIRelay

class MockAppSyncClientHelper: AppSyncClientHelper {

    // MARK: - Properties

    var getAppSyncClientCalled: Bool = false
    var getHttpEndpointCalled: Bool = false
    var getSudoApiClientCalled: Bool = false

    private var sudoApiClient: SudoApiClient!

    // MARK: - Lifecycle

    init() throws {
        let sudoUserClient = MockSudoUserClient()
        guard let (graphQLClient, _) = try? MockAWSAppSyncClientGenerator.generate(logger: .testLogger, sudoUserClient: sudoUserClient) else {
            return
        }
        self.sudoApiClient = graphQLClient
    }

    // MARK: - Conformance: AppSyncClientHelper
    
    func getHttpEndpoint() -> String {
        getHttpEndpointCalled = true
        return "mockEndpoint"
    }

    func getSudoApiClient() -> SudoApiClient {
        getSudoApiClientCalled = true
        return sudoApiClient
    }
}
