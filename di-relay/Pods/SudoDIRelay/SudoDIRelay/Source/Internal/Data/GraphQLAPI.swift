// swiftlint:disable all
//  This file was automatically generated and should not be edited.

import AWSAppSync

internal struct CreateRelayPostboxInput: GraphQLMapConvertible {
  internal var graphQLMap: GraphQLMap

  internal init(ownershipProof: String, connectionId: GraphQLID, isEnabled: Bool) {
    graphQLMap = ["ownershipProof": ownershipProof, "connectionId": connectionId, "isEnabled": isEnabled]
  }

  internal var ownershipProof: String {
    get {
      return graphQLMap["ownershipProof"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ownershipProof")
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

  internal var isEnabled: Bool {
    get {
      return graphQLMap["isEnabled"] as! Bool
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "isEnabled")
    }
  }
}

internal struct UpdateRelayPostboxInput: GraphQLMapConvertible {
  internal var graphQLMap: GraphQLMap

  internal init(postboxId: GraphQLID, isEnabled: Optional<Bool?> = nil) {
    graphQLMap = ["postboxId": postboxId, "isEnabled": isEnabled]
  }

  internal var postboxId: GraphQLID {
    get {
      return graphQLMap["postboxId"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "postboxId")
    }
  }

  internal var isEnabled: Optional<Bool?> {
    get {
      return graphQLMap["isEnabled"] as! Optional<Bool?>
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "isEnabled")
    }
  }
}

internal struct DeleteRelayPostboxInput: GraphQLMapConvertible {
  internal var graphQLMap: GraphQLMap

  internal init(postboxId: GraphQLID) {
    graphQLMap = ["postboxId": postboxId]
  }

  internal var postboxId: GraphQLID {
    get {
      return graphQLMap["postboxId"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "postboxId")
    }
  }
}

internal struct DeleteRelayMessageInput: GraphQLMapConvertible {
  internal var graphQLMap: GraphQLMap

  internal init(messageId: GraphQLID) {
    graphQLMap = ["messageId": messageId]
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

internal struct InternalFireOnRelayMessageCreatedInput: GraphQLMapConvertible {
  internal var graphQLMap: GraphQLMap

  internal init(id: GraphQLID, createdAtEpochMs: Double, updatedAtEpochMs: Double, owner: GraphQLID, owners: [OwnerInput], postboxId: GraphQLID, message: String) {
    graphQLMap = ["id": id, "createdAtEpochMs": createdAtEpochMs, "updatedAtEpochMs": updatedAtEpochMs, "owner": owner, "owners": owners, "postboxId": postboxId, "message": message]
  }

  internal var id: GraphQLID {
    get {
      return graphQLMap["id"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  internal var createdAtEpochMs: Double {
    get {
      return graphQLMap["createdAtEpochMs"] as! Double
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAtEpochMs")
    }
  }

  internal var updatedAtEpochMs: Double {
    get {
      return graphQLMap["updatedAtEpochMs"] as! Double
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "updatedAtEpochMs")
    }
  }

  internal var owner: GraphQLID {
    get {
      return graphQLMap["owner"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "owner")
    }
  }

  internal var owners: [OwnerInput] {
    get {
      return graphQLMap["owners"] as! [OwnerInput]
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "owners")
    }
  }

  internal var postboxId: GraphQLID {
    get {
      return graphQLMap["postboxId"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "postboxId")
    }
  }

  internal var message: String {
    get {
      return graphQLMap["message"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "message")
    }
  }
}

internal struct OwnerInput: GraphQLMapConvertible {
  internal var graphQLMap: GraphQLMap

  internal init(id: String, issuer: String) {
    graphQLMap = ["id": id, "issuer": issuer]
  }

  internal var id: String {
    get {
      return graphQLMap["id"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  internal var issuer: String {
    get {
      return graphQLMap["issuer"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "issuer")
    }
  }
}

internal final class ListRelayPostboxesQuery: GraphQLQuery {
  internal static let operationString =
    "query ListRelayPostboxes($limit: Int, $nextToken: String) {\n  listRelayPostboxes(limit: $limit, nextToken: $nextToken) {\n    __typename\n    items {\n      __typename\n      id\n      createdAtEpochMs\n      updatedAtEpochMs\n      owner\n      owners {\n        __typename\n        id\n        issuer\n      }\n      connectionId\n      isEnabled\n      serviceEndpoint\n    }\n    nextToken\n  }\n}"

  internal var limit: Int?
  internal var nextToken: String?

  internal init(limit: Int? = nil, nextToken: String? = nil) {
    self.limit = limit
    self.nextToken = nextToken
  }

  internal var variables: GraphQLMap? {
    return ["limit": limit, "nextToken": nextToken]
  }

  internal struct Data: GraphQLSelectionSet {
    internal static let possibleTypes = ["Query"]

    internal static let selections: [GraphQLSelection] = [
      GraphQLField("listRelayPostboxes", arguments: ["limit": GraphQLVariable("limit"), "nextToken": GraphQLVariable("nextToken")], type: .nonNull(.object(ListRelayPostbox.selections))),
    ]

    internal var snapshot: Snapshot

    internal init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    internal init(listRelayPostboxes: ListRelayPostbox) {
      self.init(snapshot: ["__typename": "Query", "listRelayPostboxes": listRelayPostboxes.snapshot])
    }

    internal var listRelayPostboxes: ListRelayPostbox {
      get {
        return ListRelayPostbox(snapshot: snapshot["listRelayPostboxes"]! as! Snapshot)
      }
      set {
        snapshot.updateValue(newValue.snapshot, forKey: "listRelayPostboxes")
      }
    }

    internal struct ListRelayPostbox: GraphQLSelectionSet {
      internal static let possibleTypes = ["ListRelayPostboxesResult"]

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
        self.init(snapshot: ["__typename": "ListRelayPostboxesResult", "items": items.map { $0.snapshot }, "nextToken": nextToken])
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
        internal static let possibleTypes = ["RelayPostbox"]

        internal static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("createdAtEpochMs", type: .nonNull(.scalar(Double.self))),
          GraphQLField("updatedAtEpochMs", type: .nonNull(.scalar(Double.self))),
          GraphQLField("owner", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("owners", type: .nonNull(.list(.nonNull(.object(Owner.selections))))),
          GraphQLField("connectionId", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("isEnabled", type: .nonNull(.scalar(Bool.self))),
          GraphQLField("serviceEndpoint", type: .nonNull(.scalar(String.self))),
        ]

        internal var snapshot: Snapshot

        internal init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        internal init(id: GraphQLID, createdAtEpochMs: Double, updatedAtEpochMs: Double, owner: GraphQLID, owners: [Owner], connectionId: GraphQLID, isEnabled: Bool, serviceEndpoint: String) {
          self.init(snapshot: ["__typename": "RelayPostbox", "id": id, "createdAtEpochMs": createdAtEpochMs, "updatedAtEpochMs": updatedAtEpochMs, "owner": owner, "owners": owners.map { $0.snapshot }, "connectionId": connectionId, "isEnabled": isEnabled, "serviceEndpoint": serviceEndpoint])
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

        internal var owner: GraphQLID {
          get {
            return snapshot["owner"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "owner")
          }
        }

        internal var owners: [Owner] {
          get {
            return (snapshot["owners"] as! [Snapshot]).map { Owner(snapshot: $0) }
          }
          set {
            snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "owners")
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

        internal var isEnabled: Bool {
          get {
            return snapshot["isEnabled"]! as! Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "isEnabled")
          }
        }

        internal var serviceEndpoint: String {
          get {
            return snapshot["serviceEndpoint"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "serviceEndpoint")
          }
        }

        internal struct Owner: GraphQLSelectionSet {
          internal static let possibleTypes = ["Owner"]

          internal static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("id", type: .nonNull(.scalar(String.self))),
            GraphQLField("issuer", type: .nonNull(.scalar(String.self))),
          ]

          internal var snapshot: Snapshot

          internal init(snapshot: Snapshot) {
            self.snapshot = snapshot
          }

          internal init(id: String, issuer: String) {
            self.init(snapshot: ["__typename": "Owner", "id": id, "issuer": issuer])
          }

          internal var __typename: String {
            get {
              return snapshot["__typename"]! as! String
            }
            set {
              snapshot.updateValue(newValue, forKey: "__typename")
            }
          }

          internal var id: String {
            get {
              return snapshot["id"]! as! String
            }
            set {
              snapshot.updateValue(newValue, forKey: "id")
            }
          }

          internal var issuer: String {
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

internal final class ListRelayMessagesQuery: GraphQLQuery {
  internal static let operationString =
    "query ListRelayMessages($limit: Int, $nextToken: String) {\n  listRelayMessages(limit: $limit, nextToken: $nextToken) {\n    __typename\n    items {\n      __typename\n      id\n      createdAtEpochMs\n      updatedAtEpochMs\n      owner\n      owners {\n        __typename\n        id\n        issuer\n      }\n      postboxId\n      message\n    }\n    nextToken\n  }\n}"

  internal var limit: Int?
  internal var nextToken: String?

  internal init(limit: Int? = nil, nextToken: String? = nil) {
    self.limit = limit
    self.nextToken = nextToken
  }

  internal var variables: GraphQLMap? {
    return ["limit": limit, "nextToken": nextToken]
  }

  internal struct Data: GraphQLSelectionSet {
    internal static let possibleTypes = ["Query"]

    internal static let selections: [GraphQLSelection] = [
      GraphQLField("listRelayMessages", arguments: ["limit": GraphQLVariable("limit"), "nextToken": GraphQLVariable("nextToken")], type: .nonNull(.object(ListRelayMessage.selections))),
    ]

    internal var snapshot: Snapshot

    internal init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    internal init(listRelayMessages: ListRelayMessage) {
      self.init(snapshot: ["__typename": "Query", "listRelayMessages": listRelayMessages.snapshot])
    }

    internal var listRelayMessages: ListRelayMessage {
      get {
        return ListRelayMessage(snapshot: snapshot["listRelayMessages"]! as! Snapshot)
      }
      set {
        snapshot.updateValue(newValue.snapshot, forKey: "listRelayMessages")
      }
    }

    internal struct ListRelayMessage: GraphQLSelectionSet {
      internal static let possibleTypes = ["ListRelayMessagesResult"]

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
        self.init(snapshot: ["__typename": "ListRelayMessagesResult", "items": items.map { $0.snapshot }, "nextToken": nextToken])
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
        internal static let possibleTypes = ["RelayMessage"]

        internal static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("createdAtEpochMs", type: .nonNull(.scalar(Double.self))),
          GraphQLField("updatedAtEpochMs", type: .nonNull(.scalar(Double.self))),
          GraphQLField("owner", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("owners", type: .nonNull(.list(.nonNull(.object(Owner.selections))))),
          GraphQLField("postboxId", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("message", type: .nonNull(.scalar(String.self))),
        ]

        internal var snapshot: Snapshot

        internal init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        internal init(id: GraphQLID, createdAtEpochMs: Double, updatedAtEpochMs: Double, owner: GraphQLID, owners: [Owner], postboxId: GraphQLID, message: String) {
          self.init(snapshot: ["__typename": "RelayMessage", "id": id, "createdAtEpochMs": createdAtEpochMs, "updatedAtEpochMs": updatedAtEpochMs, "owner": owner, "owners": owners.map { $0.snapshot }, "postboxId": postboxId, "message": message])
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

        internal var owner: GraphQLID {
          get {
            return snapshot["owner"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "owner")
          }
        }

        internal var owners: [Owner] {
          get {
            return (snapshot["owners"] as! [Snapshot]).map { Owner(snapshot: $0) }
          }
          set {
            snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "owners")
          }
        }

        internal var postboxId: GraphQLID {
          get {
            return snapshot["postboxId"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "postboxId")
          }
        }

        internal var message: String {
          get {
            return snapshot["message"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "message")
          }
        }

        internal struct Owner: GraphQLSelectionSet {
          internal static let possibleTypes = ["Owner"]

          internal static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("id", type: .nonNull(.scalar(String.self))),
            GraphQLField("issuer", type: .nonNull(.scalar(String.self))),
          ]

          internal var snapshot: Snapshot

          internal init(snapshot: Snapshot) {
            self.snapshot = snapshot
          }

          internal init(id: String, issuer: String) {
            self.init(snapshot: ["__typename": "Owner", "id": id, "issuer": issuer])
          }

          internal var __typename: String {
            get {
              return snapshot["__typename"]! as! String
            }
            set {
              snapshot.updateValue(newValue, forKey: "__typename")
            }
          }

          internal var id: String {
            get {
              return snapshot["id"]! as! String
            }
            set {
              snapshot.updateValue(newValue, forKey: "id")
            }
          }

          internal var issuer: String {
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

internal final class CreateRelayPostboxMutation: GraphQLMutation {
  internal static let operationString =
    "mutation CreateRelayPostbox($input: CreateRelayPostboxInput!) {\n  createRelayPostbox(input: $input) {\n    __typename\n    id\n    createdAtEpochMs\n    updatedAtEpochMs\n    owner\n    owners {\n      __typename\n      id\n      issuer\n    }\n    connectionId\n    isEnabled\n    serviceEndpoint\n  }\n}"

  internal var input: CreateRelayPostboxInput

  internal init(input: CreateRelayPostboxInput) {
    self.input = input
  }

  internal var variables: GraphQLMap? {
    return ["input": input]
  }

  internal struct Data: GraphQLSelectionSet {
    internal static let possibleTypes = ["Mutation"]

    internal static let selections: [GraphQLSelection] = [
      GraphQLField("createRelayPostbox", arguments: ["input": GraphQLVariable("input")], type: .nonNull(.object(CreateRelayPostbox.selections))),
    ]

    internal var snapshot: Snapshot

    internal init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    internal init(createRelayPostbox: CreateRelayPostbox) {
      self.init(snapshot: ["__typename": "Mutation", "createRelayPostbox": createRelayPostbox.snapshot])
    }

    internal var createRelayPostbox: CreateRelayPostbox {
      get {
        return CreateRelayPostbox(snapshot: snapshot["createRelayPostbox"]! as! Snapshot)
      }
      set {
        snapshot.updateValue(newValue.snapshot, forKey: "createRelayPostbox")
      }
    }

    internal struct CreateRelayPostbox: GraphQLSelectionSet {
      internal static let possibleTypes = ["RelayPostbox"]

      internal static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("createdAtEpochMs", type: .nonNull(.scalar(Double.self))),
        GraphQLField("updatedAtEpochMs", type: .nonNull(.scalar(Double.self))),
        GraphQLField("owner", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("owners", type: .nonNull(.list(.nonNull(.object(Owner.selections))))),
        GraphQLField("connectionId", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("isEnabled", type: .nonNull(.scalar(Bool.self))),
        GraphQLField("serviceEndpoint", type: .nonNull(.scalar(String.self))),
      ]

      internal var snapshot: Snapshot

      internal init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      internal init(id: GraphQLID, createdAtEpochMs: Double, updatedAtEpochMs: Double, owner: GraphQLID, owners: [Owner], connectionId: GraphQLID, isEnabled: Bool, serviceEndpoint: String) {
        self.init(snapshot: ["__typename": "RelayPostbox", "id": id, "createdAtEpochMs": createdAtEpochMs, "updatedAtEpochMs": updatedAtEpochMs, "owner": owner, "owners": owners.map { $0.snapshot }, "connectionId": connectionId, "isEnabled": isEnabled, "serviceEndpoint": serviceEndpoint])
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

      internal var owner: GraphQLID {
        get {
          return snapshot["owner"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }

      internal var owners: [Owner] {
        get {
          return (snapshot["owners"] as! [Snapshot]).map { Owner(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "owners")
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

      internal var isEnabled: Bool {
        get {
          return snapshot["isEnabled"]! as! Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "isEnabled")
        }
      }

      internal var serviceEndpoint: String {
        get {
          return snapshot["serviceEndpoint"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "serviceEndpoint")
        }
      }

      internal struct Owner: GraphQLSelectionSet {
        internal static let possibleTypes = ["Owner"]

        internal static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(String.self))),
          GraphQLField("issuer", type: .nonNull(.scalar(String.self))),
        ]

        internal var snapshot: Snapshot

        internal init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        internal init(id: String, issuer: String) {
          self.init(snapshot: ["__typename": "Owner", "id": id, "issuer": issuer])
        }

        internal var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        internal var id: String {
          get {
            return snapshot["id"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        internal var issuer: String {
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

internal final class UpdateRelayPostboxMutation: GraphQLMutation {
  internal static let operationString =
    "mutation UpdateRelayPostbox($input: UpdateRelayPostboxInput!) {\n  updateRelayPostbox(input: $input) {\n    __typename\n    id\n    createdAtEpochMs\n    updatedAtEpochMs\n    owner\n    owners {\n      __typename\n      id\n      issuer\n    }\n    connectionId\n    isEnabled\n    serviceEndpoint\n  }\n}"

  internal var input: UpdateRelayPostboxInput

  internal init(input: UpdateRelayPostboxInput) {
    self.input = input
  }

  internal var variables: GraphQLMap? {
    return ["input": input]
  }

  internal struct Data: GraphQLSelectionSet {
    internal static let possibleTypes = ["Mutation"]

    internal static let selections: [GraphQLSelection] = [
      GraphQLField("updateRelayPostbox", arguments: ["input": GraphQLVariable("input")], type: .nonNull(.object(UpdateRelayPostbox.selections))),
    ]

    internal var snapshot: Snapshot

    internal init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    internal init(updateRelayPostbox: UpdateRelayPostbox) {
      self.init(snapshot: ["__typename": "Mutation", "updateRelayPostbox": updateRelayPostbox.snapshot])
    }

    internal var updateRelayPostbox: UpdateRelayPostbox {
      get {
        return UpdateRelayPostbox(snapshot: snapshot["updateRelayPostbox"]! as! Snapshot)
      }
      set {
        snapshot.updateValue(newValue.snapshot, forKey: "updateRelayPostbox")
      }
    }

    internal struct UpdateRelayPostbox: GraphQLSelectionSet {
      internal static let possibleTypes = ["RelayPostbox"]

      internal static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("createdAtEpochMs", type: .nonNull(.scalar(Double.self))),
        GraphQLField("updatedAtEpochMs", type: .nonNull(.scalar(Double.self))),
        GraphQLField("owner", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("owners", type: .nonNull(.list(.nonNull(.object(Owner.selections))))),
        GraphQLField("connectionId", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("isEnabled", type: .nonNull(.scalar(Bool.self))),
        GraphQLField("serviceEndpoint", type: .nonNull(.scalar(String.self))),
      ]

      internal var snapshot: Snapshot

      internal init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      internal init(id: GraphQLID, createdAtEpochMs: Double, updatedAtEpochMs: Double, owner: GraphQLID, owners: [Owner], connectionId: GraphQLID, isEnabled: Bool, serviceEndpoint: String) {
        self.init(snapshot: ["__typename": "RelayPostbox", "id": id, "createdAtEpochMs": createdAtEpochMs, "updatedAtEpochMs": updatedAtEpochMs, "owner": owner, "owners": owners.map { $0.snapshot }, "connectionId": connectionId, "isEnabled": isEnabled, "serviceEndpoint": serviceEndpoint])
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

      internal var owner: GraphQLID {
        get {
          return snapshot["owner"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }

      internal var owners: [Owner] {
        get {
          return (snapshot["owners"] as! [Snapshot]).map { Owner(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "owners")
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

      internal var isEnabled: Bool {
        get {
          return snapshot["isEnabled"]! as! Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "isEnabled")
        }
      }

      internal var serviceEndpoint: String {
        get {
          return snapshot["serviceEndpoint"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "serviceEndpoint")
        }
      }

      internal struct Owner: GraphQLSelectionSet {
        internal static let possibleTypes = ["Owner"]

        internal static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(String.self))),
          GraphQLField("issuer", type: .nonNull(.scalar(String.self))),
        ]

        internal var snapshot: Snapshot

        internal init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        internal init(id: String, issuer: String) {
          self.init(snapshot: ["__typename": "Owner", "id": id, "issuer": issuer])
        }

        internal var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        internal var id: String {
          get {
            return snapshot["id"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        internal var issuer: String {
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

internal final class DeleteRelayPostboxMutation: GraphQLMutation {
  internal static let operationString =
    "mutation DeleteRelayPostbox($input: DeleteRelayPostboxInput!) {\n  deleteRelayPostbox(input: $input) {\n    __typename\n    id\n  }\n}"

  internal var input: DeleteRelayPostboxInput

  internal init(input: DeleteRelayPostboxInput) {
    self.input = input
  }

  internal var variables: GraphQLMap? {
    return ["input": input]
  }

  internal struct Data: GraphQLSelectionSet {
    internal static let possibleTypes = ["Mutation"]

    internal static let selections: [GraphQLSelection] = [
      GraphQLField("deleteRelayPostbox", arguments: ["input": GraphQLVariable("input")], type: .object(DeleteRelayPostbox.selections)),
    ]

    internal var snapshot: Snapshot

    internal init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    internal init(deleteRelayPostbox: DeleteRelayPostbox? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "deleteRelayPostbox": deleteRelayPostbox.flatMap { $0.snapshot }])
    }

    internal var deleteRelayPostbox: DeleteRelayPostbox? {
      get {
        return (snapshot["deleteRelayPostbox"] as? Snapshot).flatMap { DeleteRelayPostbox(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "deleteRelayPostbox")
      }
    }

    internal struct DeleteRelayPostbox: GraphQLSelectionSet {
      internal static let possibleTypes = ["RelayDeletionResult"]

      internal static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
      ]

      internal var snapshot: Snapshot

      internal init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      internal init(id: GraphQLID) {
        self.init(snapshot: ["__typename": "RelayDeletionResult", "id": id])
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
    }
  }
}

internal final class DeleteRelayMessageMutation: GraphQLMutation {
  internal static let operationString =
    "mutation DeleteRelayMessage($input: DeleteRelayMessageInput!) {\n  deleteRelayMessage(input: $input) {\n    __typename\n    id\n  }\n}"

  internal var input: DeleteRelayMessageInput

  internal init(input: DeleteRelayMessageInput) {
    self.input = input
  }

  internal var variables: GraphQLMap? {
    return ["input": input]
  }

  internal struct Data: GraphQLSelectionSet {
    internal static let possibleTypes = ["Mutation"]

    internal static let selections: [GraphQLSelection] = [
      GraphQLField("deleteRelayMessage", arguments: ["input": GraphQLVariable("input")], type: .object(DeleteRelayMessage.selections)),
    ]

    internal var snapshot: Snapshot

    internal init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    internal init(deleteRelayMessage: DeleteRelayMessage? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "deleteRelayMessage": deleteRelayMessage.flatMap { $0.snapshot }])
    }

    internal var deleteRelayMessage: DeleteRelayMessage? {
      get {
        return (snapshot["deleteRelayMessage"] as? Snapshot).flatMap { DeleteRelayMessage(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "deleteRelayMessage")
      }
    }

    internal struct DeleteRelayMessage: GraphQLSelectionSet {
      internal static let possibleTypes = ["RelayDeletionResult"]

      internal static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
      ]

      internal var snapshot: Snapshot

      internal init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      internal init(id: GraphQLID) {
        self.init(snapshot: ["__typename": "RelayDeletionResult", "id": id])
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
    }
  }
}

internal final class InternalFireOnRelayMessageCreatedMutation: GraphQLMutation {
  internal static let operationString =
    "mutation InternalFireOnRelayMessageCreated($input: InternalFireOnRelayMessageCreatedInput!) {\n  internalFireOnRelayMessageCreated(input: $input) {\n    __typename\n    id\n    createdAtEpochMs\n    updatedAtEpochMs\n    owner\n    owners {\n      __typename\n      id\n      issuer\n    }\n    postboxId\n    message\n  }\n}"

  internal var input: InternalFireOnRelayMessageCreatedInput

  internal init(input: InternalFireOnRelayMessageCreatedInput) {
    self.input = input
  }

  internal var variables: GraphQLMap? {
    return ["input": input]
  }

  internal struct Data: GraphQLSelectionSet {
    internal static let possibleTypes = ["Mutation"]

    internal static let selections: [GraphQLSelection] = [
      GraphQLField("internalFireOnRelayMessageCreated", arguments: ["input": GraphQLVariable("input")], type: .nonNull(.object(InternalFireOnRelayMessageCreated.selections))),
    ]

    internal var snapshot: Snapshot

    internal init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    internal init(internalFireOnRelayMessageCreated: InternalFireOnRelayMessageCreated) {
      self.init(snapshot: ["__typename": "Mutation", "internalFireOnRelayMessageCreated": internalFireOnRelayMessageCreated.snapshot])
    }

    internal var internalFireOnRelayMessageCreated: InternalFireOnRelayMessageCreated {
      get {
        return InternalFireOnRelayMessageCreated(snapshot: snapshot["internalFireOnRelayMessageCreated"]! as! Snapshot)
      }
      set {
        snapshot.updateValue(newValue.snapshot, forKey: "internalFireOnRelayMessageCreated")
      }
    }

    internal struct InternalFireOnRelayMessageCreated: GraphQLSelectionSet {
      internal static let possibleTypes = ["RelayMessage"]

      internal static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("createdAtEpochMs", type: .nonNull(.scalar(Double.self))),
        GraphQLField("updatedAtEpochMs", type: .nonNull(.scalar(Double.self))),
        GraphQLField("owner", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("owners", type: .nonNull(.list(.nonNull(.object(Owner.selections))))),
        GraphQLField("postboxId", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("message", type: .nonNull(.scalar(String.self))),
      ]

      internal var snapshot: Snapshot

      internal init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      internal init(id: GraphQLID, createdAtEpochMs: Double, updatedAtEpochMs: Double, owner: GraphQLID, owners: [Owner], postboxId: GraphQLID, message: String) {
        self.init(snapshot: ["__typename": "RelayMessage", "id": id, "createdAtEpochMs": createdAtEpochMs, "updatedAtEpochMs": updatedAtEpochMs, "owner": owner, "owners": owners.map { $0.snapshot }, "postboxId": postboxId, "message": message])
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

      internal var owner: GraphQLID {
        get {
          return snapshot["owner"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }

      internal var owners: [Owner] {
        get {
          return (snapshot["owners"] as! [Snapshot]).map { Owner(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "owners")
        }
      }

      internal var postboxId: GraphQLID {
        get {
          return snapshot["postboxId"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "postboxId")
        }
      }

      internal var message: String {
        get {
          return snapshot["message"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "message")
        }
      }

      internal struct Owner: GraphQLSelectionSet {
        internal static let possibleTypes = ["Owner"]

        internal static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(String.self))),
          GraphQLField("issuer", type: .nonNull(.scalar(String.self))),
        ]

        internal var snapshot: Snapshot

        internal init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        internal init(id: String, issuer: String) {
          self.init(snapshot: ["__typename": "Owner", "id": id, "issuer": issuer])
        }

        internal var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        internal var id: String {
          get {
            return snapshot["id"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        internal var issuer: String {
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

internal final class OnRelayMessageCreatedSubscription: GraphQLSubscription {
  internal static let operationString =
    "subscription OnRelayMessageCreated($owner: ID!) {\n  onRelayMessageCreated(owner: $owner) {\n    __typename\n    id\n    createdAtEpochMs\n    updatedAtEpochMs\n    owner\n    owners {\n      __typename\n      id\n      issuer\n    }\n    postboxId\n    message\n  }\n}"

  internal var owner: GraphQLID

  internal init(owner: GraphQLID) {
    self.owner = owner
  }

  internal var variables: GraphQLMap? {
    return ["owner": owner]
  }

  internal struct Data: GraphQLSelectionSet {
    internal static let possibleTypes = ["Subscription"]

    internal static let selections: [GraphQLSelection] = [
      GraphQLField("onRelayMessageCreated", arguments: ["owner": GraphQLVariable("owner")], type: .object(OnRelayMessageCreated.selections)),
    ]

    internal var snapshot: Snapshot

    internal init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    internal init(onRelayMessageCreated: OnRelayMessageCreated? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onRelayMessageCreated": onRelayMessageCreated.flatMap { $0.snapshot }])
    }

    internal var onRelayMessageCreated: OnRelayMessageCreated? {
      get {
        return (snapshot["onRelayMessageCreated"] as? Snapshot).flatMap { OnRelayMessageCreated(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onRelayMessageCreated")
      }
    }

    internal struct OnRelayMessageCreated: GraphQLSelectionSet {
      internal static let possibleTypes = ["RelayMessage"]

      internal static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("createdAtEpochMs", type: .nonNull(.scalar(Double.self))),
        GraphQLField("updatedAtEpochMs", type: .nonNull(.scalar(Double.self))),
        GraphQLField("owner", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("owners", type: .nonNull(.list(.nonNull(.object(Owner.selections))))),
        GraphQLField("postboxId", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("message", type: .nonNull(.scalar(String.self))),
      ]

      internal var snapshot: Snapshot

      internal init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      internal init(id: GraphQLID, createdAtEpochMs: Double, updatedAtEpochMs: Double, owner: GraphQLID, owners: [Owner], postboxId: GraphQLID, message: String) {
        self.init(snapshot: ["__typename": "RelayMessage", "id": id, "createdAtEpochMs": createdAtEpochMs, "updatedAtEpochMs": updatedAtEpochMs, "owner": owner, "owners": owners.map { $0.snapshot }, "postboxId": postboxId, "message": message])
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

      internal var owner: GraphQLID {
        get {
          return snapshot["owner"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }

      internal var owners: [Owner] {
        get {
          return (snapshot["owners"] as! [Snapshot]).map { Owner(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue.map { $0.snapshot }, forKey: "owners")
        }
      }

      internal var postboxId: GraphQLID {
        get {
          return snapshot["postboxId"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "postboxId")
        }
      }

      internal var message: String {
        get {
          return snapshot["message"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "message")
        }
      }

      internal struct Owner: GraphQLSelectionSet {
        internal static let possibleTypes = ["Owner"]

        internal static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(String.self))),
          GraphQLField("issuer", type: .nonNull(.scalar(String.self))),
        ]

        internal var snapshot: Snapshot

        internal init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        internal init(id: String, issuer: String) {
          self.init(snapshot: ["__typename": "Owner", "id": id, "issuer": issuer])
        }

        internal var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        internal var id: String {
          get {
            return snapshot["id"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        internal var issuer: String {
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