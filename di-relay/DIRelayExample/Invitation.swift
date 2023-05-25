//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// An invitation sent and received between peers.
struct Invitation: Codable {
    var connectionId: String
    var publicKey: String
}

/// An encrypted text, `cipherText` and the encrypting key `encryptedKey`.
struct EncryptedPayload: Codable {
    var cipherText: String
    var encryptedKey: String
}
