//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SudoDecentralizedIdentity

protocol DIDDocStorage {
    func retrieve(for did: String) throws -> DidDoc?
    func store(doc: DidDoc, for did: String) throws
}

extension DIDDocStorage {
    func retrieve(for did: Did) throws -> DidDoc? {
        return try retrieve(for: did.did)
    }

    func store(doc: DidDoc, for did: Did) throws {
        try store(doc: doc, for: did.did)
    }
}

class KeychainDIDDocStorage: DIDDocStorage {
    private let keychain = CodableKeychainStorage<DidDoc>()

    func retrieve(for did: String) throws -> DidDoc? {
        return try keychain.value(forKey: did)
    }

    func store(doc: DidDoc, for did: String) throws {
        try keychain.setValue(doc, forKey: did)
    }
}
