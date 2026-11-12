//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoUser
import SudoProfiles
import SudoEmail

class SudoEmailClientMockSpy: SudoEmailClientSpy {
    static var defaultError: Error {
        return NSError(domain: "unit-test", code: 0, userInfo: nil) as Error
    }

    let sudoId: String = "UnitTestSudoId"

    var emailAddress = DataFactory.EmailSDK.generateEmailAddress(
        address: "testie@test.org"
    )

    override func reset() async throws {
        // no-op
    }

    override func provisionEmailAddress(withInput input: ProvisionEmailAddressInput) async throws -> EmailAddress {
        _ = try await super.provisionEmailAddress(withInput: input)
        if input.emailAddress.starts(with: "fail") {
            throw SudoEmailClientMockSpy.defaultError
        } else {
            let provisionedEmailAddress = DataFactory.EmailSDK.generateEmailAddress(address: input.emailAddress)
            return provisionedEmailAddress
        }
    }

    override func listEmailAddresses(withInput input: ListEmailAddressesInput) async throws -> ListOutput<EmailAddress> {
        _ = try await super.listEmailAddresses(withInput: input)
        if let result = listEmailAddressesResult {
            return result
        }
        return ListOutput(items: [emailAddress])
    }

    override func deprovisionEmailAddress(_ id: String) async throws -> EmailAddress {
        _ = try await super.deprovisionEmailAddress(id)
        if id.starts(with: "fail") {
            throw SudoEmailClientMockSpy.defaultError
        } else {
            return self.emailAddress
        }
    }

    override func lookupEmailAddressesPublicInfo(withInput input: LookupEmailAddressesPublicInfoInput) async throws -> [EmailAddressPublicInfo] {
        for address in input.emailAddresses where address.starts(with: "fail") {
            throw SudoEmailClientMockSpy.defaultError
        }

        let lookupEmailAddressesResult = try await super.lookupEmailAddressesPublicInfo(withInput: input)
        return lookupEmailAddressesResult
    }

    // MARK: - Email Alias Overrides

    override func getEmailAliasDomains() async throws -> [String] {
        getEmailAliasDomainsCalled = true
        if let result = getEmailAliasDomainsResult {
            return result
        }
        return ["alias.example.com"]
    }

    override func provisionEmailAlias(withInput input: ProvisionEmailAliasInput) async throws -> EmailAlias {
        provisionEmailAliasCalled = true
        provisionEmailAliasParameter = input
        if let result = provisionEmailAliasResult {
            return result
        }
        return DataFactory.EmailSDK.generateEmailAlias(aliasAddress: input.aliasAddress, realAddress: input.realAddress)
    }

    override func deprovisionEmailAlias(withInput input: DeprovisionEmailAliasInput) async throws -> EmailAlias {
        deprovisionEmailAliasCalled = true
        deprovisionEmailAliasParameter = input
        if let result = deprovisionEmailAliasResult {
            return result
        }
        return DataFactory.EmailSDK.generateEmailAlias(id: input.emailAliasId)
    }

    override func updateEmailAlias(withInput input: UpdateEmailAliasInput) async throws -> EmailAlias {
        updateEmailAliasCalled = true
        updateEmailAliasParameter = input
        if let result = updateEmailAliasResult {
            return result
        }
        return DataFactory.EmailSDK.generateEmailAlias(id: input.emailAliasId, expiresAt: input.expiresAt, metadata: input.metadata)
    }

    override func enableEmailAlias(withInput input: EnableEmailAliasInput) async throws -> EmailAlias {
        enableEmailAliasCalled = true
        enableEmailAliasParameter = input
        if let result = enableEmailAliasResult {
            return result
        }
        return DataFactory.EmailSDK.generateEmailAlias(id: input.emailAliasId, status: .enabled)
    }

    override func disableEmailAlias(withInput input: DisableEmailAliasInput) async throws -> EmailAlias {
        disableEmailAliasCalled = true
        disableEmailAliasParameter = input
        if let result = disableEmailAliasResult {
            return result
        }
        return DataFactory.EmailSDK.generateEmailAlias(id: input.emailAliasId, status: .disabled)
    }

    override func verifyExternalEmailAddress(withInput input: VerifyExternalEmailAddressInput) async throws -> VerifyExternalEmailAddressResult {
        verifyExternalEmailAddressCalled = true
        verifyExternalEmailAddressParameter = input
        if let result = verifyExternalEmailAddressResult {
            return result
        }
        return VerifyExternalEmailAddressResult(isVerified: true)
    }

    override func listEmailAliasesForOwner(withInput input: ListEmailAliasesForOwnerInput) async throws -> ListOutput<EmailAlias> {
        listEmailAliasesForOwnerCalled = true
        listEmailAliasesForOwnerParameter = input
        if let result = listEmailAliasesForOwnerResult {
            return result
        }
        return ListOutput<EmailAlias>(items: [DataFactory.EmailSDK.generateEmailAlias()])
    }
}
