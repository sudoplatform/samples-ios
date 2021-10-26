//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Key attribute names used for export and importing keys.
///
/// - name: Key name as `String`.
/// - type: Key type. See `KeyType`.
/// - data: Raw key data as `NSData`.
/// - version: Key version as `Int`.
/// - synchronizable: `Bool` value indicating whether or not the key is synchronizable between multiple devices.
/// - exportable: `Bool` value indicating whether or not the key is exportable.
/// - namespace: Key namespace.
/// - id: Fully qualified key identifier including namespace and any prefix specific to the key type.
public enum KeyAttributeName: String {
    case name = "Name"
    case type = "Type"
    case data = "Data"
    case version = "Version"
    case synchronizable = "Synchronizable"
    case exportable = "Exportable"
    case namespace = "NameSpace"
    case id = "Id"
}
