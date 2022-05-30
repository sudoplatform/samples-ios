//  This file was automatically generated and should not be edited.

import AWSAppSync

public struct CreateSudoInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(claims: [SecureClaimInput], objects: [SecureS3ObjectInput]) {
    graphQLMap = ["claims": claims, "objects": objects]
  }

  public var claims: [SecureClaimInput] {
    get {
      return graphQLMap["claims"] as! [SecureClaimInput]
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "claims")
    }
  }

  public var objects: [SecureS3ObjectInput] {
    get {
      return graphQLMap["objects"] as! [SecureS3ObjectInput]
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "objects")
    }
  }
}

public struct SecureClaimInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(name: String, version: Int, algorithm: String, keyId: String, base64Data: String) {
    graphQLMap = ["name": name, "version": version, "algorithm": algorithm, "keyId": keyId, "base64Data": base64Data]
  }

  public var name: String {
    get {
      return graphQLMap["name"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "name")
    }
  }

  public var version: Int {
    get {
      return graphQLMap["version"] as! Int
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "version")
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

  public var keyId: String {
    get {
      return graphQLMap["keyId"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "keyId")
    }
  }

  public var base64Data: String {
    get {
      return graphQLMap["base64Data"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "base64Data")
    }
  }
}

public struct SecureS3ObjectInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(name: String, version: Int, algorithm: String, keyId: String, bucket: String, region: String, key: String) {
    graphQLMap = ["name": name, "version": version, "algorithm": algorithm, "keyId": keyId, "bucket": bucket, "region": region, "key": key]
  }

  public var name: String {
    get {
      return graphQLMap["name"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "name")
    }
  }

  public var version: Int {
    get {
      return graphQLMap["version"] as! Int
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "version")
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

  public var keyId: String {
    get {
      return graphQLMap["keyId"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "keyId")
    }
  }

  public var bucket: String {
    get {
      return graphQLMap["bucket"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "bucket")
    }
  }

  public var region: String {
    get {
      return graphQLMap["region"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "region")
    }
  }

  public var key: String {
    get {
      return graphQLMap["key"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "key")
    }
  }
}

public struct UpdateSudoInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: GraphQLID, claims: Optional<[SecureClaimInput]?> = nil, objects: Optional<[SecureS3ObjectInput]?> = nil, expectedVersion: Int) {
    graphQLMap = ["id": id, "claims": claims, "objects": objects, "expectedVersion": expectedVersion]
  }

  public var id: GraphQLID {
    get {
      return graphQLMap["id"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var claims: Optional<[SecureClaimInput]?> {
    get {
      return graphQLMap["claims"] as! Optional<[SecureClaimInput]?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "claims")
    }
  }

  public var objects: Optional<[SecureS3ObjectInput]?> {
    get {
      return graphQLMap["objects"] as! Optional<[SecureS3ObjectInput]?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "objects")
    }
  }

  public var expectedVersion: Int {
    get {
      return graphQLMap["expectedVersion"] as! Int
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "expectedVersion")
    }
  }
}

public struct DeleteSudoInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: GraphQLID, expectedVersion: Int) {
    graphQLMap = ["id": id, "expectedVersion": expectedVersion]
  }

  public var id: GraphQLID {
    get {
      return graphQLMap["id"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var expectedVersion: Int {
    get {
      return graphQLMap["expectedVersion"] as! Int
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "expectedVersion")
    }
  }
}

public struct GetOwnershipProofInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(sudoId: GraphQLID, audience: String) {
    graphQLMap = ["sudoId": sudoId, "audience": audience]
  }

  public var sudoId: GraphQLID {
    get {
      return graphQLMap["sudoId"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "sudoId")
    }
  }

  public var audience: String {
    get {
      return graphQLMap["audience"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "audience")
    }
  }
}

public struct ProcessCreateSudoEventInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(owner: GraphQLID, claims: [SecureClaimInput], objects: [SecureS3ObjectInput], metadata: [AttributeInput]) {
    graphQLMap = ["owner": owner, "claims": claims, "objects": objects, "metadata": metadata]
  }

  public var owner: GraphQLID {
    get {
      return graphQLMap["owner"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "owner")
    }
  }

  public var claims: [SecureClaimInput] {
    get {
      return graphQLMap["claims"] as! [SecureClaimInput]
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "claims")
    }
  }

  public var objects: [SecureS3ObjectInput] {
    get {
      return graphQLMap["objects"] as! [SecureS3ObjectInput]
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "objects")
    }
  }

  public var metadata: [AttributeInput] {
    get {
      return graphQLMap["metadata"] as! [AttributeInput]
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "metadata")
    }
  }
}

public struct AttributeInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(name: String, value: String) {
    graphQLMap = ["name": name, "value": value]
  }

  public var name: String {
    get {
      return graphQLMap["name"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "name")
    }
  }

  public var value: String {
    get {
      return graphQLMap["value"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "value")
    }
  }
}

public struct ProcessDeleteSudoEventInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: GraphQLID, owner: GraphQLID) {
    graphQLMap = ["id": id, "owner": owner]
  }

  public var id: GraphQLID {
    get {
      return graphQLMap["id"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var owner: GraphQLID {
    get {
      return graphQLMap["owner"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "owner")
    }
  }
}

public final class GetSudoQuery: GraphQLQuery {
  public static let operationString =
    "query GetSudo($id: ID!) {\n  getSudo(id: $id) {\n    __typename\n    id\n    claims {\n      __typename\n      name\n      version\n      algorithm\n      keyId\n      base64Data\n    }\n    objects {\n      __typename\n      name\n      version\n      algorithm\n      keyId\n      bucket\n      region\n      key\n    }\n    metadata {\n      __typename\n      name\n      value\n    }\n    createdAtEpochMs\n    updatedAtEpochMs\n    version\n    owner\n  }\n}"

  public var id: GraphQLID

  public init(id: GraphQLID) {
    self.id = id
  }

  public var variables: GraphQLMap? {
    return ["id": id]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("getSudo", arguments: ["id": GraphQLVariable("id")], type: .object(GetSudo.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(getSudo: GetSudo? = nil) {
      self.init(snapshot: ["__typename": "Query", "getSudo": getSudo.flatMap { $0.snapshot }])
    }

    public var getSudo: GetSudo? {
      get {
        return (snapshot["getSudo"] as? Snapshot).flatMap { GetSudo(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "getSudo")
      }
    }

    public struct GetSudo: GraphQLSelectionSet {
      public static let possibleTypes = ["Sudo"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("claims", type: .nonNull(.list(.nonNull(.object(Claim.selections))))),
        GraphQLField("objects", type: .nonNull(.list(.nonNull(.object(Object.selections))))),
        GraphQLField("metadata", type: .nonNull(.list(.nonNull(.object(Metadatum.selections))))),
        GraphQLField("createdAtEpochMs", type: .nonNull(.scalar(Double.self))),
        GraphQLField("updatedAtEpochMs", type: .nonNull(.scalar(Double.self))),
        GraphQLField("version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("owner", type: .nonNull(.scalar(GraphQLID.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, claims: [Claim], objects: [Object], metadata: [Metadatum], createdAtEpochMs: Double, updatedAtEpochMs: Double, version: Int, owner: GraphQLID) {
        self.init(snapshot: ["__typename": "Sudo", "id": id, "claims": claims.map { $0.snapshot }, "objects": objects.map { $0.snapshot }, "metadata": metadata.map { $0.snapshot }, "createdAtEpochMs": createdAtEpochMs, "updatedAtEpochMs": updatedAtEpochMs, "version": version, "owner": owner])
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

      public var claims: [Claim] {
        get {
          return (snapshot["claims"] as! [Snapshot]).map { Claim(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "claims")
        }
      }

      public var objects: [Object] {
        get {
          return (snapshot["objects"] as! [Snapshot]).map { Object(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "objects")
        }
      }

      public var metadata: [Metadatum] {
        get {
          return (snapshot["metadata"] as! [Snapshot]).map { Metadatum(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "metadata")
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

      public var version: Int {
        get {
          return snapshot["version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "version")
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

      public struct Claim: GraphQLSelectionSet {
        public static let possibleTypes = ["SecureClaim"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("algorithm", type: .nonNull(.scalar(String.self))),
          GraphQLField("keyId", type: .nonNull(.scalar(String.self))),
          GraphQLField("base64Data", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(name: String, version: Int, algorithm: String, keyId: String, base64Data: String) {
          self.init(snapshot: ["__typename": "SecureClaim", "name": name, "version": version, "algorithm": algorithm, "keyId": keyId, "base64Data": base64Data])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
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

        public var algorithm: String {
          get {
            return snapshot["algorithm"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "algorithm")
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

        public var base64Data: String {
          get {
            return snapshot["base64Data"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "base64Data")
          }
        }
      }

      public struct Object: GraphQLSelectionSet {
        public static let possibleTypes = ["SecureS3Object"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("algorithm", type: .nonNull(.scalar(String.self))),
          GraphQLField("keyId", type: .nonNull(.scalar(String.self))),
          GraphQLField("bucket", type: .nonNull(.scalar(String.self))),
          GraphQLField("region", type: .nonNull(.scalar(String.self))),
          GraphQLField("key", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(name: String, version: Int, algorithm: String, keyId: String, bucket: String, region: String, key: String) {
          self.init(snapshot: ["__typename": "SecureS3Object", "name": name, "version": version, "algorithm": algorithm, "keyId": keyId, "bucket": bucket, "region": region, "key": key])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
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

        public var algorithm: String {
          get {
            return snapshot["algorithm"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "algorithm")
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

        public var bucket: String {
          get {
            return snapshot["bucket"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "bucket")
          }
        }

        public var region: String {
          get {
            return snapshot["region"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "region")
          }
        }

        public var key: String {
          get {
            return snapshot["key"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "key")
          }
        }
      }

      public struct Metadatum: GraphQLSelectionSet {
        public static let possibleTypes = ["Attribute"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("value", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(name: String, value: String) {
          self.init(snapshot: ["__typename": "Attribute", "name": name, "value": value])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
          }
        }

        public var value: String {
          get {
            return snapshot["value"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "value")
          }
        }
      }
    }
  }
}

public final class ListSudosQuery: GraphQLQuery {
  public static let operationString =
    "query ListSudos($limit: Int, $nextToken: String) {\n  listSudos(limit: $limit, nextToken: $nextToken) {\n    __typename\n    items {\n      __typename\n      id\n      claims {\n        __typename\n        name\n        version\n        algorithm\n        keyId\n        base64Data\n      }\n      objects {\n        __typename\n        name\n        version\n        algorithm\n        keyId\n        bucket\n        region\n        key\n      }\n      metadata {\n        __typename\n        name\n        value\n      }\n      createdAtEpochMs\n      updatedAtEpochMs\n      version\n      owner\n    }\n    nextToken\n  }\n}"

  public var limit: Int?
  public var nextToken: String?

  public init(limit: Int? = nil, nextToken: String? = nil) {
    self.limit = limit
    self.nextToken = nextToken
  }

  public var variables: GraphQLMap? {
    return ["limit": limit, "nextToken": nextToken]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("listSudos", arguments: ["limit": GraphQLVariable("limit"), "nextToken": GraphQLVariable("nextToken")], type: .object(ListSudo.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(listSudos: ListSudo? = nil) {
      self.init(snapshot: ["__typename": "Query", "listSudos": listSudos.flatMap { $0.snapshot }])
    }

    public var listSudos: ListSudo? {
      get {
        return (snapshot["listSudos"] as? Snapshot).flatMap { ListSudo(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "listSudos")
      }
    }

    public struct ListSudo: GraphQLSelectionSet {
      public static let possibleTypes = ["ModelSudoConnection"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("items", type: .list(.nonNull(.object(Item.selections)))),
        GraphQLField("nextToken", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(items: [Item]? = nil, nextToken: String? = nil) {
        self.init(snapshot: ["__typename": "ModelSudoConnection", "items": items.flatMap { $0.map { $0.snapshot } }, "nextToken": nextToken])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var items: [Item]? {
        get {
          return (snapshot["items"] as? [Snapshot]).flatMap { $0.map { Item(snapshot: $0) } }
        }
        set {
          snapshot.updateValue(newValue.flatMap { $0.map { $0.snapshot } }, forKey: "items")
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
        public static let possibleTypes = ["Sudo"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("claims", type: .nonNull(.list(.nonNull(.object(Claim.selections))))),
          GraphQLField("objects", type: .nonNull(.list(.nonNull(.object(Object.selections))))),
          GraphQLField("metadata", type: .nonNull(.list(.nonNull(.object(Metadatum.selections))))),
          GraphQLField("createdAtEpochMs", type: .nonNull(.scalar(Double.self))),
          GraphQLField("updatedAtEpochMs", type: .nonNull(.scalar(Double.self))),
          GraphQLField("version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("owner", type: .nonNull(.scalar(GraphQLID.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, claims: [Claim], objects: [Object], metadata: [Metadatum], createdAtEpochMs: Double, updatedAtEpochMs: Double, version: Int, owner: GraphQLID) {
          self.init(snapshot: ["__typename": "Sudo", "id": id, "claims": claims.map { $0.snapshot }, "objects": objects.map { $0.snapshot }, "metadata": metadata.map { $0.snapshot }, "createdAtEpochMs": createdAtEpochMs, "updatedAtEpochMs": updatedAtEpochMs, "version": version, "owner": owner])
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

        public var claims: [Claim] {
          get {
            return (snapshot["claims"] as! [Snapshot]).map { Claim(snapshot: $0) }
          }
          set {
            snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "claims")
          }
        }

        public var objects: [Object] {
          get {
            return (snapshot["objects"] as! [Snapshot]).map { Object(snapshot: $0) }
          }
          set {
            snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "objects")
          }
        }

        public var metadata: [Metadatum] {
          get {
            return (snapshot["metadata"] as! [Snapshot]).map { Metadatum(snapshot: $0) }
          }
          set {
            snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "metadata")
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

        public var version: Int {
          get {
            return snapshot["version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "version")
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

        public struct Claim: GraphQLSelectionSet {
          public static let possibleTypes = ["SecureClaim"]

          public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("name", type: .nonNull(.scalar(String.self))),
            GraphQLField("version", type: .nonNull(.scalar(Int.self))),
            GraphQLField("algorithm", type: .nonNull(.scalar(String.self))),
            GraphQLField("keyId", type: .nonNull(.scalar(String.self))),
            GraphQLField("base64Data", type: .nonNull(.scalar(String.self))),
          ]

          public var snapshot: Snapshot

          public init(snapshot: Snapshot) {
            self.snapshot = snapshot
          }

          public init(name: String, version: Int, algorithm: String, keyId: String, base64Data: String) {
            self.init(snapshot: ["__typename": "SecureClaim", "name": name, "version": version, "algorithm": algorithm, "keyId": keyId, "base64Data": base64Data])
          }

          public var __typename: String {
            get {
              return snapshot["__typename"]! as! String
            }
            set {
              snapshot.updateValue(newValue, forKey: "__typename")
            }
          }

          public var name: String {
            get {
              return snapshot["name"]! as! String
            }
            set {
              snapshot.updateValue(newValue, forKey: "name")
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

          public var algorithm: String {
            get {
              return snapshot["algorithm"]! as! String
            }
            set {
              snapshot.updateValue(newValue, forKey: "algorithm")
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

          public var base64Data: String {
            get {
              return snapshot["base64Data"]! as! String
            }
            set {
              snapshot.updateValue(newValue, forKey: "base64Data")
            }
          }
        }

        public struct Object: GraphQLSelectionSet {
          public static let possibleTypes = ["SecureS3Object"]

          public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("name", type: .nonNull(.scalar(String.self))),
            GraphQLField("version", type: .nonNull(.scalar(Int.self))),
            GraphQLField("algorithm", type: .nonNull(.scalar(String.self))),
            GraphQLField("keyId", type: .nonNull(.scalar(String.self))),
            GraphQLField("bucket", type: .nonNull(.scalar(String.self))),
            GraphQLField("region", type: .nonNull(.scalar(String.self))),
            GraphQLField("key", type: .nonNull(.scalar(String.self))),
          ]

          public var snapshot: Snapshot

          public init(snapshot: Snapshot) {
            self.snapshot = snapshot
          }

          public init(name: String, version: Int, algorithm: String, keyId: String, bucket: String, region: String, key: String) {
            self.init(snapshot: ["__typename": "SecureS3Object", "name": name, "version": version, "algorithm": algorithm, "keyId": keyId, "bucket": bucket, "region": region, "key": key])
          }

          public var __typename: String {
            get {
              return snapshot["__typename"]! as! String
            }
            set {
              snapshot.updateValue(newValue, forKey: "__typename")
            }
          }

          public var name: String {
            get {
              return snapshot["name"]! as! String
            }
            set {
              snapshot.updateValue(newValue, forKey: "name")
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

          public var algorithm: String {
            get {
              return snapshot["algorithm"]! as! String
            }
            set {
              snapshot.updateValue(newValue, forKey: "algorithm")
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

          public var bucket: String {
            get {
              return snapshot["bucket"]! as! String
            }
            set {
              snapshot.updateValue(newValue, forKey: "bucket")
            }
          }

          public var region: String {
            get {
              return snapshot["region"]! as! String
            }
            set {
              snapshot.updateValue(newValue, forKey: "region")
            }
          }

          public var key: String {
            get {
              return snapshot["key"]! as! String
            }
            set {
              snapshot.updateValue(newValue, forKey: "key")
            }
          }
        }

        public struct Metadatum: GraphQLSelectionSet {
          public static let possibleTypes = ["Attribute"]

          public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("name", type: .nonNull(.scalar(String.self))),
            GraphQLField("value", type: .nonNull(.scalar(String.self))),
          ]

          public var snapshot: Snapshot

          public init(snapshot: Snapshot) {
            self.snapshot = snapshot
          }

          public init(name: String, value: String) {
            self.init(snapshot: ["__typename": "Attribute", "name": name, "value": value])
          }

          public var __typename: String {
            get {
              return snapshot["__typename"]! as! String
            }
            set {
              snapshot.updateValue(newValue, forKey: "__typename")
            }
          }

          public var name: String {
            get {
              return snapshot["name"]! as! String
            }
            set {
              snapshot.updateValue(newValue, forKey: "name")
            }
          }

          public var value: String {
            get {
              return snapshot["value"]! as! String
            }
            set {
              snapshot.updateValue(newValue, forKey: "value")
            }
          }
        }
      }
    }
  }
}

public final class CreateSudoMutation: GraphQLMutation {
  public static let operationString =
    "mutation CreateSudo($input: CreateSudoInput!) {\n  createSudo(input: $input) {\n    __typename\n    id\n    claims {\n      __typename\n      name\n      version\n      algorithm\n      keyId\n      base64Data\n    }\n    objects {\n      __typename\n      name\n      version\n      algorithm\n      keyId\n      bucket\n      region\n      key\n    }\n    metadata {\n      __typename\n      name\n      value\n    }\n    createdAtEpochMs\n    updatedAtEpochMs\n    version\n    owner\n  }\n}"

  public var input: CreateSudoInput

  public init(input: CreateSudoInput) {
    self.input = input
  }

  public var variables: GraphQLMap? {
    return ["input": input]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("createSudo", arguments: ["input": GraphQLVariable("input")], type: .object(CreateSudo.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(createSudo: CreateSudo? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "createSudo": createSudo.flatMap { $0.snapshot }])
    }

    public var createSudo: CreateSudo? {
      get {
        return (snapshot["createSudo"] as? Snapshot).flatMap { CreateSudo(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "createSudo")
      }
    }

    public struct CreateSudo: GraphQLSelectionSet {
      public static let possibleTypes = ["Sudo"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("claims", type: .nonNull(.list(.nonNull(.object(Claim.selections))))),
        GraphQLField("objects", type: .nonNull(.list(.nonNull(.object(Object.selections))))),
        GraphQLField("metadata", type: .nonNull(.list(.nonNull(.object(Metadatum.selections))))),
        GraphQLField("createdAtEpochMs", type: .nonNull(.scalar(Double.self))),
        GraphQLField("updatedAtEpochMs", type: .nonNull(.scalar(Double.self))),
        GraphQLField("version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("owner", type: .nonNull(.scalar(GraphQLID.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, claims: [Claim], objects: [Object], metadata: [Metadatum], createdAtEpochMs: Double, updatedAtEpochMs: Double, version: Int, owner: GraphQLID) {
        self.init(snapshot: ["__typename": "Sudo", "id": id, "claims": claims.map { $0.snapshot }, "objects": objects.map { $0.snapshot }, "metadata": metadata.map { $0.snapshot }, "createdAtEpochMs": createdAtEpochMs, "updatedAtEpochMs": updatedAtEpochMs, "version": version, "owner": owner])
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

      public var claims: [Claim] {
        get {
          return (snapshot["claims"] as! [Snapshot]).map { Claim(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "claims")
        }
      }

      public var objects: [Object] {
        get {
          return (snapshot["objects"] as! [Snapshot]).map { Object(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "objects")
        }
      }

      public var metadata: [Metadatum] {
        get {
          return (snapshot["metadata"] as! [Snapshot]).map { Metadatum(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "metadata")
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

      public var version: Int {
        get {
          return snapshot["version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "version")
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

      public struct Claim: GraphQLSelectionSet {
        public static let possibleTypes = ["SecureClaim"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("algorithm", type: .nonNull(.scalar(String.self))),
          GraphQLField("keyId", type: .nonNull(.scalar(String.self))),
          GraphQLField("base64Data", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(name: String, version: Int, algorithm: String, keyId: String, base64Data: String) {
          self.init(snapshot: ["__typename": "SecureClaim", "name": name, "version": version, "algorithm": algorithm, "keyId": keyId, "base64Data": base64Data])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
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

        public var algorithm: String {
          get {
            return snapshot["algorithm"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "algorithm")
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

        public var base64Data: String {
          get {
            return snapshot["base64Data"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "base64Data")
          }
        }
      }

      public struct Object: GraphQLSelectionSet {
        public static let possibleTypes = ["SecureS3Object"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("algorithm", type: .nonNull(.scalar(String.self))),
          GraphQLField("keyId", type: .nonNull(.scalar(String.self))),
          GraphQLField("bucket", type: .nonNull(.scalar(String.self))),
          GraphQLField("region", type: .nonNull(.scalar(String.self))),
          GraphQLField("key", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(name: String, version: Int, algorithm: String, keyId: String, bucket: String, region: String, key: String) {
          self.init(snapshot: ["__typename": "SecureS3Object", "name": name, "version": version, "algorithm": algorithm, "keyId": keyId, "bucket": bucket, "region": region, "key": key])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
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

        public var algorithm: String {
          get {
            return snapshot["algorithm"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "algorithm")
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

        public var bucket: String {
          get {
            return snapshot["bucket"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "bucket")
          }
        }

        public var region: String {
          get {
            return snapshot["region"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "region")
          }
        }

        public var key: String {
          get {
            return snapshot["key"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "key")
          }
        }
      }

      public struct Metadatum: GraphQLSelectionSet {
        public static let possibleTypes = ["Attribute"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("value", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(name: String, value: String) {
          self.init(snapshot: ["__typename": "Attribute", "name": name, "value": value])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
          }
        }

        public var value: String {
          get {
            return snapshot["value"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "value")
          }
        }
      }
    }
  }
}

public final class UpdateSudoMutation: GraphQLMutation {
  public static let operationString =
    "mutation UpdateSudo($input: UpdateSudoInput!) {\n  updateSudo(input: $input) {\n    __typename\n    id\n    claims {\n      __typename\n      name\n      version\n      algorithm\n      keyId\n      base64Data\n    }\n    objects {\n      __typename\n      name\n      version\n      algorithm\n      keyId\n      bucket\n      region\n      key\n    }\n    metadata {\n      __typename\n      name\n      value\n    }\n    createdAtEpochMs\n    updatedAtEpochMs\n    version\n    owner\n  }\n}"

  public var input: UpdateSudoInput

  public init(input: UpdateSudoInput) {
    self.input = input
  }

  public var variables: GraphQLMap? {
    return ["input": input]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("updateSudo", arguments: ["input": GraphQLVariable("input")], type: .object(UpdateSudo.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(updateSudo: UpdateSudo? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "updateSudo": updateSudo.flatMap { $0.snapshot }])
    }

    public var updateSudo: UpdateSudo? {
      get {
        return (snapshot["updateSudo"] as? Snapshot).flatMap { UpdateSudo(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "updateSudo")
      }
    }

    public struct UpdateSudo: GraphQLSelectionSet {
      public static let possibleTypes = ["Sudo"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("claims", type: .nonNull(.list(.nonNull(.object(Claim.selections))))),
        GraphQLField("objects", type: .nonNull(.list(.nonNull(.object(Object.selections))))),
        GraphQLField("metadata", type: .nonNull(.list(.nonNull(.object(Metadatum.selections))))),
        GraphQLField("createdAtEpochMs", type: .nonNull(.scalar(Double.self))),
        GraphQLField("updatedAtEpochMs", type: .nonNull(.scalar(Double.self))),
        GraphQLField("version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("owner", type: .nonNull(.scalar(GraphQLID.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, claims: [Claim], objects: [Object], metadata: [Metadatum], createdAtEpochMs: Double, updatedAtEpochMs: Double, version: Int, owner: GraphQLID) {
        self.init(snapshot: ["__typename": "Sudo", "id": id, "claims": claims.map { $0.snapshot }, "objects": objects.map { $0.snapshot }, "metadata": metadata.map { $0.snapshot }, "createdAtEpochMs": createdAtEpochMs, "updatedAtEpochMs": updatedAtEpochMs, "version": version, "owner": owner])
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

      public var claims: [Claim] {
        get {
          return (snapshot["claims"] as! [Snapshot]).map { Claim(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "claims")
        }
      }

      public var objects: [Object] {
        get {
          return (snapshot["objects"] as! [Snapshot]).map { Object(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "objects")
        }
      }

      public var metadata: [Metadatum] {
        get {
          return (snapshot["metadata"] as! [Snapshot]).map { Metadatum(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "metadata")
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

      public var version: Int {
        get {
          return snapshot["version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "version")
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

      public struct Claim: GraphQLSelectionSet {
        public static let possibleTypes = ["SecureClaim"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("algorithm", type: .nonNull(.scalar(String.self))),
          GraphQLField("keyId", type: .nonNull(.scalar(String.self))),
          GraphQLField("base64Data", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(name: String, version: Int, algorithm: String, keyId: String, base64Data: String) {
          self.init(snapshot: ["__typename": "SecureClaim", "name": name, "version": version, "algorithm": algorithm, "keyId": keyId, "base64Data": base64Data])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
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

        public var algorithm: String {
          get {
            return snapshot["algorithm"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "algorithm")
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

        public var base64Data: String {
          get {
            return snapshot["base64Data"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "base64Data")
          }
        }
      }

      public struct Object: GraphQLSelectionSet {
        public static let possibleTypes = ["SecureS3Object"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("algorithm", type: .nonNull(.scalar(String.self))),
          GraphQLField("keyId", type: .nonNull(.scalar(String.self))),
          GraphQLField("bucket", type: .nonNull(.scalar(String.self))),
          GraphQLField("region", type: .nonNull(.scalar(String.self))),
          GraphQLField("key", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(name: String, version: Int, algorithm: String, keyId: String, bucket: String, region: String, key: String) {
          self.init(snapshot: ["__typename": "SecureS3Object", "name": name, "version": version, "algorithm": algorithm, "keyId": keyId, "bucket": bucket, "region": region, "key": key])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
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

        public var algorithm: String {
          get {
            return snapshot["algorithm"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "algorithm")
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

        public var bucket: String {
          get {
            return snapshot["bucket"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "bucket")
          }
        }

        public var region: String {
          get {
            return snapshot["region"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "region")
          }
        }

        public var key: String {
          get {
            return snapshot["key"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "key")
          }
        }
      }

      public struct Metadatum: GraphQLSelectionSet {
        public static let possibleTypes = ["Attribute"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("value", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(name: String, value: String) {
          self.init(snapshot: ["__typename": "Attribute", "name": name, "value": value])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
          }
        }

        public var value: String {
          get {
            return snapshot["value"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "value")
          }
        }
      }
    }
  }
}

public final class DeleteSudoMutation: GraphQLMutation {
  public static let operationString =
    "mutation DeleteSudo($input: DeleteSudoInput!) {\n  deleteSudo(input: $input) {\n    __typename\n    id\n    claims {\n      __typename\n      name\n      version\n      algorithm\n      keyId\n      base64Data\n    }\n    objects {\n      __typename\n      name\n      version\n      algorithm\n      keyId\n      bucket\n      region\n      key\n    }\n    metadata {\n      __typename\n      name\n      value\n    }\n    createdAtEpochMs\n    updatedAtEpochMs\n    version\n    owner\n  }\n}"

  public var input: DeleteSudoInput

  public init(input: DeleteSudoInput) {
    self.input = input
  }

  public var variables: GraphQLMap? {
    return ["input": input]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("deleteSudo", arguments: ["input": GraphQLVariable("input")], type: .object(DeleteSudo.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(deleteSudo: DeleteSudo? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "deleteSudo": deleteSudo.flatMap { $0.snapshot }])
    }

    public var deleteSudo: DeleteSudo? {
      get {
        return (snapshot["deleteSudo"] as? Snapshot).flatMap { DeleteSudo(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "deleteSudo")
      }
    }

    public struct DeleteSudo: GraphQLSelectionSet {
      public static let possibleTypes = ["Sudo"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("claims", type: .nonNull(.list(.nonNull(.object(Claim.selections))))),
        GraphQLField("objects", type: .nonNull(.list(.nonNull(.object(Object.selections))))),
        GraphQLField("metadata", type: .nonNull(.list(.nonNull(.object(Metadatum.selections))))),
        GraphQLField("createdAtEpochMs", type: .nonNull(.scalar(Double.self))),
        GraphQLField("updatedAtEpochMs", type: .nonNull(.scalar(Double.self))),
        GraphQLField("version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("owner", type: .nonNull(.scalar(GraphQLID.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, claims: [Claim], objects: [Object], metadata: [Metadatum], createdAtEpochMs: Double, updatedAtEpochMs: Double, version: Int, owner: GraphQLID) {
        self.init(snapshot: ["__typename": "Sudo", "id": id, "claims": claims.map { $0.snapshot }, "objects": objects.map { $0.snapshot }, "metadata": metadata.map { $0.snapshot }, "createdAtEpochMs": createdAtEpochMs, "updatedAtEpochMs": updatedAtEpochMs, "version": version, "owner": owner])
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

      public var claims: [Claim] {
        get {
          return (snapshot["claims"] as! [Snapshot]).map { Claim(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "claims")
        }
      }

      public var objects: [Object] {
        get {
          return (snapshot["objects"] as! [Snapshot]).map { Object(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "objects")
        }
      }

      public var metadata: [Metadatum] {
        get {
          return (snapshot["metadata"] as! [Snapshot]).map { Metadatum(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "metadata")
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

      public var version: Int {
        get {
          return snapshot["version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "version")
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

      public struct Claim: GraphQLSelectionSet {
        public static let possibleTypes = ["SecureClaim"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("algorithm", type: .nonNull(.scalar(String.self))),
          GraphQLField("keyId", type: .nonNull(.scalar(String.self))),
          GraphQLField("base64Data", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(name: String, version: Int, algorithm: String, keyId: String, base64Data: String) {
          self.init(snapshot: ["__typename": "SecureClaim", "name": name, "version": version, "algorithm": algorithm, "keyId": keyId, "base64Data": base64Data])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
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

        public var algorithm: String {
          get {
            return snapshot["algorithm"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "algorithm")
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

        public var base64Data: String {
          get {
            return snapshot["base64Data"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "base64Data")
          }
        }
      }

      public struct Object: GraphQLSelectionSet {
        public static let possibleTypes = ["SecureS3Object"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("algorithm", type: .nonNull(.scalar(String.self))),
          GraphQLField("keyId", type: .nonNull(.scalar(String.self))),
          GraphQLField("bucket", type: .nonNull(.scalar(String.self))),
          GraphQLField("region", type: .nonNull(.scalar(String.self))),
          GraphQLField("key", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(name: String, version: Int, algorithm: String, keyId: String, bucket: String, region: String, key: String) {
          self.init(snapshot: ["__typename": "SecureS3Object", "name": name, "version": version, "algorithm": algorithm, "keyId": keyId, "bucket": bucket, "region": region, "key": key])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
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

        public var algorithm: String {
          get {
            return snapshot["algorithm"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "algorithm")
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

        public var bucket: String {
          get {
            return snapshot["bucket"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "bucket")
          }
        }

        public var region: String {
          get {
            return snapshot["region"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "region")
          }
        }

        public var key: String {
          get {
            return snapshot["key"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "key")
          }
        }
      }

      public struct Metadatum: GraphQLSelectionSet {
        public static let possibleTypes = ["Attribute"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("value", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(name: String, value: String) {
          self.init(snapshot: ["__typename": "Attribute", "name": name, "value": value])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
          }
        }

        public var value: String {
          get {
            return snapshot["value"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "value")
          }
        }
      }
    }
  }
}

public final class GetOwnershipProofMutation: GraphQLMutation {
  public static let operationString =
    "mutation GetOwnershipProof($input: GetOwnershipProofInput!) {\n  getOwnershipProof(input: $input) {\n    __typename\n    jwt\n  }\n}"

  public var input: GetOwnershipProofInput

  public init(input: GetOwnershipProofInput) {
    self.input = input
  }

  public var variables: GraphQLMap? {
    return ["input": input]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("getOwnershipProof", arguments: ["input": GraphQLVariable("input")], type: .object(GetOwnershipProof.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(getOwnershipProof: GetOwnershipProof? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "getOwnershipProof": getOwnershipProof.flatMap { $0.snapshot }])
    }

    public var getOwnershipProof: GetOwnershipProof? {
      get {
        return (snapshot["getOwnershipProof"] as? Snapshot).flatMap { GetOwnershipProof(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "getOwnershipProof")
      }
    }

    public struct GetOwnershipProof: GraphQLSelectionSet {
      public static let possibleTypes = ["OwnershipProof"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("jwt", type: .nonNull(.scalar(String.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(jwt: String) {
        self.init(snapshot: ["__typename": "OwnershipProof", "jwt": jwt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var jwt: String {
        get {
          return snapshot["jwt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "jwt")
        }
      }
    }
  }
}

public final class InternalProcessCreateSudoEventMutation: GraphQLMutation {
  public static let operationString =
    "mutation InternalProcessCreateSudoEvent($input: ProcessCreateSudoEventInput!) {\n  internalProcessCreateSudoEvent(input: $input) {\n    __typename\n    id\n    claims {\n      __typename\n      name\n      version\n      algorithm\n      keyId\n      base64Data\n    }\n    objects {\n      __typename\n      name\n      version\n      algorithm\n      keyId\n      bucket\n      region\n      key\n    }\n    metadata {\n      __typename\n      name\n      value\n    }\n    createdAtEpochMs\n    updatedAtEpochMs\n    version\n    owner\n  }\n}"

  public var input: ProcessCreateSudoEventInput

  public init(input: ProcessCreateSudoEventInput) {
    self.input = input
  }

  public var variables: GraphQLMap? {
    return ["input": input]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("internalProcessCreateSudoEvent", arguments: ["input": GraphQLVariable("input")], type: .object(InternalProcessCreateSudoEvent.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(internalProcessCreateSudoEvent: InternalProcessCreateSudoEvent? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "internalProcessCreateSudoEvent": internalProcessCreateSudoEvent.flatMap { $0.snapshot }])
    }

    public var internalProcessCreateSudoEvent: InternalProcessCreateSudoEvent? {
      get {
        return (snapshot["internalProcessCreateSudoEvent"] as? Snapshot).flatMap { InternalProcessCreateSudoEvent(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "internalProcessCreateSudoEvent")
      }
    }

    public struct InternalProcessCreateSudoEvent: GraphQLSelectionSet {
      public static let possibleTypes = ["Sudo"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("claims", type: .nonNull(.list(.nonNull(.object(Claim.selections))))),
        GraphQLField("objects", type: .nonNull(.list(.nonNull(.object(Object.selections))))),
        GraphQLField("metadata", type: .nonNull(.list(.nonNull(.object(Metadatum.selections))))),
        GraphQLField("createdAtEpochMs", type: .nonNull(.scalar(Double.self))),
        GraphQLField("updatedAtEpochMs", type: .nonNull(.scalar(Double.self))),
        GraphQLField("version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("owner", type: .nonNull(.scalar(GraphQLID.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, claims: [Claim], objects: [Object], metadata: [Metadatum], createdAtEpochMs: Double, updatedAtEpochMs: Double, version: Int, owner: GraphQLID) {
        self.init(snapshot: ["__typename": "Sudo", "id": id, "claims": claims.map { $0.snapshot }, "objects": objects.map { $0.snapshot }, "metadata": metadata.map { $0.snapshot }, "createdAtEpochMs": createdAtEpochMs, "updatedAtEpochMs": updatedAtEpochMs, "version": version, "owner": owner])
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

      public var claims: [Claim] {
        get {
          return (snapshot["claims"] as! [Snapshot]).map { Claim(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "claims")
        }
      }

      public var objects: [Object] {
        get {
          return (snapshot["objects"] as! [Snapshot]).map { Object(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "objects")
        }
      }

      public var metadata: [Metadatum] {
        get {
          return (snapshot["metadata"] as! [Snapshot]).map { Metadatum(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "metadata")
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

      public var version: Int {
        get {
          return snapshot["version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "version")
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

      public struct Claim: GraphQLSelectionSet {
        public static let possibleTypes = ["SecureClaim"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("algorithm", type: .nonNull(.scalar(String.self))),
          GraphQLField("keyId", type: .nonNull(.scalar(String.self))),
          GraphQLField("base64Data", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(name: String, version: Int, algorithm: String, keyId: String, base64Data: String) {
          self.init(snapshot: ["__typename": "SecureClaim", "name": name, "version": version, "algorithm": algorithm, "keyId": keyId, "base64Data": base64Data])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
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

        public var algorithm: String {
          get {
            return snapshot["algorithm"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "algorithm")
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

        public var base64Data: String {
          get {
            return snapshot["base64Data"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "base64Data")
          }
        }
      }

      public struct Object: GraphQLSelectionSet {
        public static let possibleTypes = ["SecureS3Object"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("algorithm", type: .nonNull(.scalar(String.self))),
          GraphQLField("keyId", type: .nonNull(.scalar(String.self))),
          GraphQLField("bucket", type: .nonNull(.scalar(String.self))),
          GraphQLField("region", type: .nonNull(.scalar(String.self))),
          GraphQLField("key", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(name: String, version: Int, algorithm: String, keyId: String, bucket: String, region: String, key: String) {
          self.init(snapshot: ["__typename": "SecureS3Object", "name": name, "version": version, "algorithm": algorithm, "keyId": keyId, "bucket": bucket, "region": region, "key": key])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
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

        public var algorithm: String {
          get {
            return snapshot["algorithm"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "algorithm")
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

        public var bucket: String {
          get {
            return snapshot["bucket"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "bucket")
          }
        }

        public var region: String {
          get {
            return snapshot["region"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "region")
          }
        }

        public var key: String {
          get {
            return snapshot["key"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "key")
          }
        }
      }

      public struct Metadatum: GraphQLSelectionSet {
        public static let possibleTypes = ["Attribute"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("value", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(name: String, value: String) {
          self.init(snapshot: ["__typename": "Attribute", "name": name, "value": value])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
          }
        }

        public var value: String {
          get {
            return snapshot["value"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "value")
          }
        }
      }
    }
  }
}

public final class InternalProcessDeleteSudoEventMutation: GraphQLMutation {
  public static let operationString =
    "mutation InternalProcessDeleteSudoEvent($input: ProcessDeleteSudoEventInput!) {\n  internalProcessDeleteSudoEvent(input: $input) {\n    __typename\n    id\n    claims {\n      __typename\n      name\n      version\n      algorithm\n      keyId\n      base64Data\n    }\n    objects {\n      __typename\n      name\n      version\n      algorithm\n      keyId\n      bucket\n      region\n      key\n    }\n    metadata {\n      __typename\n      name\n      value\n    }\n    createdAtEpochMs\n    updatedAtEpochMs\n    version\n    owner\n  }\n}"

  public var input: ProcessDeleteSudoEventInput

  public init(input: ProcessDeleteSudoEventInput) {
    self.input = input
  }

  public var variables: GraphQLMap? {
    return ["input": input]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("internalProcessDeleteSudoEvent", arguments: ["input": GraphQLVariable("input")], type: .object(InternalProcessDeleteSudoEvent.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(internalProcessDeleteSudoEvent: InternalProcessDeleteSudoEvent? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "internalProcessDeleteSudoEvent": internalProcessDeleteSudoEvent.flatMap { $0.snapshot }])
    }

    public var internalProcessDeleteSudoEvent: InternalProcessDeleteSudoEvent? {
      get {
        return (snapshot["internalProcessDeleteSudoEvent"] as? Snapshot).flatMap { InternalProcessDeleteSudoEvent(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "internalProcessDeleteSudoEvent")
      }
    }

    public struct InternalProcessDeleteSudoEvent: GraphQLSelectionSet {
      public static let possibleTypes = ["Sudo"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("claims", type: .nonNull(.list(.nonNull(.object(Claim.selections))))),
        GraphQLField("objects", type: .nonNull(.list(.nonNull(.object(Object.selections))))),
        GraphQLField("metadata", type: .nonNull(.list(.nonNull(.object(Metadatum.selections))))),
        GraphQLField("createdAtEpochMs", type: .nonNull(.scalar(Double.self))),
        GraphQLField("updatedAtEpochMs", type: .nonNull(.scalar(Double.self))),
        GraphQLField("version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("owner", type: .nonNull(.scalar(GraphQLID.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, claims: [Claim], objects: [Object], metadata: [Metadatum], createdAtEpochMs: Double, updatedAtEpochMs: Double, version: Int, owner: GraphQLID) {
        self.init(snapshot: ["__typename": "Sudo", "id": id, "claims": claims.map { $0.snapshot }, "objects": objects.map { $0.snapshot }, "metadata": metadata.map { $0.snapshot }, "createdAtEpochMs": createdAtEpochMs, "updatedAtEpochMs": updatedAtEpochMs, "version": version, "owner": owner])
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

      public var claims: [Claim] {
        get {
          return (snapshot["claims"] as! [Snapshot]).map { Claim(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "claims")
        }
      }

      public var objects: [Object] {
        get {
          return (snapshot["objects"] as! [Snapshot]).map { Object(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "objects")
        }
      }

      public var metadata: [Metadatum] {
        get {
          return (snapshot["metadata"] as! [Snapshot]).map { Metadatum(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "metadata")
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

      public var version: Int {
        get {
          return snapshot["version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "version")
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

      public struct Claim: GraphQLSelectionSet {
        public static let possibleTypes = ["SecureClaim"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("algorithm", type: .nonNull(.scalar(String.self))),
          GraphQLField("keyId", type: .nonNull(.scalar(String.self))),
          GraphQLField("base64Data", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(name: String, version: Int, algorithm: String, keyId: String, base64Data: String) {
          self.init(snapshot: ["__typename": "SecureClaim", "name": name, "version": version, "algorithm": algorithm, "keyId": keyId, "base64Data": base64Data])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
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

        public var algorithm: String {
          get {
            return snapshot["algorithm"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "algorithm")
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

        public var base64Data: String {
          get {
            return snapshot["base64Data"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "base64Data")
          }
        }
      }

      public struct Object: GraphQLSelectionSet {
        public static let possibleTypes = ["SecureS3Object"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("algorithm", type: .nonNull(.scalar(String.self))),
          GraphQLField("keyId", type: .nonNull(.scalar(String.self))),
          GraphQLField("bucket", type: .nonNull(.scalar(String.self))),
          GraphQLField("region", type: .nonNull(.scalar(String.self))),
          GraphQLField("key", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(name: String, version: Int, algorithm: String, keyId: String, bucket: String, region: String, key: String) {
          self.init(snapshot: ["__typename": "SecureS3Object", "name": name, "version": version, "algorithm": algorithm, "keyId": keyId, "bucket": bucket, "region": region, "key": key])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
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

        public var algorithm: String {
          get {
            return snapshot["algorithm"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "algorithm")
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

        public var bucket: String {
          get {
            return snapshot["bucket"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "bucket")
          }
        }

        public var region: String {
          get {
            return snapshot["region"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "region")
          }
        }

        public var key: String {
          get {
            return snapshot["key"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "key")
          }
        }
      }

      public struct Metadatum: GraphQLSelectionSet {
        public static let possibleTypes = ["Attribute"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("value", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(name: String, value: String) {
          self.init(snapshot: ["__typename": "Attribute", "name": name, "value": value])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
          }
        }

        public var value: String {
          get {
            return snapshot["value"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "value")
          }
        }
      }
    }
  }
}

public final class OnCreateSudoSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription OnCreateSudo($owner: ID!) {\n  onCreateSudo(owner: $owner) {\n    __typename\n    id\n    claims {\n      __typename\n      name\n      version\n      algorithm\n      keyId\n      base64Data\n    }\n    objects {\n      __typename\n      name\n      version\n      algorithm\n      keyId\n      bucket\n      region\n      key\n    }\n    metadata {\n      __typename\n      name\n      value\n    }\n    createdAtEpochMs\n    updatedAtEpochMs\n    version\n    owner\n  }\n}"

  public var owner: GraphQLID

  public init(owner: GraphQLID) {
    self.owner = owner
  }

  public var variables: GraphQLMap? {
    return ["owner": owner]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("onCreateSudo", arguments: ["owner": GraphQLVariable("owner")], type: .object(OnCreateSudo.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(onCreateSudo: OnCreateSudo? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onCreateSudo": onCreateSudo.flatMap { $0.snapshot }])
    }

    public var onCreateSudo: OnCreateSudo? {
      get {
        return (snapshot["onCreateSudo"] as? Snapshot).flatMap { OnCreateSudo(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onCreateSudo")
      }
    }

    public struct OnCreateSudo: GraphQLSelectionSet {
      public static let possibleTypes = ["Sudo"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("claims", type: .nonNull(.list(.nonNull(.object(Claim.selections))))),
        GraphQLField("objects", type: .nonNull(.list(.nonNull(.object(Object.selections))))),
        GraphQLField("metadata", type: .nonNull(.list(.nonNull(.object(Metadatum.selections))))),
        GraphQLField("createdAtEpochMs", type: .nonNull(.scalar(Double.self))),
        GraphQLField("updatedAtEpochMs", type: .nonNull(.scalar(Double.self))),
        GraphQLField("version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("owner", type: .nonNull(.scalar(GraphQLID.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, claims: [Claim], objects: [Object], metadata: [Metadatum], createdAtEpochMs: Double, updatedAtEpochMs: Double, version: Int, owner: GraphQLID) {
        self.init(snapshot: ["__typename": "Sudo", "id": id, "claims": claims.map { $0.snapshot }, "objects": objects.map { $0.snapshot }, "metadata": metadata.map { $0.snapshot }, "createdAtEpochMs": createdAtEpochMs, "updatedAtEpochMs": updatedAtEpochMs, "version": version, "owner": owner])
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

      public var claims: [Claim] {
        get {
          return (snapshot["claims"] as! [Snapshot]).map { Claim(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "claims")
        }
      }

      public var objects: [Object] {
        get {
          return (snapshot["objects"] as! [Snapshot]).map { Object(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "objects")
        }
      }

      public var metadata: [Metadatum] {
        get {
          return (snapshot["metadata"] as! [Snapshot]).map { Metadatum(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "metadata")
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

      public var version: Int {
        get {
          return snapshot["version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "version")
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

      public struct Claim: GraphQLSelectionSet {
        public static let possibleTypes = ["SecureClaim"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("algorithm", type: .nonNull(.scalar(String.self))),
          GraphQLField("keyId", type: .nonNull(.scalar(String.self))),
          GraphQLField("base64Data", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(name: String, version: Int, algorithm: String, keyId: String, base64Data: String) {
          self.init(snapshot: ["__typename": "SecureClaim", "name": name, "version": version, "algorithm": algorithm, "keyId": keyId, "base64Data": base64Data])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
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

        public var algorithm: String {
          get {
            return snapshot["algorithm"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "algorithm")
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

        public var base64Data: String {
          get {
            return snapshot["base64Data"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "base64Data")
          }
        }
      }

      public struct Object: GraphQLSelectionSet {
        public static let possibleTypes = ["SecureS3Object"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("algorithm", type: .nonNull(.scalar(String.self))),
          GraphQLField("keyId", type: .nonNull(.scalar(String.self))),
          GraphQLField("bucket", type: .nonNull(.scalar(String.self))),
          GraphQLField("region", type: .nonNull(.scalar(String.self))),
          GraphQLField("key", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(name: String, version: Int, algorithm: String, keyId: String, bucket: String, region: String, key: String) {
          self.init(snapshot: ["__typename": "SecureS3Object", "name": name, "version": version, "algorithm": algorithm, "keyId": keyId, "bucket": bucket, "region": region, "key": key])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
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

        public var algorithm: String {
          get {
            return snapshot["algorithm"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "algorithm")
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

        public var bucket: String {
          get {
            return snapshot["bucket"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "bucket")
          }
        }

        public var region: String {
          get {
            return snapshot["region"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "region")
          }
        }

        public var key: String {
          get {
            return snapshot["key"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "key")
          }
        }
      }

      public struct Metadatum: GraphQLSelectionSet {
        public static let possibleTypes = ["Attribute"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("value", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(name: String, value: String) {
          self.init(snapshot: ["__typename": "Attribute", "name": name, "value": value])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
          }
        }

        public var value: String {
          get {
            return snapshot["value"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "value")
          }
        }
      }
    }
  }
}

public final class OnUpdateSudoSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription OnUpdateSudo($owner: ID!) {\n  onUpdateSudo(owner: $owner) {\n    __typename\n    id\n    claims {\n      __typename\n      name\n      version\n      algorithm\n      keyId\n      base64Data\n    }\n    objects {\n      __typename\n      name\n      version\n      algorithm\n      keyId\n      bucket\n      region\n      key\n    }\n    metadata {\n      __typename\n      name\n      value\n    }\n    createdAtEpochMs\n    updatedAtEpochMs\n    version\n    owner\n  }\n}"

  public var owner: GraphQLID

  public init(owner: GraphQLID) {
    self.owner = owner
  }

  public var variables: GraphQLMap? {
    return ["owner": owner]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("onUpdateSudo", arguments: ["owner": GraphQLVariable("owner")], type: .object(OnUpdateSudo.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(onUpdateSudo: OnUpdateSudo? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onUpdateSudo": onUpdateSudo.flatMap { $0.snapshot }])
    }

    public var onUpdateSudo: OnUpdateSudo? {
      get {
        return (snapshot["onUpdateSudo"] as? Snapshot).flatMap { OnUpdateSudo(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onUpdateSudo")
      }
    }

    public struct OnUpdateSudo: GraphQLSelectionSet {
      public static let possibleTypes = ["Sudo"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("claims", type: .nonNull(.list(.nonNull(.object(Claim.selections))))),
        GraphQLField("objects", type: .nonNull(.list(.nonNull(.object(Object.selections))))),
        GraphQLField("metadata", type: .nonNull(.list(.nonNull(.object(Metadatum.selections))))),
        GraphQLField("createdAtEpochMs", type: .nonNull(.scalar(Double.self))),
        GraphQLField("updatedAtEpochMs", type: .nonNull(.scalar(Double.self))),
        GraphQLField("version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("owner", type: .nonNull(.scalar(GraphQLID.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, claims: [Claim], objects: [Object], metadata: [Metadatum], createdAtEpochMs: Double, updatedAtEpochMs: Double, version: Int, owner: GraphQLID) {
        self.init(snapshot: ["__typename": "Sudo", "id": id, "claims": claims.map { $0.snapshot }, "objects": objects.map { $0.snapshot }, "metadata": metadata.map { $0.snapshot }, "createdAtEpochMs": createdAtEpochMs, "updatedAtEpochMs": updatedAtEpochMs, "version": version, "owner": owner])
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

      public var claims: [Claim] {
        get {
          return (snapshot["claims"] as! [Snapshot]).map { Claim(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "claims")
        }
      }

      public var objects: [Object] {
        get {
          return (snapshot["objects"] as! [Snapshot]).map { Object(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "objects")
        }
      }

      public var metadata: [Metadatum] {
        get {
          return (snapshot["metadata"] as! [Snapshot]).map { Metadatum(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "metadata")
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

      public var version: Int {
        get {
          return snapshot["version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "version")
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

      public struct Claim: GraphQLSelectionSet {
        public static let possibleTypes = ["SecureClaim"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("algorithm", type: .nonNull(.scalar(String.self))),
          GraphQLField("keyId", type: .nonNull(.scalar(String.self))),
          GraphQLField("base64Data", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(name: String, version: Int, algorithm: String, keyId: String, base64Data: String) {
          self.init(snapshot: ["__typename": "SecureClaim", "name": name, "version": version, "algorithm": algorithm, "keyId": keyId, "base64Data": base64Data])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
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

        public var algorithm: String {
          get {
            return snapshot["algorithm"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "algorithm")
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

        public var base64Data: String {
          get {
            return snapshot["base64Data"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "base64Data")
          }
        }
      }

      public struct Object: GraphQLSelectionSet {
        public static let possibleTypes = ["SecureS3Object"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("algorithm", type: .nonNull(.scalar(String.self))),
          GraphQLField("keyId", type: .nonNull(.scalar(String.self))),
          GraphQLField("bucket", type: .nonNull(.scalar(String.self))),
          GraphQLField("region", type: .nonNull(.scalar(String.self))),
          GraphQLField("key", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(name: String, version: Int, algorithm: String, keyId: String, bucket: String, region: String, key: String) {
          self.init(snapshot: ["__typename": "SecureS3Object", "name": name, "version": version, "algorithm": algorithm, "keyId": keyId, "bucket": bucket, "region": region, "key": key])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
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

        public var algorithm: String {
          get {
            return snapshot["algorithm"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "algorithm")
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

        public var bucket: String {
          get {
            return snapshot["bucket"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "bucket")
          }
        }

        public var region: String {
          get {
            return snapshot["region"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "region")
          }
        }

        public var key: String {
          get {
            return snapshot["key"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "key")
          }
        }
      }

      public struct Metadatum: GraphQLSelectionSet {
        public static let possibleTypes = ["Attribute"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("value", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(name: String, value: String) {
          self.init(snapshot: ["__typename": "Attribute", "name": name, "value": value])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
          }
        }

        public var value: String {
          get {
            return snapshot["value"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "value")
          }
        }
      }
    }
  }
}

public final class OnDeleteSudoSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription OnDeleteSudo($owner: ID!) {\n  onDeleteSudo(owner: $owner) {\n    __typename\n    id\n    claims {\n      __typename\n      name\n      version\n      algorithm\n      keyId\n      base64Data\n    }\n    objects {\n      __typename\n      name\n      version\n      algorithm\n      keyId\n      bucket\n      region\n      key\n    }\n    metadata {\n      __typename\n      name\n      value\n    }\n    createdAtEpochMs\n    updatedAtEpochMs\n    version\n    owner\n  }\n}"

  public var owner: GraphQLID

  public init(owner: GraphQLID) {
    self.owner = owner
  }

  public var variables: GraphQLMap? {
    return ["owner": owner]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("onDeleteSudo", arguments: ["owner": GraphQLVariable("owner")], type: .object(OnDeleteSudo.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(onDeleteSudo: OnDeleteSudo? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onDeleteSudo": onDeleteSudo.flatMap { $0.snapshot }])
    }

    public var onDeleteSudo: OnDeleteSudo? {
      get {
        return (snapshot["onDeleteSudo"] as? Snapshot).flatMap { OnDeleteSudo(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onDeleteSudo")
      }
    }

    public struct OnDeleteSudo: GraphQLSelectionSet {
      public static let possibleTypes = ["Sudo"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("claims", type: .nonNull(.list(.nonNull(.object(Claim.selections))))),
        GraphQLField("objects", type: .nonNull(.list(.nonNull(.object(Object.selections))))),
        GraphQLField("metadata", type: .nonNull(.list(.nonNull(.object(Metadatum.selections))))),
        GraphQLField("createdAtEpochMs", type: .nonNull(.scalar(Double.self))),
        GraphQLField("updatedAtEpochMs", type: .nonNull(.scalar(Double.self))),
        GraphQLField("version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("owner", type: .nonNull(.scalar(GraphQLID.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, claims: [Claim], objects: [Object], metadata: [Metadatum], createdAtEpochMs: Double, updatedAtEpochMs: Double, version: Int, owner: GraphQLID) {
        self.init(snapshot: ["__typename": "Sudo", "id": id, "claims": claims.map { $0.snapshot }, "objects": objects.map { $0.snapshot }, "metadata": metadata.map { $0.snapshot }, "createdAtEpochMs": createdAtEpochMs, "updatedAtEpochMs": updatedAtEpochMs, "version": version, "owner": owner])
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

      public var claims: [Claim] {
        get {
          return (snapshot["claims"] as! [Snapshot]).map { Claim(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "claims")
        }
      }

      public var objects: [Object] {
        get {
          return (snapshot["objects"] as! [Snapshot]).map { Object(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "objects")
        }
      }

      public var metadata: [Metadatum] {
        get {
          return (snapshot["metadata"] as! [Snapshot]).map { Metadatum(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "metadata")
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

      public var version: Int {
        get {
          return snapshot["version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "version")
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

      public struct Claim: GraphQLSelectionSet {
        public static let possibleTypes = ["SecureClaim"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("algorithm", type: .nonNull(.scalar(String.self))),
          GraphQLField("keyId", type: .nonNull(.scalar(String.self))),
          GraphQLField("base64Data", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(name: String, version: Int, algorithm: String, keyId: String, base64Data: String) {
          self.init(snapshot: ["__typename": "SecureClaim", "name": name, "version": version, "algorithm": algorithm, "keyId": keyId, "base64Data": base64Data])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
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

        public var algorithm: String {
          get {
            return snapshot["algorithm"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "algorithm")
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

        public var base64Data: String {
          get {
            return snapshot["base64Data"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "base64Data")
          }
        }
      }

      public struct Object: GraphQLSelectionSet {
        public static let possibleTypes = ["SecureS3Object"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("algorithm", type: .nonNull(.scalar(String.self))),
          GraphQLField("keyId", type: .nonNull(.scalar(String.self))),
          GraphQLField("bucket", type: .nonNull(.scalar(String.self))),
          GraphQLField("region", type: .nonNull(.scalar(String.self))),
          GraphQLField("key", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(name: String, version: Int, algorithm: String, keyId: String, bucket: String, region: String, key: String) {
          self.init(snapshot: ["__typename": "SecureS3Object", "name": name, "version": version, "algorithm": algorithm, "keyId": keyId, "bucket": bucket, "region": region, "key": key])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
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

        public var algorithm: String {
          get {
            return snapshot["algorithm"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "algorithm")
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

        public var bucket: String {
          get {
            return snapshot["bucket"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "bucket")
          }
        }

        public var region: String {
          get {
            return snapshot["region"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "region")
          }
        }

        public var key: String {
          get {
            return snapshot["key"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "key")
          }
        }
      }

      public struct Metadatum: GraphQLSelectionSet {
        public static let possibleTypes = ["Attribute"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("value", type: .nonNull(.scalar(String.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(name: String, value: String) {
          self.init(snapshot: ["__typename": "Attribute", "name": name, "value": value])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
          }
        }

        public var value: String {
          get {
            return snapshot["value"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "value")
          }
        }
      }
    }
  }
}
