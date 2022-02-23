// swiftlint:disable all
//  This file was automatically generated and should not be edited.

import AWSAppSync

public enum KeyFormat: RawRepresentable, Equatable, JSONDecodable, JSONEncodable {
  public typealias RawValue = String
  case rsaPublicKey
  case spki
  /// Auto generated constant for unknown enum values
  case unknown(RawValue)

  public init?(rawValue: RawValue) {
    switch rawValue {
      case "RSA_PUBLIC_KEY": self = .rsaPublicKey
      case "SPKI": self = .spki
      default: self = .unknown(rawValue)
    }
  }

  public var rawValue: RawValue {
    switch self {
      case .rsaPublicKey: return "RSA_PUBLIC_KEY"
      case .spki: return "SPKI"
      case .unknown(let value): return value
    }
  }

  public static func == (lhs: KeyFormat, rhs: KeyFormat) -> Bool {
    switch (lhs, rhs) {
      case (.rsaPublicKey, .rsaPublicKey): return true
      case (.spki, .spki): return true
      case (.unknown(let lhsValue), .unknown(let rhsValue)): return lhsValue == rhsValue
      default: return false
    }
  }
}

public struct IdAsInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(connectionId: GraphQLID) {
    graphQLMap = ["connectionId": connectionId]
  }

  public var connectionId: GraphQLID {
    get {
      return graphQLMap["connectionId"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "connectionId")
    }
  }
}

public enum Direction: RawRepresentable, Equatable, JSONDecodable, JSONEncodable {
  public typealias RawValue = String
  case inbound
  case outbound
  /// Auto generated constant for unknown enum values
  case unknown(RawValue)

  public init?(rawValue: RawValue) {
    switch rawValue {
      case "INBOUND": self = .inbound
      case "OUTBOUND": self = .outbound
      default: self = .unknown(rawValue)
    }
  }

  public var rawValue: RawValue {
    switch self {
      case .inbound: return "INBOUND"
      case .outbound: return "OUTBOUND"
      case .unknown(let value): return value
    }
  }

  public static func == (lhs: Direction, rhs: Direction) -> Bool {
    switch (lhs, rhs) {
      case (.inbound, .inbound): return true
      case (.outbound, .outbound): return true
      case (.unknown(let lhsValue), .unknown(let rhsValue)): return lhsValue == rhsValue
      default: return false
    }
  }
}

public struct CreatePublicKeyInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(keyId: String, keyRingId: String, algorithm: String, keyFormat: Optional<KeyFormat?> = nil, publicKey: String) {
    graphQLMap = ["keyId": keyId, "keyRingId": keyRingId, "algorithm": algorithm, "keyFormat": keyFormat, "publicKey": publicKey]
  }

  public var keyId: String {
    get {
      return graphQLMap["keyId"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "keyId")
    }
  }

  public var keyRingId: String {
    get {
      return graphQLMap["keyRingId"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "keyRingId")
    }
  }

  public var algorithm: String {
    get {
      return graphQLMap["algorithm"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "algorithm")
    }
  }

  public var keyFormat: Optional<KeyFormat?> {
    get {
      return graphQLMap["keyFormat"] as! Optional<KeyFormat?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "keyFormat")
    }
  }

  public var publicKey: String {
    get {
      return graphQLMap["publicKey"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "publicKey")
    }
  }
}

public struct DeletePublicKeyInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(keyId: String) {
    graphQLMap = ["keyId": keyId]
  }

  public var keyId: String {
    get {
      return graphQLMap["keyId"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "keyId")
    }
  }
}

public struct WriteToRelayInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(messageId: GraphQLID, connectionId: GraphQLID, cipherText: String, direction: Direction, utcTimestamp: Double) {
    graphQLMap = ["messageId": messageId, "connectionId": connectionId, "cipherText": cipherText, "direction": direction, "utcTimestamp": utcTimestamp]
  }

  public var messageId: GraphQLID {
    get {
      return graphQLMap["messageId"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "messageId")
    }
  }

  public var connectionId: GraphQLID {
    get {
      return graphQLMap["connectionId"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "connectionId")
    }
  }

  public var cipherText: String {
    get {
      return graphQLMap["cipherText"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "cipherText")
    }
  }

  public var direction: Direction {
    get {
      return graphQLMap["direction"] as! Direction
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "direction")
    }
  }

  public var utcTimestamp: Double {
    get {
      return graphQLMap["utcTimestamp"] as! Double
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "utcTimestamp")
    }
  }
}

public struct PostBoxDeletionInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(connectionId: GraphQLID, remainingMessages: [TableKeyAsInput]) {
    graphQLMap = ["connectionId": connectionId, "remainingMessages": remainingMessages]
  }

  public var connectionId: GraphQLID {
    get {
      return graphQLMap["connectionId"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "connectionId")
    }
  }

  public var remainingMessages: [TableKeyAsInput] {
    get {
      return graphQLMap["remainingMessages"] as! [TableKeyAsInput]
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "remainingMessages")
    }
  }
}

public struct TableKeyAsInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(connectionId: GraphQLID, messageId: GraphQLID) {
    graphQLMap = ["connectionId": connectionId, "messageId": messageId]
  }

  public var connectionId: GraphQLID {
    get {
      return graphQLMap["connectionId"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "connectionId")
    }
  }

  public var messageId: GraphQLID {
    get {
      return graphQLMap["messageId"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "messageId")
    }
  }
}

public final class GetPublicKeyForRelayQuery: GraphQLQuery {
  public static let operationString =
    "query GetPublicKeyForRelay($keyId: String!, $keyFormats: [KeyFormat!]) {\n  getPublicKeyForRelay(keyId: $keyId, keyFormats: $keyFormats) {\n    __typename\n    id\n    keyId\n    keyRingId\n    algorithm\n    keyFormat\n    publicKey\n    owner\n    version\n    createdAtEpochMs\n    updatedAtEpochMs\n  }\n}"

  public var keyId: String
  public var keyFormats: [KeyFormat]?

  public init(keyId: String, keyFormats: [KeyFormat]?) {
    self.keyId = keyId
    self.keyFormats = keyFormats
  }

  public var variables: GraphQLMap? {
    return ["keyId": keyId, "keyFormats": keyFormats]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("getPublicKeyForRelay", arguments: ["keyId": GraphQLVariable("keyId"), "keyFormats": GraphQLVariable("keyFormats")], type: .object(GetPublicKeyForRelay.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(getPublicKeyForRelay: GetPublicKeyForRelay? = nil) {
      self.init(snapshot: ["__typename": "Query", "getPublicKeyForRelay": getPublicKeyForRelay.flatMap { $0.snapshot }])
    }

    public var getPublicKeyForRelay: GetPublicKeyForRelay? {
      get {
        return (snapshot["getPublicKeyForRelay"] as? Snapshot).flatMap { GetPublicKeyForRelay(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "getPublicKeyForRelay")
      }
    }

    public struct GetPublicKeyForRelay: GraphQLSelectionSet {
      public static let possibleTypes = ["PublicKey"]

      public static let selections: [GraphQLSelection] = [
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

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, keyId: String, keyRingId: String, algorithm: String, keyFormat: KeyFormat? = nil, publicKey: String, owner: GraphQLID, version: Int, createdAtEpochMs: Double, updatedAtEpochMs: Double) {
        self.init(snapshot: ["__typename": "PublicKey", "id": id, "keyId": keyId, "keyRingId": keyRingId, "algorithm": algorithm, "keyFormat": keyFormat, "publicKey": publicKey, "owner": owner, "version": version, "createdAtEpochMs": createdAtEpochMs, "updatedAtEpochMs": updatedAtEpochMs])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var keyId: String {
        get {
          return snapshot["keyId"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "keyId")
        }
      }

      public var keyRingId: String {
        get {
          return snapshot["keyRingId"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "keyRingId")
        }
      }

      public var algorithm: String {
        get {
          return snapshot["algorithm"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "algorithm")
        }
      }

      public var keyFormat: KeyFormat? {
        get {
          return snapshot["keyFormat"] as? KeyFormat
        }
        set {
          snapshot.updateValue(newValue, forKey: "keyFormat")
        }
      }

      public var publicKey: String {
        get {
          return snapshot["publicKey"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "publicKey")
        }
      }

      public var owner: GraphQLID {
        get {
          return snapshot["owner"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }

      public var version: Int {
        get {
          return snapshot["version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "version")
        }
      }

      public var createdAtEpochMs: Double {
        get {
          return snapshot["createdAtEpochMs"]! as! Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAtEpochMs")
        }
      }

      public var updatedAtEpochMs: Double {
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

public final class GetPublicKeysForRelayQuery: GraphQLQuery {
  public static let operationString =
    "query GetPublicKeysForRelay($limit: Int, $nextToken: String, $keyFormats: [KeyFormat!]) {\n  getPublicKeysForRelay(limit: $limit, nextToken: $nextToken, keyFormats: $keyFormats) {\n    __typename\n    items {\n      __typename\n      id\n      keyId\n      keyRingId\n      algorithm\n      keyFormat\n      publicKey\n      owner\n      version\n      createdAtEpochMs\n      updatedAtEpochMs\n    }\n    nextToken\n  }\n}"

  public var limit: Int?
  public var nextToken: String?
  public var keyFormats: [KeyFormat]?

  public init(limit: Int? = nil, nextToken: String? = nil, keyFormats: [KeyFormat]?) {
    self.limit = limit
    self.nextToken = nextToken
    self.keyFormats = keyFormats
  }

  public var variables: GraphQLMap? {
    return ["limit": limit, "nextToken": nextToken, "keyFormats": keyFormats]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("getPublicKeysForRelay", arguments: ["limit": GraphQLVariable("limit"), "nextToken": GraphQLVariable("nextToken"), "keyFormats": GraphQLVariable("keyFormats")], type: .nonNull(.object(GetPublicKeysForRelay.selections))),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(getPublicKeysForRelay: GetPublicKeysForRelay) {
      self.init(snapshot: ["__typename": "Query", "getPublicKeysForRelay": getPublicKeysForRelay.snapshot])
    }

    public var getPublicKeysForRelay: GetPublicKeysForRelay {
      get {
        return GetPublicKeysForRelay(snapshot: snapshot["getPublicKeysForRelay"]! as! Snapshot)
      }
      set {
        snapshot.updateValue(newValue.snapshot, forKey: "getPublicKeysForRelay")
      }
    }

    public struct GetPublicKeysForRelay: GraphQLSelectionSet {
      public static let possibleTypes = ["PaginatedPublicKey"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("items", type: .nonNull(.list(.nonNull(.object(Item.selections))))),
        GraphQLField("nextToken", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(items: [Item], nextToken: String? = nil) {
        self.init(snapshot: ["__typename": "PaginatedPublicKey", "items": items.map { $0.snapshot }, "nextToken": nextToken])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var items: [Item] {
        get {
          return (snapshot["items"] as! [Snapshot]).map { Item(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "items")
        }
      }

      public var nextToken: String? {
        get {
          return snapshot["nextToken"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "nextToken")
        }
      }

      public struct Item: GraphQLSelectionSet {
        public static let possibleTypes = ["PublicKey"]

        public static let selections: [GraphQLSelection] = [
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

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, keyId: String, keyRingId: String, algorithm: String, keyFormat: KeyFormat? = nil, publicKey: String, owner: GraphQLID, version: Int, createdAtEpochMs: Double, updatedAtEpochMs: Double) {
          self.init(snapshot: ["__typename": "PublicKey", "id": id, "keyId": keyId, "keyRingId": keyRingId, "algorithm": algorithm, "keyFormat": keyFormat, "publicKey": publicKey, "owner": owner, "version": version, "createdAtEpochMs": createdAtEpochMs, "updatedAtEpochMs": updatedAtEpochMs])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var keyId: String {
          get {
            return snapshot["keyId"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "keyId")
          }
        }

        public var keyRingId: String {
          get {
            return snapshot["keyRingId"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "keyRingId")
          }
        }

        public var algorithm: String {
          get {
            return snapshot["algorithm"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "algorithm")
          }
        }

        public var keyFormat: KeyFormat? {
          get {
            return snapshot["keyFormat"] as? KeyFormat
          }
          set {
            snapshot.updateValue(newValue, forKey: "keyFormat")
          }
        }

        public var publicKey: String {
          get {
            return snapshot["publicKey"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "publicKey")
          }
        }

        public var owner: GraphQLID {
          get {
            return snapshot["owner"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "owner")
          }
        }

        public var version: Int {
          get {
            return snapshot["version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "version")
          }
        }

        public var createdAtEpochMs: Double {
          get {
            return snapshot["createdAtEpochMs"]! as! Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAtEpochMs")
          }
        }

        public var updatedAtEpochMs: Double {
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

public final class GetKeyRingForRelayQuery: GraphQLQuery {
  public static let operationString =
    "query GetKeyRingForRelay($keyRingId: String!, $limit: Int, $nextToken: String, $keyFormats: [KeyFormat!]) {\n  getKeyRingForRelay(keyRingId: $keyRingId, limit: $limit, nextToken: $nextToken, keyFormats: $keyFormats) {\n    __typename\n    items {\n      __typename\n      id\n      keyId\n      keyRingId\n      algorithm\n      keyFormat\n      publicKey\n      owner\n      version\n      createdAtEpochMs\n      updatedAtEpochMs\n    }\n    nextToken\n  }\n}"

  public var keyRingId: String
  public var limit: Int?
  public var nextToken: String?
  public var keyFormats: [KeyFormat]?

  public init(keyRingId: String, limit: Int? = nil, nextToken: String? = nil, keyFormats: [KeyFormat]?) {
    self.keyRingId = keyRingId
    self.limit = limit
    self.nextToken = nextToken
    self.keyFormats = keyFormats
  }

  public var variables: GraphQLMap? {
    return ["keyRingId": keyRingId, "limit": limit, "nextToken": nextToken, "keyFormats": keyFormats]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("getKeyRingForRelay", arguments: ["keyRingId": GraphQLVariable("keyRingId"), "limit": GraphQLVariable("limit"), "nextToken": GraphQLVariable("nextToken"), "keyFormats": GraphQLVariable("keyFormats")], type: .nonNull(.object(GetKeyRingForRelay.selections))),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(getKeyRingForRelay: GetKeyRingForRelay) {
      self.init(snapshot: ["__typename": "Query", "getKeyRingForRelay": getKeyRingForRelay.snapshot])
    }

    public var getKeyRingForRelay: GetKeyRingForRelay {
      get {
        return GetKeyRingForRelay(snapshot: snapshot["getKeyRingForRelay"]! as! Snapshot)
      }
      set {
        snapshot.updateValue(newValue.snapshot, forKey: "getKeyRingForRelay")
      }
    }

    public struct GetKeyRingForRelay: GraphQLSelectionSet {
      public static let possibleTypes = ["PaginatedPublicKey"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("items", type: .nonNull(.list(.nonNull(.object(Item.selections))))),
        GraphQLField("nextToken", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(items: [Item], nextToken: String? = nil) {
        self.init(snapshot: ["__typename": "PaginatedPublicKey", "items": items.map { $0.snapshot }, "nextToken": nextToken])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var items: [Item] {
        get {
          return (snapshot["items"] as! [Snapshot]).map { Item(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "items")
        }
      }

      public var nextToken: String? {
        get {
          return snapshot["nextToken"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "nextToken")
        }
      }

      public struct Item: GraphQLSelectionSet {
        public static let possibleTypes = ["PublicKey"]

        public static let selections: [GraphQLSelection] = [
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

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, keyId: String, keyRingId: String, algorithm: String, keyFormat: KeyFormat? = nil, publicKey: String, owner: GraphQLID, version: Int, createdAtEpochMs: Double, updatedAtEpochMs: Double) {
          self.init(snapshot: ["__typename": "PublicKey", "id": id, "keyId": keyId, "keyRingId": keyRingId, "algorithm": algorithm, "keyFormat": keyFormat, "publicKey": publicKey, "owner": owner, "version": version, "createdAtEpochMs": createdAtEpochMs, "updatedAtEpochMs": updatedAtEpochMs])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var keyId: String {
          get {
            return snapshot["keyId"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "keyId")
          }
        }

        public var keyRingId: String {
          get {
            return snapshot["keyRingId"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "keyRingId")
          }
        }

        public var algorithm: String {
          get {
            return snapshot["algorithm"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "algorithm")
          }
        }

        public var keyFormat: KeyFormat? {
          get {
            return snapshot["keyFormat"] as? KeyFormat
          }
          set {
            snapshot.updateValue(newValue, forKey: "keyFormat")
          }
        }

        public var publicKey: String {
          get {
            return snapshot["publicKey"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "publicKey")
          }
        }

        public var owner: GraphQLID {
          get {
            return snapshot["owner"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "owner")
          }
        }

        public var version: Int {
          get {
            return snapshot["version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "version")
          }
        }

        public var createdAtEpochMs: Double {
          get {
            return snapshot["createdAtEpochMs"]! as! Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAtEpochMs")
          }
        }

        public var updatedAtEpochMs: Double {
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

public final class GetMessagesQuery: GraphQLQuery {
  public static let operationString =
    "query GetMessages($input: IdAsInput!) {\n  getMessages(input: $input) {\n    __typename\n    messageId\n    connectionId\n    cipherText\n    direction\n    utcTimestamp\n  }\n}"

  public var input: IdAsInput

  public init(input: IdAsInput) {
    self.input = input
  }

  public var variables: GraphQLMap? {
    return ["input": input]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("getMessages", arguments: ["input": GraphQLVariable("input")], type: .nonNull(.list(.object(GetMessage.selections)))),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(getMessages: [GetMessage?]) {
      self.init(snapshot: ["__typename": "Query", "getMessages": getMessages.map { $0.flatMap { $0.snapshot } }])
    }

    public var getMessages: [GetMessage?] {
      get {
        return (snapshot["getMessages"] as! [Snapshot?]).map { $0.flatMap { GetMessage(snapshot: $0) } }
      }
      set {
        snapshot.updateValue(newValue.map { $0.flatMap { $0.snapshot } }, forKey: "getMessages")
      }
    }

    public struct GetMessage: GraphQLSelectionSet {
      public static let possibleTypes = ["MessageEntry"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("messageId", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("connectionId", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("cipherText", type: .nonNull(.scalar(String.self))),
        GraphQLField("direction", type: .nonNull(.scalar(Direction.self))),
        GraphQLField("utcTimestamp", type: .nonNull(.scalar(Double.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(messageId: GraphQLID, connectionId: GraphQLID, cipherText: String, direction: Direction, utcTimestamp: Double) {
        self.init(snapshot: ["__typename": "MessageEntry", "messageId": messageId, "connectionId": connectionId, "cipherText": cipherText, "direction": direction, "utcTimestamp": utcTimestamp])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var messageId: GraphQLID {
        get {
          return snapshot["messageId"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "messageId")
        }
      }

      public var connectionId: GraphQLID {
        get {
          return snapshot["connectionId"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "connectionId")
        }
      }

      public var cipherText: String {
        get {
          return snapshot["cipherText"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "cipherText")
        }
      }

      public var direction: Direction {
        get {
          return snapshot["direction"]! as! Direction
        }
        set {
          snapshot.updateValue(newValue, forKey: "direction")
        }
      }

      public var utcTimestamp: Double {
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

public final class CreatePublicKeyForRelayMutation: GraphQLMutation {
  public static let operationString =
    "mutation CreatePublicKeyForRelay($input: CreatePublicKeyInput!) {\n  createPublicKeyForRelay(input: $input) {\n    __typename\n    id\n    keyId\n    keyRingId\n    algorithm\n    keyFormat\n    publicKey\n    owner\n    version\n    createdAtEpochMs\n    updatedAtEpochMs\n  }\n}"

  public var input: CreatePublicKeyInput

  public init(input: CreatePublicKeyInput) {
    self.input = input
  }

  public var variables: GraphQLMap? {
    return ["input": input]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("createPublicKeyForRelay", arguments: ["input": GraphQLVariable("input")], type: .nonNull(.object(CreatePublicKeyForRelay.selections))),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(createPublicKeyForRelay: CreatePublicKeyForRelay) {
      self.init(snapshot: ["__typename": "Mutation", "createPublicKeyForRelay": createPublicKeyForRelay.snapshot])
    }

    public var createPublicKeyForRelay: CreatePublicKeyForRelay {
      get {
        return CreatePublicKeyForRelay(snapshot: snapshot["createPublicKeyForRelay"]! as! Snapshot)
      }
      set {
        snapshot.updateValue(newValue.snapshot, forKey: "createPublicKeyForRelay")
      }
    }

    public struct CreatePublicKeyForRelay: GraphQLSelectionSet {
      public static let possibleTypes = ["PublicKey"]

      public static let selections: [GraphQLSelection] = [
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

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, keyId: String, keyRingId: String, algorithm: String, keyFormat: KeyFormat? = nil, publicKey: String, owner: GraphQLID, version: Int, createdAtEpochMs: Double, updatedAtEpochMs: Double) {
        self.init(snapshot: ["__typename": "PublicKey", "id": id, "keyId": keyId, "keyRingId": keyRingId, "algorithm": algorithm, "keyFormat": keyFormat, "publicKey": publicKey, "owner": owner, "version": version, "createdAtEpochMs": createdAtEpochMs, "updatedAtEpochMs": updatedAtEpochMs])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var keyId: String {
        get {
          return snapshot["keyId"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "keyId")
        }
      }

      public var keyRingId: String {
        get {
          return snapshot["keyRingId"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "keyRingId")
        }
      }

      public var algorithm: String {
        get {
          return snapshot["algorithm"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "algorithm")
        }
      }

      public var keyFormat: KeyFormat? {
        get {
          return snapshot["keyFormat"] as? KeyFormat
        }
        set {
          snapshot.updateValue(newValue, forKey: "keyFormat")
        }
      }

      public var publicKey: String {
        get {
          return snapshot["publicKey"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "publicKey")
        }
      }

      public var owner: GraphQLID {
        get {
          return snapshot["owner"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }

      public var version: Int {
        get {
          return snapshot["version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "version")
        }
      }

      public var createdAtEpochMs: Double {
        get {
          return snapshot["createdAtEpochMs"]! as! Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAtEpochMs")
        }
      }

      public var updatedAtEpochMs: Double {
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

public final class DeletePublicKeyForRelayMutation: GraphQLMutation {
  public static let operationString =
    "mutation DeletePublicKeyForRelay($input: DeletePublicKeyInput) {\n  deletePublicKeyForRelay(input: $input) {\n    __typename\n    id\n    keyId\n    keyRingId\n    algorithm\n    keyFormat\n    publicKey\n    owner\n    version\n    createdAtEpochMs\n    updatedAtEpochMs\n  }\n}"

  public var input: DeletePublicKeyInput?

  public init(input: DeletePublicKeyInput? = nil) {
    self.input = input
  }

  public var variables: GraphQLMap? {
    return ["input": input]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("deletePublicKeyForRelay", arguments: ["input": GraphQLVariable("input")], type: .object(DeletePublicKeyForRelay.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(deletePublicKeyForRelay: DeletePublicKeyForRelay? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "deletePublicKeyForRelay": deletePublicKeyForRelay.flatMap { $0.snapshot }])
    }

    public var deletePublicKeyForRelay: DeletePublicKeyForRelay? {
      get {
        return (snapshot["deletePublicKeyForRelay"] as? Snapshot).flatMap { DeletePublicKeyForRelay(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "deletePublicKeyForRelay")
      }
    }

    public struct DeletePublicKeyForRelay: GraphQLSelectionSet {
      public static let possibleTypes = ["PublicKey"]

      public static let selections: [GraphQLSelection] = [
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

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, keyId: String, keyRingId: String, algorithm: String, keyFormat: KeyFormat? = nil, publicKey: String, owner: GraphQLID, version: Int, createdAtEpochMs: Double, updatedAtEpochMs: Double) {
        self.init(snapshot: ["__typename": "PublicKey", "id": id, "keyId": keyId, "keyRingId": keyRingId, "algorithm": algorithm, "keyFormat": keyFormat, "publicKey": publicKey, "owner": owner, "version": version, "createdAtEpochMs": createdAtEpochMs, "updatedAtEpochMs": updatedAtEpochMs])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var keyId: String {
        get {
          return snapshot["keyId"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "keyId")
        }
      }

      public var keyRingId: String {
        get {
          return snapshot["keyRingId"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "keyRingId")
        }
      }

      public var algorithm: String {
        get {
          return snapshot["algorithm"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "algorithm")
        }
      }

      public var keyFormat: KeyFormat? {
        get {
          return snapshot["keyFormat"] as? KeyFormat
        }
        set {
          snapshot.updateValue(newValue, forKey: "keyFormat")
        }
      }

      public var publicKey: String {
        get {
          return snapshot["publicKey"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "publicKey")
        }
      }

      public var owner: GraphQLID {
        get {
          return snapshot["owner"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }

      public var version: Int {
        get {
          return snapshot["version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "version")
        }
      }

      public var createdAtEpochMs: Double {
        get {
          return snapshot["createdAtEpochMs"]! as! Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAtEpochMs")
        }
      }

      public var updatedAtEpochMs: Double {
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

public final class SendInitMutation: GraphQLMutation {
  public static let operationString =
    "mutation SendInit($input: IdAsInput!) {\n  sendInit(input: $input) {\n    __typename\n    connectionId\n    owner\n    utcTimestamp\n  }\n}"

  public var input: IdAsInput

  public init(input: IdAsInput) {
    self.input = input
  }

  public var variables: GraphQLMap? {
    return ["input": input]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("sendInit", arguments: ["input": GraphQLVariable("input")], type: .object(SendInit.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(sendInit: SendInit? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "sendInit": sendInit.flatMap { $0.snapshot }])
    }

    public var sendInit: SendInit? {
      get {
        return (snapshot["sendInit"] as? Snapshot).flatMap { SendInit(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "sendInit")
      }
    }

    public struct SendInit: GraphQLSelectionSet {
      public static let possibleTypes = ["CreatePostboxResult"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("connectionId", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("owner", type: .nonNull(.scalar(String.self))),
        GraphQLField("utcTimestamp", type: .nonNull(.scalar(Double.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(connectionId: GraphQLID, owner: String, utcTimestamp: Double) {
        self.init(snapshot: ["__typename": "CreatePostboxResult", "connectionId": connectionId, "owner": owner, "utcTimestamp": utcTimestamp])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var connectionId: GraphQLID {
        get {
          return snapshot["connectionId"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "connectionId")
        }
      }

      public var owner: String {
        get {
          return snapshot["owner"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }

      public var utcTimestamp: Double {
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

public final class StoreMessageMutation: GraphQLMutation {
  public static let operationString =
    "mutation StoreMessage($input: WriteToRelayInput!) {\n  storeMessage(input: $input) {\n    __typename\n    messageId\n    connectionId\n    cipherText\n    direction\n    utcTimestamp\n  }\n}"

  public var input: WriteToRelayInput

  public init(input: WriteToRelayInput) {
    self.input = input
  }

  public var variables: GraphQLMap? {
    return ["input": input]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("storeMessage", arguments: ["input": GraphQLVariable("input")], type: .object(StoreMessage.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(storeMessage: StoreMessage? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "storeMessage": storeMessage.flatMap { $0.snapshot }])
    }

    public var storeMessage: StoreMessage? {
      get {
        return (snapshot["storeMessage"] as? Snapshot).flatMap { StoreMessage(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "storeMessage")
      }
    }

    public struct StoreMessage: GraphQLSelectionSet {
      public static let possibleTypes = ["MessageEntry"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("messageId", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("connectionId", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("cipherText", type: .nonNull(.scalar(String.self))),
        GraphQLField("direction", type: .nonNull(.scalar(Direction.self))),
        GraphQLField("utcTimestamp", type: .nonNull(.scalar(Double.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(messageId: GraphQLID, connectionId: GraphQLID, cipherText: String, direction: Direction, utcTimestamp: Double) {
        self.init(snapshot: ["__typename": "MessageEntry", "messageId": messageId, "connectionId": connectionId, "cipherText": cipherText, "direction": direction, "utcTimestamp": utcTimestamp])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var messageId: GraphQLID {
        get {
          return snapshot["messageId"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "messageId")
        }
      }

      public var connectionId: GraphQLID {
        get {
          return snapshot["connectionId"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "connectionId")
        }
      }

      public var cipherText: String {
        get {
          return snapshot["cipherText"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "cipherText")
        }
      }

      public var direction: Direction {
        get {
          return snapshot["direction"]! as! Direction
        }
        set {
          snapshot.updateValue(newValue, forKey: "direction")
        }
      }

      public var utcTimestamp: Double {
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

public final class DeletePostBoxMutation: GraphQLMutation {
  public static let operationString =
    "mutation DeletePostBox($input: IdAsInput!) {\n  deletePostBox(input: $input) {\n    __typename\n    status\n  }\n}"

  public var input: IdAsInput

  public init(input: IdAsInput) {
    self.input = input
  }

  public var variables: GraphQLMap? {
    return ["input": input]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("deletePostBox", arguments: ["input": GraphQLVariable("input")], type: .nonNull(.object(DeletePostBox.selections))),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(deletePostBox: DeletePostBox) {
      self.init(snapshot: ["__typename": "Mutation", "deletePostBox": deletePostBox.snapshot])
    }

    public var deletePostBox: DeletePostBox {
      get {
        return DeletePostBox(snapshot: snapshot["deletePostBox"]! as! Snapshot)
      }
      set {
        snapshot.updateValue(newValue.snapshot, forKey: "deletePostBox")
      }
    }

    public struct DeletePostBox: GraphQLSelectionSet {
      public static let possibleTypes = ["AsyncInvokeStatus"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("status", type: .nonNull(.scalar(Int.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(status: Int) {
        self.init(snapshot: ["__typename": "AsyncInvokeStatus", "status": status])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var status: Int {
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

public final class InternalFireOnPostBoxDeletedMutation: GraphQLMutation {
  public static let operationString =
    "mutation InternalFireOnPostBoxDeleted($input: PostBoxDeletionInput!) {\n  internalFireOnPostBoxDeleted(input: $input) {\n    __typename\n    connectionId\n    remainingMessages {\n      __typename\n      connectionId\n      messageId\n    }\n  }\n}"

  public var input: PostBoxDeletionInput

  public init(input: PostBoxDeletionInput) {
    self.input = input
  }

  public var variables: GraphQLMap? {
    return ["input": input]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("internalFireOnPostBoxDeleted", arguments: ["input": GraphQLVariable("input")], type: .object(InternalFireOnPostBoxDeleted.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(internalFireOnPostBoxDeleted: InternalFireOnPostBoxDeleted? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "internalFireOnPostBoxDeleted": internalFireOnPostBoxDeleted.flatMap { $0.snapshot }])
    }

    public var internalFireOnPostBoxDeleted: InternalFireOnPostBoxDeleted? {
      get {
        return (snapshot["internalFireOnPostBoxDeleted"] as? Snapshot).flatMap { InternalFireOnPostBoxDeleted(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "internalFireOnPostBoxDeleted")
      }
    }

    public struct InternalFireOnPostBoxDeleted: GraphQLSelectionSet {
      public static let possibleTypes = ["PostBoxDeletionResult"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("connectionId", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("remainingMessages", type: .nonNull(.list(.nonNull(.object(RemainingMessage.selections))))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(connectionId: GraphQLID, remainingMessages: [RemainingMessage]) {
        self.init(snapshot: ["__typename": "PostBoxDeletionResult", "connectionId": connectionId, "remainingMessages": remainingMessages.map { $0.snapshot }])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var connectionId: GraphQLID {
        get {
          return snapshot["connectionId"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "connectionId")
        }
      }

      public var remainingMessages: [RemainingMessage] {
        get {
          return (snapshot["remainingMessages"] as! [Snapshot]).map { RemainingMessage(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "remainingMessages")
        }
      }

      public struct RemainingMessage: GraphQLSelectionSet {
        public static let possibleTypes = ["MessageTableKey"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("connectionId", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("messageId", type: .nonNull(.scalar(GraphQLID.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(connectionId: GraphQLID, messageId: GraphQLID) {
          self.init(snapshot: ["__typename": "MessageTableKey", "connectionId": connectionId, "messageId": messageId])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var connectionId: GraphQLID {
          get {
            return snapshot["connectionId"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "connectionId")
          }
        }

        public var messageId: GraphQLID {
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

public final class InternalFireOnMessageReceivedMutation: GraphQLMutation {
  public static let operationString =
    "mutation InternalFireOnMessageReceived($input: WriteToRelayInput) {\n  internalFireOnMessageReceived(input: $input) {\n    __typename\n    messageId\n    connectionId\n    cipherText\n    direction\n    utcTimestamp\n  }\n}"

  public var input: WriteToRelayInput?

  public init(input: WriteToRelayInput? = nil) {
    self.input = input
  }

  public var variables: GraphQLMap? {
    return ["input": input]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("internalFireOnMessageReceived", arguments: ["input": GraphQLVariable("input")], type: .object(InternalFireOnMessageReceived.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(internalFireOnMessageReceived: InternalFireOnMessageReceived? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "internalFireOnMessageReceived": internalFireOnMessageReceived.flatMap { $0.snapshot }])
    }

    public var internalFireOnMessageReceived: InternalFireOnMessageReceived? {
      get {
        return (snapshot["internalFireOnMessageReceived"] as? Snapshot).flatMap { InternalFireOnMessageReceived(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "internalFireOnMessageReceived")
      }
    }

    public struct InternalFireOnMessageReceived: GraphQLSelectionSet {
      public static let possibleTypes = ["MessageEntry"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("messageId", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("connectionId", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("cipherText", type: .nonNull(.scalar(String.self))),
        GraphQLField("direction", type: .nonNull(.scalar(Direction.self))),
        GraphQLField("utcTimestamp", type: .nonNull(.scalar(Double.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(messageId: GraphQLID, connectionId: GraphQLID, cipherText: String, direction: Direction, utcTimestamp: Double) {
        self.init(snapshot: ["__typename": "MessageEntry", "messageId": messageId, "connectionId": connectionId, "cipherText": cipherText, "direction": direction, "utcTimestamp": utcTimestamp])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var messageId: GraphQLID {
        get {
          return snapshot["messageId"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "messageId")
        }
      }

      public var connectionId: GraphQLID {
        get {
          return snapshot["connectionId"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "connectionId")
        }
      }

      public var cipherText: String {
        get {
          return snapshot["cipherText"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "cipherText")
        }
      }

      public var direction: Direction {
        get {
          return snapshot["direction"]! as! Direction
        }
        set {
          snapshot.updateValue(newValue, forKey: "direction")
        }
      }

      public var utcTimestamp: Double {
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

public final class PingSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription Ping {\n  ping\n}"

  public init() {
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("ping", type: .scalar(String.self)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(ping: String? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "ping": ping])
    }

    public var ping: String? {
      get {
        return snapshot["ping"] as? String
      }
      set {
        snapshot.updateValue(newValue, forKey: "ping")
      }
    }
  }
}

public final class OnMessageCreatedSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription OnMessageCreated($connectionId: ID!, $direction: Direction!) {\n  onMessageCreated(connectionId: $connectionId, direction: $direction) {\n    __typename\n    messageId\n    connectionId\n    cipherText\n    direction\n    utcTimestamp\n  }\n}"

  public var connectionId: GraphQLID
  public var direction: Direction

  public init(connectionId: GraphQLID, direction: Direction) {
    self.connectionId = connectionId
    self.direction = direction
  }

  public var variables: GraphQLMap? {
    return ["connectionId": connectionId, "direction": direction]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("onMessageCreated", arguments: ["connectionId": GraphQLVariable("connectionId"), "direction": GraphQLVariable("direction")], type: .object(OnMessageCreated.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(onMessageCreated: OnMessageCreated? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onMessageCreated": onMessageCreated.flatMap { $0.snapshot }])
    }

    public var onMessageCreated: OnMessageCreated? {
      get {
        return (snapshot["onMessageCreated"] as? Snapshot).flatMap { OnMessageCreated(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onMessageCreated")
      }
    }

    public struct OnMessageCreated: GraphQLSelectionSet {
      public static let possibleTypes = ["MessageEntry"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("messageId", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("connectionId", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("cipherText", type: .nonNull(.scalar(String.self))),
        GraphQLField("direction", type: .nonNull(.scalar(Direction.self))),
        GraphQLField("utcTimestamp", type: .nonNull(.scalar(Double.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(messageId: GraphQLID, connectionId: GraphQLID, cipherText: String, direction: Direction, utcTimestamp: Double) {
        self.init(snapshot: ["__typename": "MessageEntry", "messageId": messageId, "connectionId": connectionId, "cipherText": cipherText, "direction": direction, "utcTimestamp": utcTimestamp])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var messageId: GraphQLID {
        get {
          return snapshot["messageId"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "messageId")
        }
      }

      public var connectionId: GraphQLID {
        get {
          return snapshot["connectionId"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "connectionId")
        }
      }

      public var cipherText: String {
        get {
          return snapshot["cipherText"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "cipherText")
        }
      }

      public var direction: Direction {
        get {
          return snapshot["direction"]! as! Direction
        }
        set {
          snapshot.updateValue(newValue, forKey: "direction")
        }
      }

      public var utcTimestamp: Double {
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

public final class OnPostBoxDeletedSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription OnPostBoxDeleted($connectionId: ID!) {\n  onPostBoxDeleted(connectionId: $connectionId) {\n    __typename\n    connectionId\n    remainingMessages {\n      __typename\n      connectionId\n      messageId\n    }\n  }\n}"

  public var connectionId: GraphQLID

  public init(connectionId: GraphQLID) {
    self.connectionId = connectionId
  }

  public var variables: GraphQLMap? {
    return ["connectionId": connectionId]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("onPostBoxDeleted", arguments: ["connectionId": GraphQLVariable("connectionId")], type: .object(OnPostBoxDeleted.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(onPostBoxDeleted: OnPostBoxDeleted? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onPostBoxDeleted": onPostBoxDeleted.flatMap { $0.snapshot }])
    }

    public var onPostBoxDeleted: OnPostBoxDeleted? {
      get {
        return (snapshot["onPostBoxDeleted"] as? Snapshot).flatMap { OnPostBoxDeleted(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onPostBoxDeleted")
      }
    }

    public struct OnPostBoxDeleted: GraphQLSelectionSet {
      public static let possibleTypes = ["PostBoxDeletionResult"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("connectionId", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("remainingMessages", type: .nonNull(.list(.nonNull(.object(RemainingMessage.selections))))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(connectionId: GraphQLID, remainingMessages: [RemainingMessage]) {
        self.init(snapshot: ["__typename": "PostBoxDeletionResult", "connectionId": connectionId, "remainingMessages": remainingMessages.map { $0.snapshot }])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var connectionId: GraphQLID {
        get {
          return snapshot["connectionId"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "connectionId")
        }
      }

      public var remainingMessages: [RemainingMessage] {
        get {
          return (snapshot["remainingMessages"] as! [Snapshot]).map { RemainingMessage(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "remainingMessages")
        }
      }

      public struct RemainingMessage: GraphQLSelectionSet {
        public static let possibleTypes = ["MessageTableKey"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("connectionId", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("messageId", type: .nonNull(.scalar(GraphQLID.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(connectionId: GraphQLID, messageId: GraphQLID) {
          self.init(snapshot: ["__typename": "MessageTableKey", "connectionId": connectionId, "messageId": messageId])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var connectionId: GraphQLID {
          get {
            return snapshot["connectionId"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "connectionId")
          }
        }

        public var messageId: GraphQLID {
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
