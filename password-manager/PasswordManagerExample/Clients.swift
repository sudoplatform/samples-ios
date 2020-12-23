//
//  Clients.swift
//  PasswordManagerExample
//
//  Copyright © 2020 Sudo Platform. All rights reserved.
//

import Foundation
import UIKit
import SudoUser
import SudoKeyManager
import SudoPasswordManager
import SudoProfiles
import SudoConfigManager
import AWSMobileClient

class Clients {
    static private(set) var userClient: SudoUserClient!
    static private(set) var keyManager: SudoKeyManager!
    static private(set) var authenticator: Authenticator!
    static private(set) var passwordManagerClient: PasswordManagerClient!
    static private(set) var sudoProfilesClient: SudoProfilesClient!

    static func configure() throws {
        self.userClient = try DefaultSudoUserClient(keyNamespace: "ids")

        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.sudoProfilesClient = try DefaultSudoProfilesClient(sudoUserClient: self.userClient, blobContainerURL: documentsDir)

        self.keyManager = SudoKeyManagerImpl(serviceName: "com.sudoplatform.passwordmanager", keyTag: "com.sudoplatform", namespace: "client")

        self.authenticator = Authenticator(userClient: userClient, keyManager: keyManager)

        self.passwordManagerClient = try PasswordManager(sudoUserClient: self.userClient, fileStorage: nil).getClient()
    }

    static func resetClients() throws {
        try passwordManagerClient.reset()
        try sudoProfilesClient.reset()
        try userClient.reset()
    }
}

