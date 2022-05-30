//  This file was automatically generated and should not be edited.

import AWSAppSync

public final class GetEntitlementsQuery: GraphQLQuery {
  public static let operationString =
    "query GetEntitlements {\n  getEntitlements {\n    __typename\n    createdAtEpochMs\n    updatedAtEpochMs\n    version\n    name\n    description\n    entitlements {\n      __typename\n      name\n      description\n      value\n    }\n  }\n}"

  public init() {
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("getEntitlements", type: .object(GetEntitlement.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(getEntitlements: GetEntitlement? = nil) {
      self.init(snapshot: ["__typename": "Query", "getEntitlements": getEntitlements.flatMap { $0.snapshot }])
    }

    public var getEntitlements: GetEntitlement? {
      get {
        return (snapshot["getEntitlements"] as? Snapshot).flatMap { GetEntitlement(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "getEntitlements")
      }
    }

    public struct GetEntitlement: GraphQLSelectionSet {
      public static let possibleTypes = ["EntitlementsSet"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("createdAtEpochMs", type: .nonNull(.scalar(Double.self))),
        GraphQLField("updatedAtEpochMs", type: .nonNull(.scalar(Double.self))),
        GraphQLField("version", type: .nonNull(.scalar(Double.self))),
        GraphQLField("name", type: .nonNull(.scalar(String.self))),
        GraphQLField("description", type: .scalar(String.self)),
        GraphQLField("entitlements", type: .nonNull(.list(.nonNull(.object(Entitlement.selections))))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(createdAtEpochMs: Double, updatedAtEpochMs: Double, version: Double, name: String, description: String? = nil, entitlements: [Entitlement]) {
        self.init(snapshot: ["__typename": "EntitlementsSet", "createdAtEpochMs": createdAtEpochMs, "updatedAtEpochMs": updatedAtEpochMs, "version": version, "name": name, "description": description, "entitlements": entitlements.map { $0.snapshot }])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
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

      public var version: Double {
        get {
          return snapshot["version"]! as! Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "version")
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

      public var description: String? {
        get {
          return snapshot["description"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "description")
        }
      }

      public var entitlements: [Entitlement] {
        get {
          return (snapshot["entitlements"] as! [Snapshot]).map { Entitlement(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "entitlements")
        }
      }

      public struct Entitlement: GraphQLSelectionSet {
        public static let possibleTypes = ["Entitlement"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("description", type: .scalar(String.self)),
          GraphQLField("value", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(name: String, description: String? = nil, value: Int) {
          self.init(snapshot: ["__typename": "Entitlement", "name": name, "description": description, "value": value])
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

        public var description: String? {
          get {
            return snapshot["description"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "description")
          }
        }

        public var value: Int {
          get {
            return snapshot["value"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "value")
          }
        }
      }
    }
  }
}

public final class GetEntitlementsConsumptionQuery: GraphQLQuery {
  public static let operationString =
    "query GetEntitlementsConsumption {\n  getEntitlementsConsumption {\n    __typename\n    entitlements {\n      __typename\n      version\n      entitlementsSetName\n      entitlements {\n        __typename\n        name\n        description\n        value\n      }\n    }\n    consumption {\n      __typename\n      consumer {\n        __typename\n        id\n        issuer\n      }\n      name\n      value\n      consumed\n      available\n      firstConsumedAtEpochMs\n      lastConsumedAtEpochMs\n    }\n  }\n}"

  public init() {
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("getEntitlementsConsumption", type: .nonNull(.object(GetEntitlementsConsumption.selections))),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(getEntitlementsConsumption: GetEntitlementsConsumption) {
      self.init(snapshot: ["__typename": "Query", "getEntitlementsConsumption": getEntitlementsConsumption.snapshot])
    }

    public var getEntitlementsConsumption: GetEntitlementsConsumption {
      get {
        return GetEntitlementsConsumption(snapshot: snapshot["getEntitlementsConsumption"]! as! Snapshot)
      }
      set {
        snapshot.updateValue(newValue.snapshot, forKey: "getEntitlementsConsumption")
      }
    }

    public struct GetEntitlementsConsumption: GraphQLSelectionSet {
      public static let possibleTypes = ["EntitlementsConsumption"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("entitlements", type: .nonNull(.object(Entitlement.selections))),
        GraphQLField("consumption", type: .nonNull(.list(.nonNull(.object(Consumption.selections))))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(entitlements: Entitlement, consumption: [Consumption]) {
        self.init(snapshot: ["__typename": "EntitlementsConsumption", "entitlements": entitlements.snapshot, "consumption": consumption.map { $0.snapshot }])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var entitlements: Entitlement {
        get {
          return Entitlement(snapshot: snapshot["entitlements"]! as! Snapshot)
        }
        set {
          snapshot.updateValue(newValue.snapshot, forKey: "entitlements")
        }
      }

      public var consumption: [Consumption] {
        get {
          return (snapshot["consumption"] as! [Snapshot]).map { Consumption(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "consumption")
        }
      }

      public struct Entitlement: GraphQLSelectionSet {
        public static let possibleTypes = ["UserEntitlements"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("version", type: .nonNull(.scalar(Double.self))),
          GraphQLField("entitlementsSetName", type: .scalar(String.self)),
          GraphQLField("entitlements", type: .nonNull(.list(.nonNull(.object(Entitlement.selections))))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(version: Double, entitlementsSetName: String? = nil, entitlements: [Entitlement]) {
          self.init(snapshot: ["__typename": "UserEntitlements", "version": version, "entitlementsSetName": entitlementsSetName, "entitlements": entitlements.map { $0.snapshot }])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var version: Double {
          get {
            return snapshot["version"]! as! Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "version")
          }
        }

        public var entitlementsSetName: String? {
          get {
            return snapshot["entitlementsSetName"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "entitlementsSetName")
          }
        }

        public var entitlements: [Entitlement] {
          get {
            return (snapshot["entitlements"] as! [Snapshot]).map { Entitlement(snapshot: $0) }
          }
          set {
            snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "entitlements")
          }
        }

        public struct Entitlement: GraphQLSelectionSet {
          public static let possibleTypes = ["Entitlement"]

          public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("name", type: .nonNull(.scalar(String.self))),
            GraphQLField("description", type: .scalar(String.self)),
            GraphQLField("value", type: .nonNull(.scalar(Int.self))),
          ]

          public var snapshot: Snapshot

          public init(snapshot: Snapshot) {
            self.snapshot = snapshot
          }

          public init(name: String, description: String? = nil, value: Int) {
            self.init(snapshot: ["__typename": "Entitlement", "name": name, "description": description, "value": value])
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

          public var description: String? {
            get {
              return snapshot["description"] as? String
            }
            set {
              snapshot.updateValue(newValue, forKey: "description")
            }
          }

          public var value: Int {
            get {
              return snapshot["value"]! as! Int
            }
            set {
              snapshot.updateValue(newValue, forKey: "value")
            }
          }
        }
      }

      public struct Consumption: GraphQLSelectionSet {
        public static let possibleTypes = ["EntitlementConsumption"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("consumer", type: .object(Consumer.selections)),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("value", type: .nonNull(.scalar(Int.self))),
          GraphQLField("consumed", type: .nonNull(.scalar(Int.self))),
          GraphQLField("available", type: .nonNull(.scalar(Int.self))),
          GraphQLField("firstConsumedAtEpochMs", type: .scalar(Double.self)),
          GraphQLField("lastConsumedAtEpochMs", type: .scalar(Double.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(consumer: Consumer? = nil, name: String, value: Int, consumed: Int, available: Int, firstConsumedAtEpochMs: Double? = nil, lastConsumedAtEpochMs: Double? = nil) {
          self.init(snapshot: ["__typename": "EntitlementConsumption", "consumer": consumer.flatMap { $0.snapshot }, "name": name, "value": value, "consumed": consumed, "available": available, "firstConsumedAtEpochMs": firstConsumedAtEpochMs, "lastConsumedAtEpochMs": lastConsumedAtEpochMs])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var consumer: Consumer? {
          get {
            return (snapshot["consumer"] as? Snapshot).flatMap { Consumer(snapshot: $0) }
          }
          set {
            snapshot.updateValue(newValue?.snapshot, forKey: "consumer")
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

        public var value: Int {
          get {
            return snapshot["value"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "value")
          }
        }

        public var consumed: Int {
          get {
            return snapshot["consumed"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "consumed")
          }
        }

        public var available: Int {
          get {
            return snapshot["available"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "available")
          }
        }

        public var firstConsumedAtEpochMs: Double? {
          get {
            return snapshot["firstConsumedAtEpochMs"] as? Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "firstConsumedAtEpochMs")
          }
        }

        public var lastConsumedAtEpochMs: Double? {
          get {
            return snapshot["lastConsumedAtEpochMs"] as? Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "lastConsumedAtEpochMs")
          }
        }

        public struct Consumer: GraphQLSelectionSet {
          public static let possibleTypes = ["EntitlementConsumer"]

          public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
            GraphQLField("issuer", type: .nonNull(.scalar(String.self))),
          ]

          public var snapshot: Snapshot

          public init(snapshot: Snapshot) {
            self.snapshot = snapshot
          }

          public init(id: GraphQLID, issuer: String) {
            self.init(snapshot: ["__typename": "EntitlementConsumer", "id": id, "issuer": issuer])
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

          public var issuer: String {
            get {
              return snapshot["issuer"]! as! String
            }
            set {
              snapshot.updateValue(newValue, forKey: "issuer")
            }
          }
        }
      }
    }
  }
}

public final class GetExternalIdQuery: GraphQLQuery {
  public static let operationString =
    "query GetExternalId {\n  getExternalId\n}"

  public init() {
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("getExternalId", type: .nonNull(.scalar(String.self))),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(getExternalId: String) {
      self.init(snapshot: ["__typename": "Query", "getExternalId": getExternalId])
    }

    public var getExternalId: String {
      get {
        return snapshot["getExternalId"]! as! String
      }
      set {
        snapshot.updateValue(newValue, forKey: "getExternalId")
      }
    }
  }
}

public final class RedeemEntitlementsMutation: GraphQLMutation {
  public static let operationString =
    "mutation RedeemEntitlements {\n  redeemEntitlements {\n    __typename\n    createdAtEpochMs\n    updatedAtEpochMs\n    version\n    name\n    description\n    entitlements {\n      __typename\n      name\n      description\n      value\n    }\n  }\n}"

  public init() {
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("redeemEntitlements", type: .nonNull(.object(RedeemEntitlement.selections))),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(redeemEntitlements: RedeemEntitlement) {
      self.init(snapshot: ["__typename": "Mutation", "redeemEntitlements": redeemEntitlements.snapshot])
    }

    public var redeemEntitlements: RedeemEntitlement {
      get {
        return RedeemEntitlement(snapshot: snapshot["redeemEntitlements"]! as! Snapshot)
      }
      set {
        snapshot.updateValue(newValue.snapshot, forKey: "redeemEntitlements")
      }
    }

    public struct RedeemEntitlement: GraphQLSelectionSet {
      public static let possibleTypes = ["EntitlementsSet"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("createdAtEpochMs", type: .nonNull(.scalar(Double.self))),
        GraphQLField("updatedAtEpochMs", type: .nonNull(.scalar(Double.self))),
        GraphQLField("version", type: .nonNull(.scalar(Double.self))),
        GraphQLField("name", type: .nonNull(.scalar(String.self))),
        GraphQLField("description", type: .scalar(String.self)),
        GraphQLField("entitlements", type: .nonNull(.list(.nonNull(.object(Entitlement.selections))))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(createdAtEpochMs: Double, updatedAtEpochMs: Double, version: Double, name: String, description: String? = nil, entitlements: [Entitlement]) {
        self.init(snapshot: ["__typename": "EntitlementsSet", "createdAtEpochMs": createdAtEpochMs, "updatedAtEpochMs": updatedAtEpochMs, "version": version, "name": name, "description": description, "entitlements": entitlements.map { $0.snapshot }])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
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

      public var version: Double {
        get {
          return snapshot["version"]! as! Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "version")
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

      public var description: String? {
        get {
          return snapshot["description"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "description")
        }
      }

      public var entitlements: [Entitlement] {
        get {
          return (snapshot["entitlements"] as! [Snapshot]).map { Entitlement(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "entitlements")
        }
      }

      public struct Entitlement: GraphQLSelectionSet {
        public static let possibleTypes = ["Entitlement"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("description", type: .scalar(String.self)),
          GraphQLField("value", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(name: String, description: String? = nil, value: Int) {
          self.init(snapshot: ["__typename": "Entitlement", "name": name, "description": description, "value": value])
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

        public var description: String? {
          get {
            return snapshot["description"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "description")
          }
        }

        public var value: Int {
          get {
            return snapshot["value"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "value")
          }
        }
      }
    }
  }
}

public final class ConsumeBooleanEntitlementsMutation: GraphQLMutation {
  public static let operationString =
    "mutation ConsumeBooleanEntitlements($entitlementNames: [String!]!) {\n  consumeBooleanEntitlements(entitlementNames: $entitlementNames)\n}"

  public var entitlementNames: [String]

  public init(entitlementNames: [String]) {
    self.entitlementNames = entitlementNames
  }

  public var variables: GraphQLMap? {
    return ["entitlementNames": entitlementNames]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("consumeBooleanEntitlements", arguments: ["entitlementNames": GraphQLVariable("entitlementNames")], type: .nonNull(.scalar(Bool.self))),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(consumeBooleanEntitlements: Bool) {
      self.init(snapshot: ["__typename": "Mutation", "consumeBooleanEntitlements": consumeBooleanEntitlements])
    }

    public var consumeBooleanEntitlements: Bool {
      get {
        return snapshot["consumeBooleanEntitlements"]! as! Bool
      }
      set {
        snapshot.updateValue(newValue, forKey: "consumeBooleanEntitlements")
      }
    }
  }
}