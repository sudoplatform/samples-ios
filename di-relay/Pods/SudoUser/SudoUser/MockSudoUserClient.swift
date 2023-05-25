//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoKeyManager
import AuthenticationServices

// Mock implementation of `SudoUserClient` protocol used for unit testing.
open class MockSudoUserClient: SudoUserClient {

    public var version: String = "1.0"

    public init() {}

    public var isRegisteredCalled: Bool = false
    public var isRegisteredReturn: Bool = true

    open func isRegistered() -> Bool {
        self.isRegisteredCalled = true
        return self.isRegisteredReturn
    }

    public var resetCalled: Bool = false
    public var resetError: Error?

    open func reset() throws {
        self.resetCalled = true

        if let error = self.resetError {
            throw error
        }
    }

    public var registerWithDeviceCheckCalled: Bool = false
    public var registerWithDeviceCheckResult: String = ""
    public var registerWithDeviceCheckError: Error?
    public var registerWithDeviceCheckParamToken: Data?
    public var registerWithDeviceCheckParamBuildType: String?
    public var registerWithDeviceCheckParamVendorId: UUID?
    public var registerWithDeviceCheckParamRegistrationId: String?

    open func registerWithDeviceCheck(token: Data, buildType: String, vendorId: UUID, registrationId: String?) async throws -> String {
        self.registerWithDeviceCheckCalled = true
        self.registerWithDeviceCheckParamBuildType = buildType
        self.registerWithDeviceCheckParamToken = token
        self.registerWithDeviceCheckParamVendorId = vendorId
        self.registerWithDeviceCheckParamRegistrationId = registrationId

        if let error = self.registerWithDeviceCheckError {
            throw error
        }

        return self.registerWithDeviceCheckResult
    }

    public var registerWithAuthenticationProviderCalled: Bool = false
    public var registerWithAuthenticationProviderResult: String = ""
    public var registerWithAuthenticationProviderError: Error?
    public var registerWithAuthenticationProviderParamAuthenticationProvider: AuthenticationProvider?
    public var registerWithAuthenticationProviderParamRegistrationId: String?

    open func registerWithAuthenticationProvider(authenticationProvider: AuthenticationProvider, registrationId: String?) async throws -> String {
        self.registerWithAuthenticationProviderCalled = true
        self.registerWithAuthenticationProviderParamAuthenticationProvider = authenticationProvider
        self.registerWithAuthenticationProviderParamRegistrationId = registrationId

        if let error = self.registerWithAuthenticationProviderError {
            throw error
        }

        return  self.registerWithAuthenticationProviderResult
    }

    public var deregisterCalled: Bool = false
    public var deregisterResult: String = ""
    public var deregisterError: Error?

    open func deregister() async throws -> String {
        self.deregisterCalled = true

        if let error = self.deregisterError {
            throw error
        }

        return self.deregisterResult
    }

    public var signInWithKeyCalled: Bool = false
    public var signInWithKeyResult: AuthenticationTokens = AuthenticationTokens(idToken: "", accessToken: "", refreshToken: "", lifetime: 0, username: "")
    public var signInWithKeyError: Error?

    open func signInWithKey() async throws -> AuthenticationTokens {
        self.signInWithKeyCalled = true

        if let error = self.signInWithKeyError {
            throw error
        }

        return self.signInWithKeyResult
    }

    public var refreshTokensCalled: Bool = false
    public var refreshTokensResult: AuthenticationTokens = AuthenticationTokens(idToken: "", accessToken: "", refreshToken: "", lifetime: 0, username: "")
    public var refreshTokensError: Error?
    public var refreshTokensParamRefreshToken: String?

    open func refreshTokens(refreshToken: String) async throws -> AuthenticationTokens {
        self.refreshTokensCalled = true
        self.refreshTokensParamRefreshToken = refreshToken

        if let error = self.refreshTokensError {
            throw error
        }

        return self.refreshTokensResult
    }

    public var refreshToken: String = ""

    open func refreshTokens() async throws -> AuthenticationTokens {
        return try await self.refreshTokens(refreshToken: self.refreshToken)
    }

    public var getUserNameCalled: Bool = false
    public var getUserNameReturn: String?
    public var getUserNameError: Error?

    open func getUserName() throws -> String? {
        self.getUserNameCalled = true

        if let error = self.getUserNameError {
            throw error
        }

        return self.getUserNameReturn
    }

    public var setUserNameCalled: Bool = false
    public var setUserNameParamName: String?
    public var setUserNameError: Error?

    open func setUserName(name: String) throws {
        self.setUserNameCalled = true
        self.setUserNameParamName = name

        if let error = self.setUserNameError {
            throw error
        }
    }

    public var getIdTokenCalled: Bool = false
    public var getIdTokenReturn: String?
    public var getIdTokenError: Error?

    open func getIdToken() throws -> String? {
        self.getIdTokenCalled = true

        if let error = self.getIdTokenError {
            throw error
        }

        return self.getIdTokenReturn
    }

    public var getAccessTokenCalled: Bool = false
    public var getAccessTokenReturn: String?
    public var getAccessTokenError: Error?

    open func getAccessToken() throws -> String? {
        self.getAccessTokenCalled = true

        if let error = self.getAccessTokenError {
            throw error
        }

        return self.getAccessTokenReturn
    }

    public var getRefreshTokenCalled: Bool = false
    public var getRefreshTokenReturn: String?
    public var getRefreshTokenError: Error?

    open func getRefreshToken() throws -> String? {
        self.getRefreshTokenCalled = true

        if let error = self.getRefreshTokenError {
            throw error
        }

        return self.getRefreshTokenReturn
    }

    public var getTokenExpiryCalled: Bool = false
    public var getTokenExpiryReturn: Date?
    public var getTokenExpiryError: Error?

    open func getTokenExpiry() throws -> Date? {
        self.getTokenExpiryCalled = true

        if let error = self.getTokenExpiryError {
            throw error
        }

        return self.getTokenExpiryReturn
    }

    public var getRefreshTokenExpiryCalled: Bool = false
    public var getRefreshTokenExpiryReturn: Date?
    public var getRefreshTokenExpiryError: Error?

    open func getRefreshTokenExpiry() throws -> Date? {
        self.getRefreshTokenExpiryCalled = true

        if let error = self.getRefreshTokenExpiryError {
            throw error
        }

        return self.getRefreshTokenExpiryReturn
    }

    public var presentFederatedSignInUICalled: Bool = false
    public var presentFederatedSignInUIError: Error?
    public var presentFederatedSignInUIResult: AuthenticationTokens = AuthenticationTokens(idToken: "", accessToken: "", refreshToken: "", lifetime: 0, username: "")

    open func presentFederatedSignInUI(presentationAnchor: ASPresentationAnchor) async throws -> AuthenticationTokens {
        self.presentFederatedSignInUICalled = true

        if let error = self.presentFederatedSignInUIError {
            throw error
        }

        return self.presentFederatedSignInUIResult
    }

    public var presentFederatedSignOutUICalled: Bool = false
    public var presentFederatedSignOutUIError: Error?

    open func presentFederatedSignOutUI(presentationAnchor: ASPresentationAnchor) async throws {
        self.presentFederatedSignOutUICalled = true

        if let error = self.presentFederatedSignOutUIError {
            throw error
        }
    }

    public var processFederatedSignInTokensCalled: Bool = false
    public var processFederatedSignInTokensError: Error?
    public var processFederatedSignInTokenstParamUrl: URL?
    public var processFederatedSignInTokenstReturn: Bool = false

    public func processFederatedSignInTokens(url: URL) throws -> Bool {
        self.processFederatedSignInTokensCalled = true
        self.processFederatedSignInTokenstParamUrl = url

        if let error = self.processFederatedSignInTokensError {
            throw error
        }

        return processFederatedSignInTokenstReturn
    }

    public var clearAuthTokensCalled: Bool = false
    public var clearAuthTokensError: Error?

    open func clearAuthTokens() throws {
        self.clearAuthTokensCalled = true

        if let error = self.clearAuthTokensError {
            throw error
        }
    }

    public var signOutCalled: Bool = false
    public var signOutError: Error?

    open func signOut() async throws {
        self.signOutCalled = true

        if let error = self.signOutError {
            throw error
        }
    }

    public var globalSignOutCalled: Bool = false
    public var globalSignOutError: Error?

    open func globalSignOut() async throws {
        self.globalSignOutCalled = true

        if let error = self.globalSignOutError {
            throw error
        }
    }

    public var getIdentityIdCalled: Bool = false
    public var getIdentityIdReturn: String? = "dummy_id"

    open func getIdentityId() -> String? {
        self.getIdentityIdCalled = true

        return getIdentityIdReturn
    }

    public var getSubjectCalled: Bool = false
    public var getSubjectReturn: String?
    public var getSubjectError: Error?

    open func getSubject() throws -> String? {
        self.getSubjectCalled = true

        if let error = self.getSubjectError {
            throw error
        }

        return self.getSubjectReturn
    }

    public var getUserClaimReturn: Any?

    open func getUserClaim(name: String) throws -> Any? {
        return self.getUserClaimReturn
    }

    public var storeTokensCalled: Bool = false
    public var storeTokensError: Error?
    public var storeTokensParamTokens: AuthenticationTokens?

    open func storeTokens(tokens: AuthenticationTokens) throws {
        self.storeTokensCalled = true
        self.storeTokensParamTokens = tokens

        if let error = self.storeTokensError {
            throw error
        }
    }

    public var isSignedInCalled: Bool = false
    public var isSignedInReturn: Bool = false
    public var isSignedInError: Error?

    open func isSignedIn() throws -> Bool {
        self.isSignedInCalled = true

        if let error = self.isSignedInError {
            throw error
        }

        return isSignedInReturn
    }

    public var isGetSupportedRegistrationChallengeTypeCalled: Bool = false
    public var isGetSupportedRegistrationChallengeTypeReturn: [ChallengeType]  = []

    public func getSupportedRegistrationChallengeType() -> [ChallengeType] {
        self.isGetSupportedRegistrationChallengeTypeCalled = true
        return isGetSupportedRegistrationChallengeTypeReturn
    }

    public var registerSignInObserverCalled: Bool = false
    public var registerSignInObserverParamId: String = ""
    public var registerSignInObserverParamObserver: SignInStatusObserver?

    open func registerSignInStatusObserver(id: String, observer: SignInStatusObserver) {
        self.registerSignInObserverCalled = true
        self.registerSignInObserverParamId = id
        self.registerSignInObserverParamObserver = observer
    }

    public var deregisterSignInObserverCalled: Bool = false
    public var deregisterSignInObserverParamId: String = ""

    open func deregisterSignInStatusObserver(id: String) {
        self.deregisterSignInObserverCalled = true
        self.deregisterSignInObserverParamId = id
    }

    public var signInWithAuthenticationProviderCalled: Bool = false
    public var signInWithAuthenticationProviderResult: AuthenticationTokens = AuthenticationTokens(idToken: "", accessToken: "", refreshToken: "", lifetime: 0, username: "")
    public var signInWithAuthenticationProviderError: Error?
    public var signInWithAuthenticationProviderParamAuthenticationProvider: AuthenticationProvider?

    open func signInWithAuthenticationProvider(authenticationProvider: AuthenticationProvider) async throws -> AuthenticationTokens {
        self.signInWithAuthenticationProviderCalled = true
        self.signInWithAuthenticationProviderParamAuthenticationProvider = authenticationProvider

        if let error = self.signInWithAuthenticationProviderError {
            throw error
        }

        return self.signInWithAuthenticationProviderResult
    }

}
