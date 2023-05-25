//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoProfiles

class MockSudoProfilesClient: SudoProfilesClient {

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

    func subscribe(id: String, subscriber: SudoSubscriber) async throws {

    }

    var createSudoResult: Result<Sudo, Error> = .failure(defaultError)
    var createSudoCalled: Bool = false
    func createSudo(sudo: Sudo) async throws -> Sudo {
        createSudoCalled = true
        switch createSudoResult {
        case .success(let sudo):
            return sudo
        case .failure(let error):
            throw error
        }
    }

    var updateSudoResult: Result<Sudo, Error> = .failure(defaultError)
    func updateSudo(sudo: Sudo) async throws -> Sudo {
        switch updateSudoResult {
        case .success(let sudo):
            return sudo
        case .failure(let error):
            throw error
        }
    }

    var deleteSudoError: Error?
    var deleteSudoCalled: Bool = false
    func deleteSudo(sudo: Sudo) async throws {
        deleteSudoCalled = true
        if let deleteSudoError = deleteSudoError {
            throw deleteSudoError
        }
    }

    var listSudosResult: [Sudo]?
    var listSudosCalled: Bool = false
    func listSudos(option: ListOption) async throws -> [Sudo] {
        listSudosCalled = true
        if let listSudosResult = listSudosResult {
            return listSudosResult
        }
        throw AnyError("Please add result to MockSudoProfilesClient listSudosResult")
    }

    var getOutstandingRequestsCountResult: Int = 0
    func getOutstandingRequestsCount() -> Int {
        return getOutstandingRequestsCountResult
    }

    var resetCalled: Bool = false
    func reset() throws {
        resetCalled = true
    }

    func subscribe(id: String, changeType: SudoChangeType, subscriber: SudoSubscriber) async throws {
        // no-op
    }

    func unsubscribe(id: String, changeType: SudoChangeType) {
        // no-op
    }

    func unsubscribeAll() {
        // no-op
    }

    func getOwnershipProof(sudo: Sudo, audience: String) async throws -> String {
        // no-op
        return ""
    }
}
