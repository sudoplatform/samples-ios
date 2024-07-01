//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoProfiles

class SudoProfilesClientMock: SudoProfilesClient {

    func unsubscribe(id: String) {
    }

    func generateEncryptionKey() throws -> String {
        return ""
    }

    func getSymmetricKeyId() throws -> String? {
        return nil
    }

    func importEncryptionKeys(keys: [EncryptionKey], currentKeyId: String) throws {
    }

    func exportEncryptionKeys() throws -> [EncryptionKey] {
        return []
    }

    static var defaultError: Error {
        return NSError(domain: "unit-test", code: 0, userInfo: nil) as Error
    }

    static var sudoLabel = "UnitTestSudoLabel"

    func subscribe(id: String, subscriber: SudoSubscriber) throws {

    }

    var createSudoResult: Sudo?
    var createSudoError = defaultError
    var createSudoCalled: Bool = false
    func createSudo(sudo: Sudo) async throws -> Sudo {
        createSudoCalled = true
        if createSudoResult != nil {
            return createSudoResult!
        }
        throw createSudoError
    }

    var updateSudoResult: Sudo?
    var updateSudoError = defaultError
    func updateSudo(sudo: Sudo) async throws -> Sudo {
        if updateSudoResult != nil {
            return updateSudoResult!
        }
        throw updateSudoError
    }

    var deleteSudoFailure = true
    var deleteSudoError = defaultError
    func deleteSudo(sudo: Sudo) async throws {
        if deleteSudoFailure {
            throw deleteSudoError
        }
    }

    var listSudosResult: [Sudo]?
    var listSudosError = defaultError
    func listSudos(option: ListOption) async throws -> [Sudo] {
        if listSudosResult != nil {
            if option == .cacheOnly {
                return listSudosResult!
            } else {
                var testSudo = Sudo()
                testSudo.label = SudoProfilesClientMock.sudoLabel
                testSudo.id = "UnitTestSudoId"
                return [testSudo]
            }
        }
        throw listSudosError
    }

    var getOutstandingRequestsCountResult: Int = 0
    func getOutstandingRequestsCount() -> Int {
        return getOutstandingRequestsCountResult
    }

    func reset() throws {
        // no-op
    }

    func subscribe(id: String, changeType: SudoChangeType, subscriber: SudoSubscriber) throws {
        // no-op
    }

    func unsubscribe(id: String, changeType: SudoChangeType) {
        // no-op
    }

    func unsubscribeAll() {
        // no-op
    }

    var getOwnershipProofResult: String?
    var getOwnershipProofError = defaultError
    func getOwnershipProof(sudo: Sudo, audience: String) async throws -> String {
        if getOwnershipProofResult != nil {
            return getOwnershipProofResult!
        }
        throw getOwnershipProofError
    }

    var redeemResult: Swift.Result<[Entitlement], Error> = .failure(defaultError)
    func redeem(token: String, type: String, completion: @escaping (Swift.Result<[Entitlement], Error>) -> Void) throws {
        completion(redeemResult)
    }
}
