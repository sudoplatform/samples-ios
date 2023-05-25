//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import DIRelayExample


class MockKeychainPostboxIdStorage: KeychainPostboxIdStorage {

    var retrieveCalled = false
    var retrieveReturn: [String]? = []

    override func retrieve() throws -> [String]? {
        self.retrieveCalled = true
        return self.retrieveReturn
    }

    var storeCalled = false
    var storeParamPostboxId = ""

    override func store(postboxId: String) throws {
        self.storeCalled = true
        self.storeParamPostboxId = postboxId
    }

    var deleteCalled = false
    var deleteParamPostboxId = ""

    override func delete(postBoxId: String) {
        self.deleteCalled = true
        self.deleteParamPostboxId = postBoxId
    }}
