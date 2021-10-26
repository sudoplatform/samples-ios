//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSAppSync

/// General errors associated with Sudo Platform Services.
///
/// - internalError: An internal error has occurred and will need to be resolved by Anonyome.
/// - invalidTokenError: Returned when JSON web tokens submitted are rejected because they:
///      1. fail signature verification
///      2. is not an appropriate token for the invoker user to be submitting (e.g. user id doesn't match)
///      3. is a resource reference token for resource type unrecognized by the service
///         to which the token has been submitted
/// - accountLockedError: Returned when an operation fails because the user's account is locked.
/// - identityInsufficient: Returned when an operation fails because the user's level of identity verification is insufficient.
/// - identityNotVerified: Returned when an operation fails due to lack of verification.
/// - unknownTimezone: Returned if specified time zone is not recognized.
/// - invalidArgument: Returned if an API argument is not valid or inconsistent with other arguments.
public enum SudoPlatformError: Error, Equatable {
    case accountLockedError
    case decodingError
    case environmentError
    case identityInsufficient
    case identityNotVerified
    case insufficientEntitlementsError
    case internalError(cause: String?)
    case invalidArgument(msg: String?)
    case invalidTokenError
    case noEntitlementsError
    case policyFailed
    case serviceError
    case unknownTimezone

    public init(_ error: GraphQLError) {
        guard let errorType = error["errorType"] as? String else {
            self = .internalError(cause: error.message)
            return
        }
        switch errorType {
        case "sudoplatform.AccountLockedError":
            self = .accountLockedError
        case "sudoplatform.DecodingError":
            self = .decodingError
        case "sudoplatform.EnvironmentError":
            self = .environmentError
        case "sudoplatform.IdentityVerificationInsufficientError":
            self = .identityInsufficient
        case "sudoplatform.IdentityVerificationNotVerifiedError":
            self = .identityNotVerified
        case "sudoplatform.InsufficientEntitlementsError":
            self = .insufficientEntitlementsError
        case "sudoplatform.invalidArgumentError":
            let msg = error.message.isEmpty ? nil : error.message
            self = .invalidArgument(msg: msg)
        case "sudoplatform.InvalidTokenError":
            self = .invalidTokenError
        case "sudoplatform.NoEntitlementsError":
            self = .noEntitlementsError
        case "sudoplatform.PolicyFailed":
            self = .policyFailed
        case "sudoplatform.ServiceError":
            self = .serviceError
        case "sudoplatform.UnknownTimezoneError":
            self = .unknownTimezone
        default:
            self = .internalError(cause: "\(errorType) - \(error.message)")
        }
    }

    /// Validation of a GraphQLError to determine if is a Service Error.
    ///
    /// - Parameter error: GraphQL Error.
    /// - Parameter serviceDomain: String representing the service domain name.
    public static func isServiceError(_ error: GraphQLError, serviceDomain: String) -> Bool {
        guard let errorType = error["errorType"] as? String else {
            return false
        }
        return errorType.starts(with: "sudoplatform.\(serviceDomain).")
    }
}
