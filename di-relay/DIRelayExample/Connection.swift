//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// A connection object to be stored.
struct Connection: Codable {
    var myConnectionId: String
    var peerConnectionId: String
}

protocol ConnectionStorage {
    /// Attempt to retrieve the peer connection ID stored against `myConnectionId`
    /// - Parameter myConnectionId: The connection ID of this connection to retrieve the peer's connection Id
    /// - Throws: `Errors.FailedToDecodeValue`
    /// - Returns: The peer connection ID or nil
    func retrieve(for myConnectionId: String) throws -> String?

    /// Attempt to store the `peerConnectionId` against `myConnectionId`
    /// - Parameters:
    ///   - peerConnectionId: Connection ID of the peer to store as the value
    ///   - myConnectionId: Connection ID of this connection to store as the key
    /// - Throws: `Errors.FailedToEncodeValue`
    func store(peerConnectionId: String, for myConnectionId: String) throws
}
class KeychainConnectionStorage: ConnectionStorage {
    private let keychain = CodableKeychainStorage<String>()

    func retrieve(for myConnectionId: String) throws -> String? {
        return try keychain.value(forKey: myConnectionId)
    }

    func store(peerConnectionId: String, for myConnectionId: String) throws {
        return try keychain.setValue(peerConnectionId, forKey: myConnectionId)
    }
}
