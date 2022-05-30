// swiftlint:disable all
//  This file was automatically generated and should not be edited.

import AWSAppSync

internal enum KeyFormat: RawRepresentable, Equatable, JSONDecodable, JSONEncodable {
  internal typealias RawValue = String
  case rsaPublicKey
  case spki
  /// Auto generated constant for unknown enum values
  case unknown(RawValue)

  internal init?(rawValue: RawValue) {
    switch rawValue {
      case "RSA_PUBLIC_KEY": self = .rsaPublicKey
      case "SPKI": self = .spki
      default: self = .unknown(rawValue)
    }
  }

  internal var rawValue: RawValue {
    switch self {
      case .rsaPublicKey: return "RSA_PUBLIC_KEY"
      case .spki: return "SPKI"
      case .unknown(let value): return value
    }
  }

  internal static func == (lhs: KeyFormat, rhs: KeyFormat) -> Bool {
    switch (lhs, rhs) {
      case (.rsaPublicKey, .rsaPublicKey): return true
      case (.spki, .spki): return true
      case (.unknown(let lhsValue), .unknown(let rhsValue)): return lhsValue == rhsValue
      default: return false
    }
  }
}

internal struct IdAsInput: GraphQLMapConvertible {
  internal var graphQLMap: GraphQLMap

  internal init(connectionId: GraphQLID) {
    graphQLMap = ["connectionId": connectionId]
  }

  internal var connectionId: GraphQLID {
    get {
      return graphQLMap["connectionId"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "connectionId")
    }
  }
}

internal enum Direction: RawRepresentable, Equatable, JSONDecodable, JSONEncodable {
  internal typealias RawValue = String
  case inbound
  case outbound
  /// Auto generated constant for unknown enum values
  case unknown(RawValue)

  internal init?(rawValue: RawValue) {
    switch rawValue {
      case "INBOUND": self = .inbound
      case "OUTBOUND": self = .outbound
      default: self = .unknown(rawValue)
    }
  }

  internal var rawValue: RawValue {
    switch self {
      case .inbound: return "INBOUND"
      case .outbound: return "OUTBOUND"
      case .unknown(let value): return value
    }
  }

  internal static func == (lhs: Direction, rhs: Direction) -> Bool {
    switch (lhs, rhs) {
      case (.inbound, .inbound): return true
      case (.outbound, .outbound): return true
      case (.unknown(let lhsValue), .unknown(let rhsValue)): return lhsValue == rhsValue
      default: return false
    }
  }
}

internal struct ListPostboxesForSudoIdInput: GraphQLMapConvertible {
  internal var graphQLMap: GraphQLMap

  internal init(sudoId: GraphQLID) {
    graphQLMap = ["sudoId": sudoId]
  }

  internal var sudoId: GraphQLID {
    get {
      return graphQLMap["sudoId"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "sudoId")
    }
  }
}

internal struct CreatePublicKeyInput: GraphQLMapConvertible {
  internal var graphQLMap: GraphQLMap

  internal init(keyId: String, keyRingId: String, algorithm: String, keyFormat: Optional<KeyFormat?> = nil, publicKey: String) {
    graphQLMap = ["keyId": keyId, "keyRingId": keyRingId, "algorithm": algorithm, "keyFormat": keyFormat, "publicKey": publicKey]
  }

  internal var keyId: String {
    get {
      return graphQLMap["keyId"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "keyId")
    }
  }

  internal var keyRingId: String {
    get {
      return graphQLMap["keyRingId"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "keyRingId")
    }
  }

  internal var algorithm: String {
    get {
      return graphQLMap["algorithm"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "algorithm")
    }
  }

  internal var keyFormat: Optional<KeyFormat?> {
    get {
      return graphQLMap["keyFormat"] as! Optional<KeyFormat?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "keyFormat")
    }
  }

  internal var publicKey: String {
    get {
      return graphQLMap["publicKey"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "publicKey")
    }
  }
}

internal struct DeletePublicKeyInput: GraphQLMapConvertible {
  internal var graphQLMap: GraphQLMap

  internal init(keyId: String) {
    graphQLMap = ["keyId": keyId]
  }

  internal var keyId: String {
    get {
      return graphQLMap["keyId"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "keyId")
    }
  }
}

internal struct CreatePostboxInput: GraphQLMapConvertible {
  internal var graphQLMap: GraphQLMap

  internal init(connectionId: GraphQLID, ownershipProofTokens: [String]) {
    graphQLMap = ["connectionId": connectionId, "ownershipProofTokens": ownershipProofTokens]
  }

  internal var connectionId: GraphQLID {
    get {
      return graphQLMap["connectionId"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "connectionId")
    }
  }

  internal var ownershipProofTokens: [String] {
    get {
      return graphQLMap["ownershipProofTokens"] as! [String]
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ownershipProofTokens")
    }
  }
}

internal struct WriteToRelayInput: GraphQLMapConvertible {
  internal var graphQLMap: GraphQLMap

  internal init(messageId: GraphQLID, connectionId: GraphQLID, cipherText: String, direction: Direction, utcTimestamp: Double) {
    graphQLMap = ["messageId": messageId, "connectionId": connectionId, "cipherText": cipherText, "direction": direction, "utcTimestamp": utcTimestamp]
  }

  internal var messageId: GraphQLID {
    get {
      return graphQLMap["messageId"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "messageId")
    }
  }

  internal var connectionId: GraphQLID {
    get {
      return graphQLMap["connectionId"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "connectionId")
    }
  }

  internal var cipherText: String {
    get {
      return graphQLMap["cipherText"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "cipherText")
    }
  }

  internal var direction: Direction {
    get {
      return graphQLMap["direction"] as! Direction
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "direction")
    }
  }

  internal var utcTimestamp: Double {
    get {
      return graphQLMap["utcTimestamp"] as! Double
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "utcTimestamp")
    }
  }
}

internal struct PostBoxDeletionInput: GraphQLMapConvertible {
  internal var graphQLMap: GraphQLMap

  internal init(connectionId: GraphQLID, remainingMessages: [TableKeyAsInput]) {
    graphQLMap = ["connectionId": connectionId, "remainingMessages": remainingMessages]
  }

  internal var connectionId: GraphQLID {
    get {
      return graphQLMap["connectionId"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "connectionId")
    }
  }

  internal var remainingMessages: [TableKeyAsInput] {
    get {
      return graphQLMap["remainingMessages"] as! [TableKeyAsInput]
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "remainingMessages")
    }
  }
}

internal struct TableKeyAsInput: GraphQLMapConvertible {
  internal var graphQLMap: GraphQLMap

  internal init(connectionId: GraphQLID, messageId: GraphQLID) {
    graphQLMap = ["connectionId": connectionId, "messageId": messageId]
  }

  internal var connectionId: GraphQLID {
    get {
      return graphQLMap["connectionId"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "connectionId")
    }
  }

  internal var messageId: GraphQLID {
    get {
      return graphQLMap["messageId"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "messageId")
    }
  }
}

internal final class GetPublicKeyForRelayQuery: GraphQLQuery {
  internal static let operationString =
    "query GetPublicKeyForRelay($keyId: String!, $keyFormats: [KeyFormat!]) {\n  getPublicKeyForRelay(keyId: $keyId, keyFormats: $keyFormats) {\n    __typename\n    id\n    keyId\n    keyRingId\n    algorithm\n    keyFormat\n    publicKey\n    owner\n    version\n    createdAtEpochMs\n    updatedAtEpochMs\n  }\n}"

  internal var keyId: String
  internal var keyFormats: [KeyFormat]?

  internal init(keyId: String, keyFormats: [KeyFormat]?) {
    self.keyId = keyId
    self.keyFormats = keyFormats
  }

  internal var variables: GraphQLMap? {
    return ["keyId": keyId, "keyFormats": keyFormats]
  }

  internal struct Data: GraphQLSelectionSet {
    internal static let possibleTypes = ["Query"]

    internal static let selections: [GraphQLSelection] = [
      GraphQLField("getPublicKeyForRelay", arguments: ["keyId": GraphQLVariable("keyId"), "keyFormats": GraphQLVariable("keyFormats")], type: .object(GetPublicKeyForRelay.selections)),
    ]

    internal var snapshot: Snapshot

    internal init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    internal init(getPublicKeyForRelay: GetPublicKeyForRelay? = nil) {
      self.init(snapshot: ["__typename": "Query", "getPublicKeyForRelay": getPublicKeyForRelay.flatMap { $0.snapshot }])
    }

    internal var getPublicKeyForRelay: GetPublicKeyForRelay? {
      get {
        return (snapshot["getPublicKeyForRelay"] as? Snapshot).flatMap { GetPublicKeyForRelay(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "getPublicKeyForRelay")
      }
    }

    internal struct GetPublicKeyForRelay: GraphQLSelectionSet {
      internal static let possibleTypes = ["PublicKey"]

      internal static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("keyId", type: .nonNull(.scalar(String.self))),
        GraphQLField("keyRingId", type: .nonNull(.scalar(String.self))),
        GraphQLField("algorithm", type: .nonNull(.scalar(String.self))),
        GraphQLField("keyFormat", type: .scalar(KeyFormat.self)),
        GraphQLField("publicKey", type: .nonNull(.scalar(String.self))),
        GraphQLField("owner", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("createdAtEpochMs", type: .nonNull(.scalar(Double.self))),
        GraphQLField("updatedAtEpochMs", type: .nonNull(.scalar(Double.self))),
      ]

      internal var snapshot: Snapshot

      internal init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      internal init(id: GraphQLID, keyId: String, keyRingId: String, algorithm: String, keyFormat: KeyFormat? = nil, publicKey: String, owner: GraphQLID, version: Int, createdAtEpochMs: Double, updatedAtEpochMs: Double) {
        self.init(snapshot: ["__typename": "PublicKey", "id": id, "keyId": keyId, "keyRingId": keyRingId, "algorithm": algorithm, "keyFormat": keyFormat, "publicKey": publicKey, "owner": owner, "version": version, "createdAtEpochMs": createdAtEpochMs, "updatedAtEpochMs": updatedAtEpochMs])
      }

      internal var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      internal var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      internal var keyId: String {
        get {
          return snapshot["keyId"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "keyId")
        }
      }

      internal var keyRingId: String {
        get {
          return snapshot["keyRingId"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "keyRingId")
        }
      }

      internal var algorithm: String {
        get {
          return snapshot["algorithm"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "algorithm")
        }
      }

      internal var keyFormat: KeyFormat? {
        get {
          return snapshot["keyFormat"] as? KeyFormat
        }
        set {
          snapshot.updateValue(newValue, forKey: "keyFormat")
        }
      }

      internal var publicKey: String {
        get {
          return snapshot["publicKey"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "publicKey")
        }
      }

      internal var owner: GraphQLID {
        get {
          return snapshot["owner"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }

      internal var version: Int {
        get {
          return snapshot["version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "version")
        }
      }

      internal var createdAtEpochMs: Double {
        get {
          return snapshot["createdAtEpochMs"]! as! Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAtEpochMs")
        }
      }

      internal var updatedAtEpochMs: Double {
        get {
          return snapshot["updatedAtEpochMs"]! as! Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAtEpochMs")
        }
      }
    }
  }
}

internal final class GetPublicKeysForRelayQuery: GraphQLQuery {
  internal static let operationString =
    "query GetPublicKeysForRelay($limit: Int, $nextToken: String, $keyFormats: [KeyFormat!]) {\n  getPublicKeysForRelay(limit: $limit, nextToken: $nextToken, keyFormats: $keyFormats) {\n    __typename\n    items {\n      __typename\n      id\n      keyId\n      keyRingId\n      algorithm\n      keyFormat\n      publicKey\n      owner\n      version\n      createdAtEpochMs\n      updatedAtEpochMs\n    }\n    nextToken\n  }\n}"

  internal var limit: Int?
  internal var nextToken: String?
  internal var keyFormats: [KeyFormat]?

  internal init(limit: Int? = nil, nextToken: String? = nil, keyFormats: [KeyFormat]?) {
    self.limit = limit
    self.nextToken = nextToken
    self.keyFormats = keyFormats
  }

  internal var variables: GraphQLMap? {
    return ["limit": limit, "nextToken": nextToken, "keyFormats": keyFormats]
  }

  internal struct Data: GraphQLSelectionSet {
    internal static let possibleTypes = ["Query"]

    internal static let selections: [GraphQLSelection] = [
      GraphQLField("getPublicKeysForRelay", arguments: ["limit": GraphQLVariable("limit"), "nextToken": GraphQLVariable("nextToken"), "keyFormats": GraphQLVariable("keyFormats")], type: .nonNull(.object(GetPublicKeysForRelay.selections))),
    ]

    internal var snapshot: Snapshot

    internal init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    internal init(getPublicKeysForRelay: GetPublicKeysForRelay) {
      self.init(snapshot: ["__typename": "Query", "getPublicKeysForRelay": getPublicKeysForRelay.snapshot])
    }

    internal var getPublicKeysForRelay: GetPublicKeysForRelay {
      get {
        return GetPublicKeysForRelay(snapshot: snapshot["getPublicKeysForRelay"]! as! Snapshot)
      }
      set {
        snapshot.updateValue(newValue.snapshot, forKey: "getPublicKeysForRelay")
      }
    }

    internal struct GetPublicKeysForRelay: GraphQLSelectionSet {
      internal static let possibleTypes = ["PaginatedPublicKey"]

      internal static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("items", type: .nonNull(.list(.nonNull(.object(Item.selections))))),
        GraphQLField("nextToken", type: .scalar(String.self)),
      ]

      internal var snapshot: Snapshot

      internal init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      internal init(items: [Item], nextToken: String? = nil) {
        self.init(snapshot: ["__typename": "PaginatedPublicKey", "items": items.map { $0.snapshot }, "nextToken": nextToken])
      }

      internal var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      internal var items: [Item] {
        get {
          return (snapshot["items"] as! [Snapshot]).map { Item(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "items")
        }
      }

      internal var nextToken: String? {
        get {
          return snapshot["nextToken"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "nextToken")
        }
      }

      internal struct Item: GraphQLSelectionSet {
        internal static let possibleTypes = ["PublicKey"]

        internal static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("keyId", type: .nonNull(.scalar(String.self))),
          GraphQLField("keyRingId", type: .nonNull(.scalar(String.self))),
          GraphQLField("algorithm", type: .nonNull(.scalar(String.self))),
          GraphQLField("keyFormat", type: .scalar(KeyFormat.self)),
          GraphQLField("publicKey", type: .nonNull(.scalar(String.self))),
          GraphQLField("owner", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("createdAtEpochMs", type: .nonNull(.scalar(Double.self))),
          GraphQLField("updatedAtEpochMs", type: .nonNull(.scalar(Double.self))),
        ]

        internal var snapshot: Snapshot

        internal init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        internal init(id: GraphQLID, keyId: String, keyRingId: String, algorithm: String, keyFormat: KeyFormat? = nil, publicKey: String, owner: GraphQLID, version: Int, createdAtEpochMs: Double, updatedAtEpochMs: Double) {
          self.init(snapshot: ["__typename": "PublicKey", "id": id, "keyId": keyId, "keyRingId": keyRingId, "algorithm": algorithm, "keyFormat": keyFormat, "publicKey": publicKey, "owner": owner, "version": version, "createdAtEpochMs": createdAtEpochMs, "updatedAtEpochMs": updatedAtEpochMs])
        }

        internal var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        internal var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        internal var keyId: String {
          get {
            return snapshot["keyId"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "keyId")
          }
        }

        internal var keyRingId: String {
          get {
            return snapshot["keyRingId"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "keyRingId")
          }
        }

        internal var algorithm: String {
          get {
            return snapshot["algorithm"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "algorithm")
          }
        }

        internal var keyFormat: KeyFormat? {
          get {
            return snapshot["keyFormat"] as? KeyFormat
          }
          set {
            snapshot.updateValue(newValue, forKey: "keyFormat")
          }
        }

        internal var publicKey: String {
          get {
            return snapshot["publicKey"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "publicKey")
          }
        }

        internal var owner: GraphQLID {
          get {
            return snapshot["owner"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "owner")
          }
        }

        internal var version: Int {
          get {
            return snapshot["version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "version")
          }
        }

        internal var createdAtEpochMs: Double {
          get {
            return snapshot["createdAtEpochMs"]! as! Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAtEpochMs")
          }
        }

        internal var updatedAtEpochMs: Double {
          get {
            return snapshot["updatedAtEpochMs"]! as! Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAtEpochMs")
          }
        }
      }
    }
  }
}

internal final class GetKeyRingForRelayQuery: GraphQLQuery {
  internal static let operationString =
    "query GetKeyRingForRelay($keyRingId: String!, $limit: Int, $nextToken: String, $keyFormats: [KeyFormat!]) {\n  getKeyRingForRelay(keyRingId: $keyRingId, limit: $limit, nextToken: $nextToken, keyFormats: $keyFormats) {\n    __typename\n    items {\n      __typename\n      id\n      keyId\n      keyRingId\n      algorithm\n      keyFormat\n      publicKey\n      owner\n      version\n      createdAtEpochMs\n      updatedAtEpochMs\n    }\n    nextToken\n  }\n}"

  internal var keyRingId: String
  internal var limit: Int?
  internal var nextToken: String?
  internal var keyFormats: [KeyFormat]?

  internal init(keyRingId: String, limit: Int? = nil, nextToken: String? = nil, keyFormats: [KeyFormat]?) {
    self.keyRingId = keyRingId
    self.limit = limit
    self.nextToken = nextToken
    self.keyFormats = keyFormats
  }

  internal var variables: GraphQLMap? {
    return ["keyRingId": keyRingId, "limit": limit, "nextToken": nextToken, "keyFormats": keyFormats]
  }

  internal struct Data: GraphQLSelectionSet {
    internal static let possibleTypes = ["Query"]

    internal static let selections: [GraphQLSelection] = [
      GraphQLField("getKeyRingForRelay", arguments: ["keyRingId": GraphQLVariable("keyRingId"), "limit": GraphQLVariable("limit"), "nextToken": GraphQLVariable("nextToken"), "keyFormats": GraphQLVariable("keyFormats")], type: .nonNull(.object(GetKeyRingForRelay.selections))),
    ]

    internal var snapshot: Snapshot

    internal init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    internal init(getKeyRingForRelay: GetKeyRingForRelay) {
      self.init(snapshot: ["__typename": "Query", "getKeyRingForRelay": getKeyRingForRelay.snapshot])
    }

    internal var getKeyRingForRelay: GetKeyRingForRelay {
      get {
        return GetKeyRingForRelay(snapshot: snapshot["getKeyRingForRelay"]! as! Snapshot)
      }
      set {
        snapshot.updateValue(newValue.snapshot, forKey: "getKeyRingForRelay")
      }
    }

    internal struct GetKeyRingForRelay: GraphQLSelectionSet {
      internal static let possibleTypes = ["PaginatedPublicKey"]

      internal static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("items", type: .nonNull(.list(.nonNull(.object(Item.selections))))),
        GraphQLField("nextToken", type: .scalar(String.self)),
      ]

      internal var snapshot: Snapshot

      internal init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      internal init(items: [Item], nextToken: String? = nil) {
        self.init(snapshot: ["__typename": "PaginatedPublicKey", "items": items.map { $0.snapshot }, "nextToken": nextToken])
      }

      internal var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      internal var items: [Item] {
        get {
          return (snapshot["items"] as! [Snapshot]).map { Item(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "items")
        }
      }

      internal var nextToken: String? {
        get {
          return snapshot["nextToken"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "nextToken")
        }
      }

      internal struct Item: GraphQLSelectionSet {
        internal static let possibleTypes = ["PublicKey"]

        internal static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("keyId", type: .nonNull(.scalar(String.self))),
          GraphQLField("keyRingId", type: .nonNull(.scalar(String.self))),
          GraphQLField("algorithm", type: .nonNull(.scalar(String.self))),
          GraphQLField("keyFormat", type: .scalar(KeyFormat.self)),
          GraphQLField("publicKey", type: .nonNull(.scalar(String.self))),
          GraphQLField("owner", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("createdAtEpochMs", type: .nonNull(.scalar(Double.self))),
          GraphQLField("updatedAtEpochMs", type: .nonNull(.scalar(Double.self))),
        ]

        internal var snapshot: Snapshot

        internal init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        internal init(id: GraphQLID, keyId: String, keyRingId: String, algorithm: String, keyFormat: KeyFormat? = nil, publicKey: String, owner: GraphQLID, version: Int, createdAtEpochMs: Double, updatedAtEpochMs: Double) {
          self.init(snapshot: ["__typename": "PublicKey", "id": id, "keyId": keyId, "keyRingId": keyRingId, "algorithm": algorithm, "keyFormat": keyFormat, "publicKey": publicKey, "owner": owner, "version": version, "createdAtEpochMs": createdAtEpochMs, "updatedAtEpochMs": updatedAtEpochMs])
        }

        internal var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        internal var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        internal var keyId: String {
          get {
            return snapshot["keyId"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "keyId")
          }
        }

        internal var keyRingId: String {
          get {
            return snapshot["keyRingId"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "keyRingId")
          }
        }

        internal var algorithm: String {
          get {
            return snapshot["algorithm"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "algorithm")
          }
        }

        internal var keyFormat: KeyFormat? {
          get {
            return snapshot["keyFormat"] as? KeyFormat
          }
          set {
            snapshot.updateValue(newValue, forKey: "keyFormat")
          }
        }

        internal var publicKey: String {
          get {
            return snapshot["publicKey"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "publicKey")
          }
        }

        internal var owner: GraphQLID {
          get {
            return snapshot["owner"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "owner")
          }
        }

        internal var version: Int {
          get {
            return snapshot["version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "version")
          }
        }

        internal var createdAtEpochMs: Double {
          get {
            return snapshot["createdAtEpochMs"]! as! Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAtEpochMs")
          }
        }

        internal var updatedAtEpochMs: Double {
          get {
            return snapshot["updatedAtEpochMs"]! as! Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAtEpochMs")
          }
        }
      }
    }
  }
}

internal final class GetMessagesQuery: GraphQLQuery {
  internal static let operationString =
    "query GetMessages($input: IdAsInput!) {\n  getMessages(input: $input) {\n    __typename\n    messageId\n    connectionId\n    cipherText\n    direction\n    utcTimestamp\n  }\n}"

  internal var input: IdAsInput

  internal init(input: IdAsInput) {
    self.input = input
  }

  internal var variables: GraphQLMap? {
    return ["input": input]
  }

  internal struct Data: GraphQLSelectionSet {
    internal static let possibleTypes = ["Query"]

    internal static let selections: [GraphQLSelection] = [
      GraphQLField("getMessages", arguments: ["input": GraphQLVariable("input")], type: .nonNull(.list(.object(GetMessage.selections)))),
    ]

    internal var snapshot: Snapshot

    internal init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    internal init(getMessages: [GetMessage?]) {
      self.init(snapshot: ["__typename": "Query", "getMessages": getMessages.map { $0.flatMap { $0.snapshot } }])
    }

    internal var getMessages: [GetMessage?] {
      get {
        return (snapshot["getMessages"] as! [Snapshot?]).map { $0.flatMap { GetMessage(snapshot: $0) } }
      }
      set {
        snapshot.updateValue(newValue.map { $0.flatMap { $0.snapshot } }, forKey: "getMessages")
      }
    }

    internal struct GetMessage: GraphQLSelectionSet {
      internal static let possibleTypes = ["MessageEntry"]

      internal static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("messageId", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("connectionId", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("cipherText", type: .nonNull(.scalar(String.self))),
        GraphQLField("direction", type: .nonNull(.scalar(Direction.self))),
        GraphQLField("utcTimestamp", type: .nonNull(.scalar(Double.self))),
      ]

      internal var snapshot: Snapshot

      internal init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      internal init(messageId: GraphQLID, connectionId: GraphQLID, cipherText: String, direction: Direction, utcTimestamp: Double) {
        self.init(snapshot: ["__typename": "MessageEntry", "messageId": messageId, "connectionId": connectionId, "cipherText": cipherText, "direction": direction, "utcTimestamp": utcTimestamp])
      }

      internal var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      internal var messageId: GraphQLID {
        get {
          return snapshot["messageId"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "messageId")
        }
      }

      internal var connectionId: GraphQLID {
        get {
          return snapshot["connectionId"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "connectionId")
        }
      }

      internal var cipherText: String {
        get {
          return snapshot["cipherText"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "cipherText")
        }
      }

      internal var direction: Direction {
        get {
          return snapshot["direction"]! as! Direction
        }
        set {
          snapshot.updateValue(newValue, forKey: "direction")
        }
      }

      internal var utcTimestamp: Double {
        get {
          return snapshot["utcTimestamp"]! as! Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "utcTimestamp")
        }
      }
    }
  }
}

internal final class ListPostboxesForSudoIdQuery: GraphQLQuery {
  internal static let operationString =
    "query ListPostboxesForSudoId($input: ListPostboxesForSudoIdInput) {\n  listPostboxesForSudoId(input: $input) {\n    __typename\n    connectionId\n    sudoId\n    owner\n    utcTimestamp\n  }\n}"

  internal var input: ListPostboxesForSudoIdInput?

  internal init(input: ListPostboxesForSudoIdInput? = nil) {
    self.input = input
  }

  internal var variables: GraphQLMap? {
    return ["input": input]
  }

  internal struct Data: GraphQLSelectionSet {
    internal static let possibleTypes = ["Query"]

    internal static let selections: [GraphQLSelection] = [
      GraphQLField("listPostboxesForSudoId", arguments: ["input": GraphQLVariable("input")], type: .nonNull(.list(.object(ListPostboxesForSudoId.selections)))),
    ]

    internal var snapshot: Snapshot

    internal init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    internal init(listPostboxesForSudoId: [ListPostboxesForSudoId?]) {
      self.init(snapshot: ["__typename": "Query", "listPostboxesForSudoId": listPostboxesForSudoId.map { $0.flatMap { $0.snapshot } }])
    }

    internal var listPostboxesForSudoId: [ListPostboxesForSudoId?] {
      get {
        return (snapshot["listPostboxesForSudoId"] as! [Snapshot?]).map { $0.flatMap { ListPostboxesForSudoId(snapshot: $0) } }
      }
      set {
        snapshot.updateValue(newValue.map { $0.flatMap { $0.snapshot } }, forKey: "listPostboxesForSudoId")
      }
    }

    internal struct ListPostboxesForSudoId: GraphQLSelectionSet {
      internal static let possibleTypes = ["ListPostboxesForSudoIdResult"]

      internal static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("connectionId", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("sudoId", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("owner", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("utcTimestamp", type: .nonNull(.scalar(Double.self))),
      ]

      internal var snapshot: Snapshot

      internal init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      internal init(connectionId: GraphQLID, sudoId: GraphQLID, owner: GraphQLID, utcTimestamp: Double) {
        self.init(snapshot: ["__typename": "ListPostboxesForSudoIdResult", "connectionId": connectionId, "sudoId": sudoId, "owner": owner, "utcTimestamp": utcTimestamp])
      }

      internal var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      internal var connectionId: GraphQLID {
        get {
          return snapshot["connectionId"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "connectionId")
        }
      }

      internal var sudoId: GraphQLID {
        get {
          return snapshot["sudoId"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "sudoId")
        }
      }

      internal var owner: GraphQLID {
        get {
          return snapshot["owner"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }

      internal var utcTimestamp: Double {
        get {
          return snapshot["utcTimestamp"]! as! Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "utcTimestamp")
        }
      }
    }
  }
}

internal final class CreatePublicKeyForRelayMutation: GraphQLMutation {
  internal static let operationString =
    "mutation CreatePublicKeyForRelay($input: CreatePublicKeyInput!) {\n  createPublicKeyForRelay(input: $input) {\n    __typename\n    id\n    keyId\n    keyRingId\n    algorithm\n    keyFormat\n    publicKey\n    owner\n    version\n    createdAtEpochMs\n    updatedAtEpochMs\n  }\n}"

  internal var input: CreatePublicKeyInput

  internal init(input: CreatePublicKeyInput) {
    self.input = input
  }

  internal var variables: GraphQLMap? {
    return ["input": input]
  }

  internal struct Data: GraphQLSelectionSet {
    internal static let possibleTypes = ["Mutation"]

    internal static let selections: [GraphQLSelection] = [
      GraphQLField("createPublicKeyForRelay", arguments: ["input": GraphQLVariable("input")], type: .nonNull(.object(CreatePublicKeyForRelay.selections))),
    ]

    internal var snapshot: Snapshot

    internal init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    internal init(createPublicKeyForRelay: CreatePublicKeyForRelay) {
      self.init(snapshot: ["__typename": "Mutation", "createPublicKeyForRelay": createPublicKeyForRelay.snapshot])
    }

    internal var createPublicKeyForRelay: CreatePublicKeyForRelay {
      get {
        return CreatePublicKeyForRelay(snapshot: snapshot["createPublicKeyForRelay"]! as! Snapshot)
      }
      set {
        snapshot.updateValue(newValue.snapshot, forKey: "createPublicKeyForRelay")
      }
    }

    internal struct CreatePublicKeyForRelay: GraphQLSelectionSet {
      internal static let possibleTypes = ["PublicKey"]

      internal static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("keyId", type: .nonNull(.scalar(String.self))),
        GraphQLField("keyRingId", type: .nonNull(.scalar(String.self))),
        GraphQLField("algorithm", type: .nonNull(.scalar(String.self))),
        GraphQLField("keyFormat", type: .scalar(KeyFormat.self)),
        GraphQLField("publicKey", type: .nonNull(.scalar(String.self))),
        GraphQLField("owner", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("createdAtEpochMs", type: .nonNull(.scalar(Double.self))),
        GraphQLField("updatedAtEpochMs", type: .nonNull(.scalar(Double.self))),
      ]

      internal var snapshot: Snapshot

      internal init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      internal init(id: GraphQLID, keyId: String, keyRingId: String, algorithm: String, keyFormat: KeyFormat? = nil, publicKey: String, owner: GraphQLID, version: Int, createdAtEpochMs: Double, updatedAtEpochMs: Double) {
        self.init(snapshot: ["__typename": "PublicKey", "id": id, "keyId": keyId, "keyRingId": keyRingId, "algorithm": algorithm, "keyFormat": keyFormat, "publicKey": publicKey, "owner": owner, "version": version, "createdAtEpochMs": createdAtEpochMs, "updatedAtEpochMs": updatedAtEpochMs])
      }

      internal var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      internal var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      internal var keyId: String {
        get {
          return snapshot["keyId"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "keyId")
        }
      }

      internal var keyRingId: String {
        get {
          return snapshot["keyRingId"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "keyRingId")
        }
      }

      internal var algorithm: String {
        get {
          return snapshot["algorithm"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "algorithm")
        }
      }

      internal var keyFormat: KeyFormat? {
        get {
          return snapshot["keyFormat"] as? KeyFormat
        }
        set {
          snapshot.updateValue(newValue, forKey: "keyFormat")
        }
      }

      internal var publicKey: String {
        get {
          return snapshot["publicKey"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "publicKey")
        }
      }

      internal var owner: GraphQLID {
        get {
          return snapshot["owner"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }

      internal var version: Int {
        get {
          return snapshot["version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "version")
        }
      }

      internal var createdAtEpochMs: Double {
        get {
          return snapshot["createdAtEpochMs"]! as! Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAtEpochMs")
        }
      }

      internal var updatedAtEpochMs: Double {
        get {
          return snapshot["updatedAtEpochMs"]! as! Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAtEpochMs")
        }
      }
    }
  }
}

internal final class DeletePublicKeyForRelayMutation: GraphQLMutation {
  internal static let operationString =
    "mutation DeletePublicKeyForRelay($input: DeletePublicKeyInput) {\n  deletePublicKeyForRelay(input: $input) {\n    __typename\n    id\n    keyId\n    keyRingId\n    algorithm\n    keyFormat\n    publicKey\n    owner\n    version\n    createdAtEpochMs\n    updatedAtEpochMs\n  }\n}"

  internal var input: DeletePublicKeyInput?

  internal init(input: DeletePublicKeyInput? = nil) {
    self.input = input
  }

  internal var variables: GraphQLMap? {
    return ["input": input]
  }

  internal struct Data: GraphQLSelectionSet {
    internal static let possibleTypes = ["Mutation"]

    internal static let selections: [GraphQLSelection] = [
      GraphQLField("deletePublicKeyForRelay", arguments: ["input": GraphQLVariable("input")], type: .object(DeletePublicKeyForRelay.selections)),
    ]

    internal var snapshot: Snapshot

    internal init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    internal init(deletePublicKeyForRelay: DeletePublicKeyForRelay? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "deletePublicKeyForRelay": deletePublicKeyForRelay.flatMap { $0.snapshot }])
    }

    internal var deletePublicKeyForRelay: DeletePublicKeyForRelay? {
      get {
        return (snapshot["deletePublicKeyForRelay"] as? Snapshot).flatMap { DeletePublicKeyForRelay(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "deletePublicKeyForRelay")
      }
    }

    internal struct DeletePublicKeyForRelay: GraphQLSelectionSet {
      internal static let possibleTypes = ["PublicKey"]

      internal static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("keyId", type: .nonNull(.scalar(String.self))),
        GraphQLField("keyRingId", type: .nonNull(.scalar(String.self))),
        GraphQLField("algorithm", type: .nonNull(.scalar(String.self))),
        GraphQLField("keyFormat", type: .scalar(KeyFormat.self)),
        GraphQLField("publicKey", type: .nonNull(.scalar(String.self))),
        GraphQLField("owner", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("createdAtEpochMs", type: .nonNull(.scalar(Double.self))),
        GraphQLField("updatedAtEpochMs", type: .nonNull(.scalar(Double.self))),
      ]

      internal var snapshot: Snapshot

      internal init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      internal init(id: GraphQLID, keyId: String, keyRingId: String, algorithm: String, keyFormat: KeyFormat? = nil, publicKey: String, owner: GraphQLID, version: Int, createdAtEpochMs: Double, updatedAtEpochMs: Double) {
        self.init(snapshot: ["__typename": "PublicKey", "id": id, "keyId": keyId, "keyRingId": keyRingId, "algorithm": algorithm, "keyFormat": keyFormat, "publicKey": publicKey, "owner": owner, "version": version, "createdAtEpochMs": createdAtEpochMs, "updatedAtEpochMs": updatedAtEpochMs])
      }

      internal var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      internal var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      internal var keyId: String {
        get {
          return snapshot["keyId"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "keyId")
        }
      }

      internal var keyRingId: String {
        get {
          return snapshot["keyRingId"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "keyRingId")
        }
      }

      internal var algorithm: String {
        get {
          return snapshot["algorithm"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "algorithm")
        }
      }

      internal var keyFormat: KeyFormat? {
        get {
          return snapshot["keyFormat"] as? KeyFormat
        }
        set {
          snapshot.updateValue(newValue, forKey: "keyFormat")
        }
      }

      internal var publicKey: String {
        get {
          return snapshot["publicKey"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "publicKey")
        }
      }

      internal var owner: GraphQLID {
        get {
          return snapshot["owner"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }

      internal var version: Int {
        get {
          return snapshot["version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "version")
        }
      }

      internal var createdAtEpochMs: Double {
        get {
          return snapshot["createdAtEpochMs"]! as! Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAtEpochMs")
        }
      }

      internal var updatedAtEpochMs: Double {
        get {
          return snapshot["updatedAtEpochMs"]! as! Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAtEpochMs")
        }
      }
    }
  }
}

internal final class SendInitMutation: GraphQLMutation {
  internal static let operationString =
    "mutation SendInit($input: CreatePostboxInput!) {\n  sendInit(input: $input) {\n    __typename\n    connectionId\n    owner\n    utcTimestamp\n  }\n}"

  internal var input: CreatePostboxInput

  internal init(input: CreatePostboxInput) {
    self.input = input
  }

  internal var variables: GraphQLMap? {
    return ["input": input]
  }

  internal struct Data: GraphQLSelectionSet {
    internal static let possibleTypes = ["Mutation"]

    internal static let selections: [GraphQLSelection] = [
      GraphQLField("sendInit", arguments: ["input": GraphQLVariable("input")], type: .object(SendInit.selections)),
    ]

    internal var snapshot: Snapshot

    internal init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    internal init(sendInit: SendInit? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "sendInit": sendInit.flatMap { $0.snapshot }])
    }

    internal var sendInit: SendInit? {
      get {
        return (snapshot["sendInit"] as? Snapshot).flatMap { SendInit(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "sendInit")
      }
    }

    internal struct SendInit: GraphQLSelectionSet {
      internal static let possibleTypes = ["CreatePostboxResult"]

      internal static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("connectionId", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("owner", type: .nonNull(.scalar(String.self))),
        GraphQLField("utcTimestamp", type: .nonNull(.scalar(Double.self))),
      ]

      internal var snapshot: Snapshot

      internal init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      internal init(connectionId: GraphQLID, owner: String, utcTimestamp: Double) {
        self.init(snapshot: ["__typename": "CreatePostboxResult", "connectionId": connectionId, "owner": owner, "utcTimestamp": utcTimestamp])
      }

      internal var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      internal var connectionId: GraphQLID {
        get {
          return snapshot["connectionId"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "connectionId")
        }
      }

      internal var owner: String {
        get {
          return snapshot["owner"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }

      internal var utcTimestamp: Double {
        get {
          return snapshot["utcTimestamp"]! as! Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "utcTimestamp")
        }
      }
    }
  }
}

internal final class StoreMessageMutation: GraphQLMutation {
  internal static let operationString =
    "mutation StoreMessage($input: WriteToRelayInput!) {\n  storeMessage(input: $input) {\n    __typename\n    messageId\n    connectionId\n    cipherText\n    direction\n    utcTimestamp\n  }\n}"

  internal var input: WriteToRelayInput

  internal init(input: WriteToRelayInput) {
    self.input = input
  }

  internal var variables: GraphQLMap? {
    return ["input": input]
  }

  internal struct Data: GraphQLSelectionSet {
    internal static let possibleTypes = ["Mutation"]

    internal static let selections: [GraphQLSelection] = [
      GraphQLField("storeMessage", arguments: ["input": GraphQLVariable("input")], type: .object(StoreMessage.selections)),
    ]

    internal var snapshot: Snapshot

    internal init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    internal init(storeMessage: StoreMessage? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "storeMessage": storeMessage.flatMap { $0.snapshot }])
    }

    internal var storeMessage: StoreMessage? {
      get {
        return (snapshot["storeMessage"] as? Snapshot).flatMap { StoreMessage(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "storeMessage")
      }
    }

    internal struct StoreMessage: GraphQLSelectionSet {
      internal static let possibleTypes = ["MessageEntry"]

      internal static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("messageId", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("connectionId", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("cipherText", type: .nonNull(.scalar(String.self))),
        GraphQLField("direction", type: .nonNull(.scalar(Direction.self))),
        GraphQLField("utcTimestamp", type: .nonNull(.scalar(Double.self))),
      ]

      internal var snapshot: Snapshot

      internal init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      internal init(messageId: GraphQLID, connectionId: GraphQLID, cipherText: String, direction: Direction, utcTimestamp: Double) {
        self.init(snapshot: ["__typename": "MessageEntry", "messageId": messageId, "connectionId": connectionId, "cipherText": cipherText, "direction": direction, "utcTimestamp": utcTimestamp])
      }

      internal var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      internal var messageId: GraphQLID {
        get {
          return snapshot["messageId"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "messageId")
        }
      }

      internal var connectionId: GraphQLID {
        get {
          return snapshot["connectionId"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "connectionId")
        }
      }

      internal var cipherText: String {
        get {
          return snapshot["cipherText"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "cipherText")
        }
      }

      internal var direction: Direction {
        get {
          return snapshot["direction"]! as! Direction
        }
        set {
          snapshot.updateValue(newValue, forKey: "direction")
        }
      }

      internal var utcTimestamp: Double {
        get {
          return snapshot["utcTimestamp"]! as! Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "utcTimestamp")
        }
      }
    }
  }
}

internal final class DeletePostBoxMutation: GraphQLMutation {
  internal static let operationString =
    "mutation DeletePostBox($input: IdAsInput!) {\n  deletePostBox(input: $input) {\n    __typename\n    status\n  }\n}"

  internal var input: IdAsInput

  internal init(input: IdAsInput) {
    self.input = input
  }

  internal var variables: GraphQLMap? {
    return ["input": input]
  }

  internal struct Data: GraphQLSelectionSet {
    internal static let possibleTypes = ["Mutation"]

    internal static let selections: [GraphQLSelection] = [
      GraphQLField("deletePostBox", arguments: ["input": GraphQLVariable("input")], type: .nonNull(.object(DeletePostBox.selections))),
    ]

    internal var snapshot: Snapshot

    internal init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    internal init(deletePostBox: DeletePostBox) {
      self.init(snapshot: ["__typename": "Mutation", "deletePostBox": deletePostBox.snapshot])
    }

    internal var deletePostBox: DeletePostBox {
      get {
        return DeletePostBox(snapshot: snapshot["deletePostBox"]! as! Snapshot)
      }
      set {
        snapshot.updateValue(newValue.snapshot, forKey: "deletePostBox")
      }
    }

    internal struct DeletePostBox: GraphQLSelectionSet {
      internal static let possibleTypes = ["AsyncInvokeStatus"]

      internal static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("status", type: .nonNull(.scalar(Int.self))),
      ]

      internal var snapshot: Snapshot

      internal init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      internal init(status: Int) {
        self.init(snapshot: ["__typename": "AsyncInvokeStatus", "status": status])
      }

      internal var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      internal var status: Int {
        get {
          return snapshot["status"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "status")
        }
      }
    }
  }
}

internal final class InternalFireOnPostBoxDeletedMutation: GraphQLMutation {
  internal static let operationString =
    "mutation InternalFireOnPostBoxDeleted($input: PostBoxDeletionInput!) {\n  internalFireOnPostBoxDeleted(input: $input) {\n    __typename\n    connectionId\n    remainingMessages {\n      __typename\n      connectionId\n      messageId\n    }\n  }\n}"

  internal var input: PostBoxDeletionInput

  internal init(input: PostBoxDeletionInput) {
    self.input = input
  }

  internal var variables: GraphQLMap? {
    return ["input": input]
  }

  internal struct Data: GraphQLSelectionSet {
    internal static let possibleTypes = ["Mutation"]

    internal static let selections: [GraphQLSelection] = [
      GraphQLField("internalFireOnPostBoxDeleted", arguments: ["input": GraphQLVariable("input")], type: .object(InternalFireOnPostBoxDeleted.selections)),
    ]

    internal var snapshot: Snapshot

    internal init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    internal init(internalFireOnPostBoxDeleted: InternalFireOnPostBoxDeleted? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "internalFireOnPostBoxDeleted": internalFireOnPostBoxDeleted.flatMap { $0.snapshot }])
    }

    internal var internalFireOnPostBoxDeleted: InternalFireOnPostBoxDeleted? {
      get {
        return (snapshot["internalFireOnPostBoxDeleted"] as? Snapshot).flatMap { InternalFireOnPostBoxDeleted(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "internalFireOnPostBoxDeleted")
      }
    }

    internal struct InternalFireOnPostBoxDeleted: GraphQLSelectionSet {
      internal static let possibleTypes = ["PostBoxDeletionResult"]

      internal static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("connectionId", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("remainingMessages", type: .nonNull(.list(.nonNull(.object(RemainingMessage.selections))))),
      ]

      internal var snapshot: Snapshot

      internal init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      internal init(connectionId: GraphQLID, remainingMessages: [RemainingMessage]) {
        self.init(snapshot: ["__typename": "PostBoxDeletionResult", "connectionId": connectionId, "remainingMessages": remainingMessages.map { $0.snapshot }])
      }

      internal var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      internal var connectionId: GraphQLID {
        get {
          return snapshot["connectionId"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "connectionId")
        }
      }

      internal var remainingMessages: [RemainingMessage] {
        get {
          return (snapshot["remainingMessages"] as! [Snapshot]).map { RemainingMessage(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "remainingMessages")
        }
      }

      internal struct RemainingMessage: GraphQLSelectionSet {
        internal static let possibleTypes = ["MessageTableKey"]

        internal static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("connectionId", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("messageId", type: .nonNull(.scalar(GraphQLID.self))),
        ]

        internal var snapshot: Snapshot

        internal init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        internal init(connectionId: GraphQLID, messageId: GraphQLID) {
          self.init(snapshot: ["__typename": "MessageTableKey", "connectionId": connectionId, "messageId": messageId])
        }

        internal var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        internal var connectionId: GraphQLID {
          get {
            return snapshot["connectionId"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "connectionId")
          }
        }

        internal var messageId: GraphQLID {
          get {
            return snapshot["messageId"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "messageId")
          }
        }
      }
    }
  }
}

internal final class InternalFireOnMessageReceivedMutation: GraphQLMutation {
  internal static let operationString =
    "mutation InternalFireOnMessageReceived($input: WriteToRelayInput) {\n  internalFireOnMessageReceived(input: $input) {\n    __typename\n    messageId\n    connectionId\n    cipherText\n    direction\n    utcTimestamp\n  }\n}"

  internal var input: WriteToRelayInput?

  internal init(input: WriteToRelayInput? = nil) {
    self.input = input
  }

  internal var variables: GraphQLMap? {
    return ["input": input]
  }

  internal struct Data: GraphQLSelectionSet {
    internal static let possibleTypes = ["Mutation"]

    internal static let selections: [GraphQLSelection] = [
      GraphQLField("internalFireOnMessageReceived", arguments: ["input": GraphQLVariable("input")], type: .object(InternalFireOnMessageReceived.selections)),
    ]

    internal var snapshot: Snapshot

    internal init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    internal init(internalFireOnMessageReceived: InternalFireOnMessageReceived? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "internalFireOnMessageReceived": internalFireOnMessageReceived.flatMap { $0.snapshot }])
    }

    internal var internalFireOnMessageReceived: InternalFireOnMessageReceived? {
      get {
        return (snapshot["internalFireOnMessageReceived"] as? Snapshot).flatMap { InternalFireOnMessageReceived(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "internalFireOnMessageReceived")
      }
    }

    internal struct InternalFireOnMessageReceived: GraphQLSelectionSet {
      internal static let possibleTypes = ["MessageEntry"]

      internal static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("messageId", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("connectionId", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("cipherText", type: .nonNull(.scalar(String.self))),
        GraphQLField("direction", type: .nonNull(.scalar(Direction.self))),
        GraphQLField("utcTimestamp", type: .nonNull(.scalar(Double.self))),
      ]

      internal var snapshot: Snapshot

      internal init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      internal init(messageId: GraphQLID, connectionId: GraphQLID, cipherText: String, direction: Direction, utcTimestamp: Double) {
        self.init(snapshot: ["__typename": "MessageEntry", "messageId": messageId, "connectionId": connectionId, "cipherText": cipherText, "direction": direction, "utcTimestamp": utcTimestamp])
      }

      internal var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      internal var messageId: GraphQLID {
        get {
          return snapshot["messageId"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "messageId")
        }
      }

      internal var connectionId: GraphQLID {
        get {
          return snapshot["connectionId"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "connectionId")
        }
      }

      internal var cipherText: String {
        get {
          return snapshot["cipherText"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "cipherText")
        }
      }

      internal var direction: Direction {
        get {
          return snapshot["direction"]! as! Direction
        }
        set {
          snapshot.updateValue(newValue, forKey: "direction")
        }
      }

      internal var utcTimestamp: Double {
        get {
          return snapshot["utcTimestamp"]! as! Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "utcTimestamp")
        }
      }
    }
  }
}

internal final class PingSubscription: GraphQLSubscription {
  internal static let operationString =
    "subscription Ping {\n  ping\n}"

  internal init() {
  }

  internal struct Data: GraphQLSelectionSet {
    internal static let possibleTypes = ["Subscription"]

    internal static let selections: [GraphQLSelection] = [
      GraphQLField("ping", type: .scalar(String.self)),
    ]

    internal var snapshot: Snapshot

    internal init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    internal init(ping: String? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "ping": ping])
    }

    internal var ping: String? {
      get {
        return snapshot["ping"] as? String
      }
      set {
        snapshot.updateValue(newValue, forKey: "ping")
      }
    }
  }
}

internal final class OnMessageCreatedSubscription: GraphQLSubscription {
  internal static let operationString =
    "subscription OnMessageCreated($connectionId: ID!, $direction: Direction!) {\n  onMessageCreated(connectionId: $connectionId, direction: $direction) {\n    __typename\n    messageId\n    connectionId\n    cipherText\n    direction\n    utcTimestamp\n  }\n}"

  internal var connectionId: GraphQLID
  internal var direction: Direction

  internal init(connectionId: GraphQLID, direction: Direction) {
    self.connectionId = connectionId
    self.direction = direction
  }

  internal var variables: GraphQLMap? {
    return ["connectionId": connectionId, "direction": direction]
  }

  internal struct Data: GraphQLSelectionSet {
    internal static let possibleTypes = ["Subscription"]

    internal static let selections: [GraphQLSelection] = [
      GraphQLField("onMessageCreated", arguments: ["connectionId": GraphQLVariable("connectionId"), "direction": GraphQLVariable("direction")], type: .object(OnMessageCreated.selections)),
    ]

    internal var snapshot: Snapshot

    internal init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    internal init(onMessageCreated: OnMessageCreated? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onMessageCreated": onMessageCreated.flatMap { $0.snapshot }])
    }

    internal var onMessageCreated: OnMessageCreated? {
      get {
        return (snapshot["onMessageCreated"] as? Snapshot).flatMap { OnMessageCreated(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onMessageCreated")
      }
    }

    internal struct OnMessageCreated: GraphQLSelectionSet {
      internal static let possibleTypes = ["MessageEntry"]

      internal static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("messageId", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("connectionId", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("cipherText", type: .nonNull(.scalar(String.self))),
        GraphQLField("direction", type: .nonNull(.scalar(Direction.self))),
        GraphQLField("utcTimestamp", type: .nonNull(.scalar(Double.self))),
      ]

      internal var snapshot: Snapshot

      internal init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      internal init(messageId: GraphQLID, connectionId: GraphQLID, cipherText: String, direction: Direction, utcTimestamp: Double) {
        self.init(snapshot: ["__typename": "MessageEntry", "messageId": messageId, "connectionId": connectionId, "cipherText": cipherText, "direction": direction, "utcTimestamp": utcTimestamp])
      }

      internal var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      internal var messageId: GraphQLID {
        get {
          return snapshot["messageId"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "messageId")
        }
      }

      internal var connectionId: GraphQLID {
        get {
          return snapshot["connectionId"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "connectionId")
        }
      }

      internal var cipherText: String {
        get {
          return snapshot["cipherText"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "cipherText")
        }
      }

      internal var direction: Direction {
        get {
          return snapshot["direction"]! as! Direction
        }
        set {
          snapshot.updateValue(newValue, forKey: "direction")
        }
      }

      internal var utcTimestamp: Double {
        get {
          return snapshot["utcTimestamp"]! as! Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "utcTimestamp")
        }
      }
    }
  }
}

internal final class OnPostBoxDeletedSubscription: GraphQLSubscription {
  internal static let operationString =
    "subscription OnPostBoxDeleted($connectionId: ID!) {\n  onPostBoxDeleted(connectionId: $connectionId) {\n    __typename\n    connectionId\n    remainingMessages {\n      __typename\n      connectionId\n      messageId\n    }\n  }\n}"

  internal var connectionId: GraphQLID

  internal init(connectionId: GraphQLID) {
    self.connectionId = connectionId
  }

  internal var variables: GraphQLMap? {
    return ["connectionId": connectionId]
  }

  internal struct Data: GraphQLSelectionSet {
    internal static let possibleTypes = ["Subscription"]

    internal static let selections: [GraphQLSelection] = [
      GraphQLField("onPostBoxDeleted", arguments: ["connectionId": GraphQLVariable("connectionId")], type: .object(OnPostBoxDeleted.selections)),
    ]

    internal var snapshot: Snapshot

    internal init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    internal init(onPostBoxDeleted: OnPostBoxDeleted? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onPostBoxDeleted": onPostBoxDeleted.flatMap { $0.snapshot }])
    }

    internal var onPostBoxDeleted: OnPostBoxDeleted? {
      get {
        return (snapshot["onPostBoxDeleted"] as? Snapshot).flatMap { OnPostBoxDeleted(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onPostBoxDeleted")
      }
    }

    internal struct OnPostBoxDeleted: GraphQLSelectionSet {
      internal static let possibleTypes = ["PostBoxDeletionResult"]

      internal static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("connectionId", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("remainingMessages", type: .nonNull(.list(.nonNull(.object(RemainingMessage.selections))))),
      ]

      internal var snapshot: Snapshot

      internal init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      internal init(connectionId: GraphQLID, remainingMessages: [RemainingMessage]) {
        self.init(snapshot: ["__typename": "PostBoxDeletionResult", "connectionId": connectionId, "remainingMessages": remainingMessages.map { $0.snapshot }])
      }

      internal var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      internal var connectionId: GraphQLID {
        get {
          return snapshot["connectionId"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "connectionId")
        }
      }

      internal var remainingMessages: [RemainingMessage] {
        get {
          return (snapshot["remainingMessages"] as! [Snapshot]).map { RemainingMessage(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "remainingMessages")
        }
      }

      internal struct RemainingMessage: GraphQLSelectionSet {
        internal static let possibleTypes = ["MessageTableKey"]

        internal static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("connectionId", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("messageId", type: .nonNull(.scalar(GraphQLID.self))),
        ]

        internal var snapshot: Snapshot

        internal init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        internal init(connectionId: GraphQLID, messageId: GraphQLID) {
          self.init(snapshot: ["__typename": "MessageTableKey", "connectionId": connectionId, "messageId": messageId])
        }

        internal var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        internal var connectionId: GraphQLID {
          get {
            return snapshot["connectionId"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "connectionId")
          }
        }

        internal var messageId: GraphQLID {
          get {
            return snapshot["messageId"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "messageId")
          }
        }
      }
    }
  }
}