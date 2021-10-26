//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

protocol PostboxIdStorage {

    /// Retrieve all postbox IDs from the storage.
    /// - Throws: `Errors.FailedToDecodeValue`.
    /// - Returns: A list of all postbox IDs or nil if unable to retrieve.
    func retrieve() throws -> [String]?

    /// Attempt to store `postboxId` in the storage.
    /// - Parameter postboxId: Postbox ID to store in list.
    /// - Throws: `Errors.FailedToDecodeValue`
    ///           `Errors.FailedToEncodeValue`
    func store(postboxId: String) throws

    /// Delete `postboxId` from the storage
    /// - Parameter postBoxId: Postbox ID to delete from storage
    func delete(postBoxId: String)
}

class KeychainPostboxIdStorage: PostboxIdStorage {
    private let keychain = CodableKeychainStorage<[String]>()
    private let keychainEntryId = "postboxes"
    

    func retrieve() throws -> [String]? {
        return try keychain.value(forKey: keychainEntryId)
    }

    func store(postboxId: String) throws {
        var postboxIds: [String] = []
        postboxIds.append(postboxId)
        if let existingIds = try self.retrieve() {
            postboxIds.append(contentsOf: existingIds)
        }
        try keychain.setValue(postboxIds, forKey: keychainEntryId)
    }

    func delete(postBoxId: String) {
        if var existingIds = try? self.retrieve() {
            existingIds = existingIds.filter(){$0 != postBoxId}
            try? keychain.setValue(existingIds, forKey: keychainEntryId)
        }
    }
}
