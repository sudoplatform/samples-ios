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

    // MARK: - Email Mask Overrides

    override func getEmailMaskDomains() async throws -> [String] {
        getEmailMaskDomainsCalled = true
        if let result = getEmailMaskDomainsResult {
            return result
        }
        return ["mask.example.com"]
    }

    override func provisionEmailMask(withInput input: ProvisionEmailMaskInput) async throws -> EmailMask {
        provisionEmailMaskCalled = true
        provisionEmailMaskParameter = input
        if let result = provisionEmailMaskResult {
            return result
        }
        return DataFactory.EmailSDK.generateEmailMask(maskAddress: input.maskAddress, realAddress: input.realAddress)
    }

    override func deprovisionEmailMask(withInput input: DeprovisionEmailMaskInput) async throws -> EmailMask {
        deprovisionEmailMaskCalled = true
        deprovisionEmailMaskParameter = input
        if let result = deprovisionEmailMaskResult {
            return result
        }
        return DataFactory.EmailSDK.generateEmailMask(id: input.emailMaskId)
    }

    override func updateEmailMask(withInput input: UpdateEmailMaskInput) async throws -> EmailMask {
        updateEmailMaskCalled = true
        updateEmailMaskParameter = input
        if let result = updateEmailMaskResult {
            return result
        }
        return DataFactory.EmailSDK.generateEmailMask(id: input.emailMaskId, expiresAt: input.expiresAt, metadata: input.metadata)
    }

    override func enableEmailMask(withInput input: EnableEmailMaskInput) async throws -> EmailMask {
        enableEmailMaskCalled = true
        enableEmailMaskParameter = input
        if let result = enableEmailMaskResult {
            return result
        }
        return DataFactory.EmailSDK.generateEmailMask(id: input.emailMaskId, status: .enabled)
    }

    override func disableEmailMask(withInput input: DisableEmailMaskInput) async throws -> EmailMask {
        disableEmailMaskCalled = true
        disableEmailMaskParameter = input
        if let result = disableEmailMaskResult {
            return result
        }
        return DataFactory.EmailSDK.generateEmailMask(id: input.emailMaskId, status: .disabled)
    }

    override func verifyExternalEmailAddress(withInput input: VerifyExternalEmailAddressInput) async throws -> VerifyExternalEmailAddressResult {
        verifyExternalEmailAddressCalled = true
        verifyExternalEmailAddressParameter = input
        if let result = verifyExternalEmailAddressResult {
            return result
        }
        return VerifyExternalEmailAddressResult(isVerified: true)
    }

    override func listEmailMasksForOwner(withInput input: ListEmailMasksForOwnerInput) async throws -> ListOutput<EmailMask> {
        listEmailMasksForOwnerCalled = true
        listEmailMasksForOwnerParameter = input
        if let result = listEmailMasksForOwnerResult {
            return result
        }
        return ListOutput<EmailMask>(items: [DataFactory.EmailSDK.generateEmailMask()])
    }
}
