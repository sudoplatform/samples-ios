//
//  ConfigurationProvider.swift
//  VirtualCardsExample
//
//  Copyright © 2020 Anonyome Labs. All rights reserved.
//

import Foundation
import SudoVirtualCards
import AWSAppSync
import AWSCore
import SudoUser

struct ConfigurationProvider: AWSAppSync.AWSAppSyncServiceConfigProvider {

    let endpoint: URL

    let region: AWSRegionType

    let authType: AWSAppSyncAuthType

    let apiKey: String?

    let clientDatabasePrefix: String?
}

class KeyAuthenticationInfo: AuthenticationInfo {

    let type: String = "TEST"

    var jwt: String = ""

    func isValid() -> Bool {
        return true
    }

    func toString() -> String {
        return jwt
    }

    func getUsername() -> String {
        return ""
    }
}

class KeyAuthenticationProvider: AuthenticationProvider {

    var authInfo = KeyAuthenticationInfo()

    func getAuthenticationInfo() async throws -> AuthenticationInfo {
        return authInfo
    }

    func reset() {}

}
