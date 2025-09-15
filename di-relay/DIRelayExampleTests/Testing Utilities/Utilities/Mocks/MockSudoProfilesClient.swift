//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoProfiles

class SudoProfilesClientMock: SudoProfilesClient {

    var config: SudoProfilesClientConfig {
        fatalError("Not implemented")
    }

    // MARK: - Mocked Methods

    // createSudo
    var createSudoResult: Sudo?
    var createSudoError = SudoProfilesClientMock.defaultError
    var createSudoCalled: Bool = false
    func createSudo(input: SudoProfiles.SudoCreateInput) async throws -> SudoProfiles.Sudo {
        createSudoCalled = true
        if let result = createSudoResult {
            return result
        }
        throw createSudoError
    }

    // updateSudo
    var updateSudoResult: Sudo?
    var updateSudoError = SudoProfilesClientMock.defaultError
    func updateSudo(input: SudoProfiles.SudoUpdateInput) async throws -> SudoProfiles.Sudo {
        if let result = updateSudoResult {
            return result
        }
        throw updateSudoError
    }

    // deleteSudo
    var deleteSudoFailure = true
    var deleteSudoError = SudoProfilesClientMock.defaultError
    func deleteSudo(input: SudoProfiles.SudoDeleteInput) async throws {
        if deleteSudoFailure {
            throw deleteSudoError
        }
    }

    // listSudos
    var listSudosResult: [Sudo]?
    var listSudosError = SudoProfilesClientMock.defaultError
    func listSudos(cachePolicy: SudoProfiles.CachePolicy) async throws -> [SudoProfiles.Sudo] {
        if let result = listSudosResult {
            return result
        }
        throw listSudosError
    }

    // getBlob
    var getBlobResult: Data?
    var getBlobError = SudoProfilesClientMock.defaultError
    func getBlob(forClaim claim: SudoProfiles.Claim, cachePolicy: SudoProfiles.CachePolicy) async throws -> Data {
        if let result = getBlobResult {
            return result
        }
        throw getBlobError
    }

    // clearCache
    func clearCache() throws {
        // no-op
    }

    // getOwnershipProof (by Sudo)
    var getOwnershipProofResult: String?
    var getOwnershipProofError = SudoProfilesClientMock.defaultError
    func getOwnershipProof(sudo: SudoProfiles.Sudo, audience: String) async throws -> String {
        if let result = getOwnershipProofResult {
            return result
        }
        throw getOwnershipProofError
    }

    // getOwnershipProof (by sudoId)
    func getOwnershipProof(sudoId: String, audience: String) async throws -> String {
        if let result = getOwnershipProofResult {
            return result
        }
        throw getOwnershipProofError
    }

    // unsubscribe
    func unsubscribe(id: String) {
        // no-op
    }

    // generateEncryptionKey
    func generateEncryptionKey() throws -> String {
        return ""
    }

    // getSymmetricKeyId
    func getSymmetricKeyId() throws -> String? {
        return nil
    }

    // importEncryptionKeys
    func importEncryptionKeys(keys: [EncryptionKey], currentKeyId: String) throws {
        // no-op
    }

    // exportEncryptionKeys
    func exportEncryptionKeys() throws -> [EncryptionKey] {
        return []
    }

    // MARK: - Static Defaults
    static var defaultError: Error {
        return NSError(domain: "unit-test", code: 0, userInfo: nil) as Error
    }

    static var sudoLabel = "Create Sudo"

    // subscribe
    func subscribe(id: String, subscriber: SudoSubscriber) throws {
        // no-op
    }

    func subscribe(id: String, changeType: SudoChangeType, subscriber: SudoSubscriber) throws {
        // no-op
    }

    // unsubscribe (changeType)
    func unsubscribe(id: String, changeType: SudoChangeType) {
        // no-op
    }

    // unsubscribeAll
    func unsubscribeAll() {
        // no-op
    }

    // getOutstandingRequestsCount
    var getOutstandingRequestsCountResult: Int = 0
    func getOutstandingRequestsCount() -> Int {
        return getOutstandingRequestsCountResult
    }

    // reset
    func reset() throws {
        // no-op
    }

    // redeem
    var redeemResult: Swift.Result<[Entitlement], Error> = .failure(SudoProfilesClientMock.defaultError)
    func redeem(token: String, type: String, completion: @escaping (Swift.Result<[Entitlement], Error>) -> Void) throws {
        completion(redeemResult)
    }
}
