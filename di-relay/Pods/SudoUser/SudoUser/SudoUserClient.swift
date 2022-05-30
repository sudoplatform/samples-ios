//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AuthenticationServices

/// Protocol encapsulating a library of functions for calling Sudo Platform
/// identity services, managing keys, performing cryptographic operations.
public protocol SudoUserClient: AnyObject {

    /// The release version of this instance of `SudoUserClient`.
    var version: String { get }

    /// Indicates whether or not this client is registered with Sudo Platform
    /// backend.
    ///
    /// - Returns: `true` if the client is registered.
    func isRegistered() async throws -> Bool

    /// Removes all keys associated with this client and invalidates any
    /// cached authentication credentials.
    ///
    /// - Throws: `SudoUserClientError.FatalError`
    func reset() async throws

    /// Registers this client against the backend with a registration challenge and validation data.
    ///
    /// - Parameters:
    ///   - token: Apple DeviceCheck token..
    ///   - buildType: Build type of the App from which the DeviceCheck token was retrieved, e.g. "debug" or "release".
    ///   - vendorId: An alphanumeric string that uniquely identifies a device to the app’s vendor. Obtained via
    ///     `identifierForVendor` property of `UIDevice` class.
    ///   - registrationId: The registration ID  used for uniquely identifying the registration request in case it fails.
    /// - Returns: User ID of newly registered user.
    func registerWithDeviceCheck(
        token: Data,
        buildType: String,
        vendorId: UUID,
        registrationId: String?
    ) async throws -> String

    /// Registers this client against the backend with an external authentication provider. Caller must
    /// implement `AuthenticationProvider` protocol to return appropriate authentication token required
    /// to authorize the registration request.
    ///
    /// - Parameters:
    ///   - authenticationProvider: Authentication provider that provides the authentication token.
    ///   - registrationId: The registrationId if known.
    /// - Returns: User ID of newly registered user.
    func registerWithAuthenticationProvider(
        authenticationProvider: AuthenticationProvider,
        registrationId: String?
    ) async throws -> String

    /// Deregisters this client from the backend and resets the keychain. Will throw an error if an error occurred
    /// while attempting to reset the keychain.
    ///
    /// - Returns: User ID of the deregistered user.
    func deregister() async throws -> String

    /// Sign into the backend using a private key. The client must have created a private/public key pair via
    /// `register` method.
    ///
    /// - Returns: Authentication tokens.
    func signInWithKey() async throws -> AuthenticationTokens

    /// Sign into the backend  with an external authentication provider. Caller must implement `AuthenticationProvider`
    /// protocol to return the appropriate authentication token associated with the external identity registered with
    /// `registerWithAuthenticationProvider`.
    ///
    /// - Parameters:
    ///   - authenticationProvider: Authentication provider that provides the authentication token.
    /// - Returns: Authentication tokens.
    func signInWithAuthenticationProvider(authenticationProvider: AuthenticationProvider) async throws -> AuthenticationTokens

    /// Presents the sign in UI for federated sign in using an external identity provider.
    ///
    /// - Parameters:
    ///   - presentationAnchor: Window to act as the anchor for this UI.
    /// - Returns: Authentication tokens.
    func presentFederatedSignInUI(presentationAnchor: ASPresentationAnchor) async throws -> AuthenticationTokens

    /// Presents the sign out UI for federated sign in using an external identity provider.
    ///
    /// - Parameters:
    ///   - presentationAnchor: Window to act as the anchor for this UI.
    func presentFederatedSignOutUI(presentationAnchor: ASPresentationAnchor) async throws

    /// Processes federated sign in redirect URL to obtain the authentication tokens required for API access..
    ///
    /// - Parameters:
    ///   - url: Federated sign in URL passed into the app via URL scheme.
    /// - Returns: Boolean indicating whether or not the FSSO token was processed successfully.
    func processFederatedSignInTokens(url: URL) async throws -> Bool

    /// Refreshes the access and ID tokens using the refresh token. The refresh token expires after 30 days so
    /// sign in again to obtain a new refresh token before its expiry. The tokens will also be refreshed automatically
    /// when you call platform APIs requiring authentication but there will be added delay in the API response.
    /// For more consistent response time for each API call, call this API to proactively keep the tokens fresh.
    ///
    /// - Parameters:
    ///   - refreshToken: Refresh token.
    /// - Returns: Authentication tokens.
    func refreshTokens(refreshToken: String) async throws -> AuthenticationTokens

    /// Refreshes the access and ID tokens using the cached refresh token. The refresh token expires after 30 days
    /// so sign in again to obtain a new refresh token before its expiry. The tokens will also be refreshed automatically
    /// when you call platform APIs requiring authentication but there will be added delay in the API response.
    /// For more consistent response time for each API call, call this API to proactively keep the tokens fresh.
    ///
    /// - Returns: Authentication tokens.
    func refreshTokens() async throws -> AuthenticationTokens

    /// Returns the user name associated with this client. The username maybe needed to contact
    /// the support team when diagnosing an issue related to a specific user.
    ///
    /// - Returns: User name.
    func getUserName() throws -> String?

    /// Sets the user name associated with this client. Mainly used for testing.
    /// - Parameter name: user name.
    func setUserName(name: String) async throws

    /// Returns the subject of the user associated with this client.
    /// Note: This is an internal method used by other Sudo platform SDKs.
    ///
    /// - Returns: Subject.
    func getSubject() throws -> String?

    /// Returns the ID token cached from the last sign-in.
    /// Note: This is an internal method used by other Sudo platform SDKs.
    ///
    /// - Returns: ID token.
    func getIdToken() throws -> String?

    /// Returns the access token cached from the last sign-in.
    /// Note: This is an internal method used by other Sudo platform SDKs.
    ///
    /// - Returns: Access token.
    func getAccessToken() throws -> String?

    /// Returns the refresh token cached from the last sign-in. Use for callling `refreshTokens` API
    /// to refresh the authentication tokens.
    ///
    /// - Returns: Refresh token.
    func getRefreshToken() throws -> String?

    /// Returns the ID and access token expiry cached from the last sign-in. The tokens should be
    /// refreshed before they expired otherwise the platform APIs requiring authentication may fail.
    ///
    /// - Returns: Token expiry.
    func getTokenExpiry() throws -> Date?

    /// Returns the refresh token expiry cached from the last sign-in.
    ///
    /// - Returns: Refresh token expiry.
    func getRefreshTokenExpiry() throws -> Date?

    /// Clears cached authentication tokens.
    func clearAuthTokens() async throws

    /// Signs out the user from this device only.
    ///
    func signOut() async throws
    
    /// Signs out the user from all devices.
    ///
    func globalSignOut() async throws

    /// Retrieves and returns the identity ID associated with the temporary credential used for
    /// accessing certain backend resources, e.g. large blobs stored in AWS S3.
    ///
    /// - Returns:Identity ID.
    func getIdentityId() async -> String?

    /// Returns the specified claim associated with the user's identity.
    ///
    /// - Parameter name: Claim name.
    /// - Returns: The specified claim value. The value can be of any JSON supported types. Safe cast
    ///     it the expected Swift type before using it, e.g. `Dictionary`, `Array`, `String`, `Number`
    ///     or `Bool`.
    func getUserClaim(name: String) throws -> Any?

    /// Indicates whether or not the client is signed in. The client is considered signed in if it currently caches
    /// valid ID and access tokens.
    ///
    /// - Returns: `true` if the client is signed in.
    func isSignedIn() async throws -> Bool

    /// Returns the list of supported registration challenge types supported by the configured backend.
    ///
    /// - Returns: List of supported registration challenge types.
    func getSupportedRegistrationChallengeType() -> [ChallengeType]

    /// Registers an observer for sign in status changes.
    ///
    /// - Parameters:
    ///     - id: unique ID to associate with the observer.
    ///     - observer: sign in status observer to register.
    func registerSignInStatusObserver(id: String, observer: SignInStatusObserver) async

    /// Deregisters an existing sign in status observer.
    ///
    /// - Parameter id: ID of the observer to deregister.
    func deregisterSignInStatusObserver(id: String) async

}
