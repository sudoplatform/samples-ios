//  This file was automatically generated and should not be edited.

import AWSAppSync

public struct RegisterFederatedIdInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(idToken: String) {
    graphQLMap = ["idToken": idToken]
  }

  public var idToken: String {
    get {
      return graphQLMap["idToken"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "idToken")
    }
  }
}

public final class NotImplementedQuery: GraphQLQuery {
  public static let operationString =
    "query NotImplemented($dummy: String!) {\n  notImplemented(dummy: $dummy)\n}"

  public var dummy: String

  public init(dummy: String) {
    self.dummy = dummy
  }

  public var variables: GraphQLMap? {
    return ["dummy": dummy]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("notImplemented", arguments: ["dummy": GraphQLVariable("dummy")], type: .scalar(Bool.self)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(notImplemented: Bool? = nil) {
      self.init(snapshot: ["__typename": "Query", "notImplemented": notImplemented])
    }

    public var notImplemented: Bool? {
      get {
        return snapshot["notImplemented"] as? Bool
      }
      set {
        snapshot.updateValue(newValue, forKey: "notImplemented")
      }
    }
  }
}

public final class DeregisterMutation: GraphQLMutation {
  public static let operationString =
    "mutation Deregister {\n  deregister {\n    __typename\n    success\n  }\n}"

  public init() {
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("deregister", type: .object(Deregister.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(deregister: Deregister? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "deregister": deregister.flatMap { $0.snapshot }])
    }

    public var deregister: Deregister? {
      get {
        return (snapshot["deregister"] as? Snapshot).flatMap { Deregister(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "deregister")
      }
    }

    public struct Deregister: GraphQLSelectionSet {
      public static let possibleTypes = ["Deregister"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("success", type: .nonNull(.scalar(Bool.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(success: Bool) {
        self.init(snapshot: ["__typename": "Deregister", "success": success])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var success: Bool {
        get {
          return snapshot["success"]! as! Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "success")
        }
      }
    }
  }
}

public final class GlobalSignOutMutation: GraphQLMutation {
  public static let operationString =
    "mutation GlobalSignOut {\n  globalSignOut {\n    __typename\n    success\n  }\n}"

  public init() {
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("globalSignOut", type: .object(GlobalSignOut.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(globalSignOut: GlobalSignOut? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "globalSignOut": globalSignOut.flatMap { $0.snapshot }])
    }

    public var globalSignOut: GlobalSignOut? {
      get {
        return (snapshot["globalSignOut"] as? Snapshot).flatMap { GlobalSignOut(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "globalSignOut")
      }
    }

    public struct GlobalSignOut: GraphQLSelectionSet {
      public static let possibleTypes = ["GlobalSignOut"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("success", type: .nonNull(.scalar(Bool.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(success: Bool) {
        self.init(snapshot: ["__typename": "GlobalSignOut", "success": success])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var success: Bool {
        get {
          return snapshot["success"]! as! Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "success")
        }
      }
    }
  }
}

public final class RegisterFederatedIdMutation: GraphQLMutation {
  public static let operationString =
    "mutation RegisterFederatedId($input: RegisterFederatedIdInput) {\n  registerFederatedId(input: $input) {\n    __typename\n    identityId\n  }\n}"

  public var input: RegisterFederatedIdInput?

  public init(input: RegisterFederatedIdInput? = nil) {
    self.input = input
  }

  public var variables: GraphQLMap? {
    return ["input": input]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("registerFederatedId", arguments: ["input": GraphQLVariable("input")], type: .object(RegisterFederatedId.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(registerFederatedId: RegisterFederatedId? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "registerFederatedId": registerFederatedId.flatMap { $0.snapshot }])
    }

    public var registerFederatedId: RegisterFederatedId? {
      get {
        return (snapshot["registerFederatedId"] as? Snapshot).flatMap { RegisterFederatedId(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "registerFederatedId")
      }
    }

    public struct RegisterFederatedId: GraphQLSelectionSet {
      public static let possibleTypes = ["FederatedId"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("identityId", type: .nonNull(.scalar(String.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(identityId: String) {
        self.init(snapshot: ["__typename": "FederatedId", "identityId": identityId])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var identityId: String {
        get {
          return snapshot["identityId"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "identityId")
        }
      }
    }
  }
}