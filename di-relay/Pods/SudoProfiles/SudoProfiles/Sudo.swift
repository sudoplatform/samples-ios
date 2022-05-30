//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Represents a claim or identity attribute associated with a Sudo.
public struct Claim: Hashable {

    /// Claim visibility.
    ///
    /// - `private`: claim is only accessible by the user, i.e. it's encrypted using the user's key.
    /// - `public`: claim is accessible by other users in Sudo platform.
    public enum Visibility: Hashable {
        case `private`
        case `public`
    }

    /// Claim value.
    ///
    /// - string: String value.
    /// - blob: Blob value reperesented as a URL.
    public enum Value: Hashable {
        case string(String)
        case blob(URL)

        public func toRaw() -> Any {
            switch self {
            case .string(let value):
                return value
            case .blob(let value):
                return value
            }
        }
    }

    /// Claim name.
    public let name: String

    /// Claim visibility.
    public let visibility: Visibility

    /// Claim value.
    public var value: Value

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.name)
        hasher.combine(self.visibility)
    }

    public static func == (lhs: Claim, rhs: Claim) -> Bool {
        // Mainly for set semantic used in `ClaimSet`. Two claims are considered equal if
        // name and visibility are same. Value can be different so existing claim in
        // `ClaimSet` can be replaced with a different value.
        return lhs.hashValue == rhs.hashValue
    }

    /// Initializes a `Claim`.
    ///
    /// - Parameters:
    ///   - name: Claim name
    ///   - visibility: Claim visibility.
    ///   - vallue: Claim value.
    public init(name: String, visibility: Visibility, value: Value) {
        self.name = name
        self.visibility = visibility
        self.value = value
    }

}

// MARK: - Some convenient String literals for Sudo claim names.
extension String {
    static let title = "title"
    static let firstName = "firstName"
    static let lastName = "lastName"
    static let label = "label"
    static let notes = "notes"
    static let avatar = "avatar"
    static let externalId = "ExternalId"
}

/// Represents a Sudo.
public struct Sudo {

    /// Claims.
    public var claims: Set<Claim> = []

    /// Arbitrary metadata set by the backend.
    public var metadata: [String: String] = [:]

    /// Date and time at which this Sudo was created.
    public var createdAt = Date(timeIntervalSince1970: 0)

    /// Date and time at which this Sudo was updated.
    public var updatedAt = Date(timeIntervalSince1970: 0)

    /// Current version of this Sudo.
    public var version: Int = 0

    /// Globally unique identifier of this Sudo. This is generated and set by Sudo service.
    public var id: String?

    /// Instantiates a `Sudo`.
    ///
    /// - Parameters:
    ///   - id: Unique ID of the Sudo.
    ///   - version: Current version of the Sudo.
    ///   - createdAt: Date and time at which the Sudo was created.
    ///   - updatedAt: Date and time at which the Sudo was last updated.
    public init(
        id: String,
        version: Int,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.version = version
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Returns the claim with the specified name.
    ///
    /// - Parameter name: Claim name.
    /// - Returns: Claim of the specified name.
    public func getClaim(name: String) -> Claim? {
        return self.claims.first(where: { $0.name == name })
    }

    /// Inserts a new claim into the set. If it already exists then it will be replaced.
    ///
    /// - Parameter claim: Claim insert.
    public mutating func updateClaim(claim: Claim) {
        self.claims.update(with: claim)
    }

    /// Removes the claim with the specified name.
    ///
    /// - Parameter name: Claim name.
    public mutating func removeClaim(name: String) {
        self.claims = self.claims.filter { $0.name != name }
    }

}

// MARK: - Default Sudo schema.
public extension Sudo {

    /// Title.
    var title: String? {
        get {
            return self.getClaim(name: .title)?.value.toRaw() as? String
        }
        set {
            if let newValue = newValue {
                self.updateClaim(claim: Claim(name: .title, visibility: .private, value: .string(newValue)))
            } else {
                self.removeClaim(name: .title)
            }
        }
    }

    /// First name.
    var firstName: String? {
        get {
            return self.getClaim(name: .firstName)?.value.toRaw() as? String
        }
        set {
            if let newValue = newValue {
                self.updateClaim(claim: Claim(name: .firstName, visibility: .private, value: .string(newValue)))
            } else {
                self.removeClaim(name: .firstName)
            }
        }
    }

    /// Last name.
    var lastName: String? {
        get {
            return self.getClaim(name: .lastName)?.value.toRaw() as? String
        }
        set {
            if let newValue = newValue {
                self.updateClaim(claim: Claim(name: .lastName, visibility: .private, value: .string(newValue)))
            } else {
                self.removeClaim(name: .lastName)
            }
        }
    }

    /// Label.
    var label: String? {
        get {
            return self.getClaim(name: .label)?.value.toRaw() as? String
        }
        set {
            if let newValue = newValue {
                self.updateClaim(claim: Claim(name: .label, visibility: .private, value: .string(newValue)))
            } else {
                self.removeClaim(name: .label)
            }
        }
    }

    /// Notes.
    var notes: String? {
        get {
            return self.getClaim(name: .notes)?.value.toRaw() as? String
        }
        set {
            if let newValue = newValue {
                self.updateClaim(claim: Claim(name: .notes, visibility: .private, value: .string(newValue)))
            } else {
                self.removeClaim(name: .notes)
            }
        }
    }

    /// External ID associated with this Sudo.
    var externalId: String? {
        return self.metadata[.externalId]
    }

    /// Avatar image URL.
    var avatar: URL? {
        get {
            return self.getClaim(name: .avatar)?.value.toRaw() as? URL
        }
        set {
            if let newValue = newValue {
                self.updateClaim(claim: Claim(name: .avatar, visibility: .private, value: .blob(newValue)))
            } else {
                self.removeClaim(name: .avatar)
            }
        }
    }

    /// Instantiates a `Sudo`.
    ///
    /// - Parameters:
    ///   - id: Unique ID of the Sudo.
    ///   - version: Current version of the Sudo.
    ///   - createdAt: Date and time at which the Sudo was created.
    ///   - updatedAt: Date and time at which the Sudo was last updated.
    ///   - title: Title.
    ///   - firstName: First name.
    ///   - lastName: Last name.
    ///   - label: Label.
    ///   - notes: Notes.
    ///   - avatar: Avatar image URL.
    init(id: String,
         version: Int,
         createdAt: Date,
         updatedAt: Date,
         title: String? = nil,
         firstName: String? = nil,
         lastName: String? = nil,
         label: String? = nil,
         notes: String? = nil,
         avatar: URL? = nil) {
        self.init(id: id, version: version, createdAt: createdAt, updatedAt: updatedAt)
        self.title = title
        self.firstName = firstName
        self.lastName = lastName
        self.label = label
        self.notes = notes
        self.avatar = avatar
    }

    /// Instantiates a `Sudo`.
    ///
    /// - Parameters:
    ///   - title: Title.
    ///   - firstName: First name.
    ///   - lastName: Last name.
    ///   - label: Label.
    ///   - notes: Notes.
    ///   - avatar: Avatar image URL.
    init(title: String? = nil,
         firstName: String? = nil,
         lastName: String? = nil,
         label: String? = nil,
         notes: String? = nil,
         avatar: URL? = nil) {
        self.version = 1
        self.title = title
        self.firstName = firstName
        self.lastName = lastName
        self.label = label
        self.notes = notes
        self.avatar = avatar
    }

    /// Instantiates a `Sudo`.
    ///
    /// - Parameters:
    ///   - id: Unique ID of the Sudo.
    init(id: String) {
        self.init(id: id, version: 1, createdAt: Date(), updatedAt: Date())
    }

}
