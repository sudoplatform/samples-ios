//
//  ConfigurationProvider.swift
//  TelephonyExample
//
//  Copyright © 2020 Anonyome Labs. All rights reserved.
//

import Foundation
import SudoTelephony
import AWSAppSync
import SudoUser

struct ConfigurationProvider: AWSAppSync.AWSAppSyncServiceConfigProvider {
    
    let endpoint: URL
    
    let region: AWSRegionType
    
    let authType: AWSAppSyncAuthType
    
    let apiKey: String?
    
    let clientDatabasePrefix: String?
}

class KeyAuthenticationInfo: AuthenticationInfo {
    
    static var type: String = "TEST"
    
    var jwt: String = ""
    
    func isValid() -> Bool {
        return true
    }
    
    func toString() -> String {
        return jwt
    }
    
}

class KeyAuthenticationProvider: AuthenticationProvider {
    
    var authInfo = KeyAuthenticationInfo()
    
    func getAuthenticationInfo() throws -> AuthenticationInfo {
        return authInfo
    }

    func reset() {}
    
}
