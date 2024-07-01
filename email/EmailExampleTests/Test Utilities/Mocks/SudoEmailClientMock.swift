//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSAppSync
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

    override func reset() throws {
        // no-op
    }

    override func getEmailMessageRfc822Data(withInput input: GetEmailMessageRfc822DataInput) async throws -> Data {
        guard let result = DataFactory.TestData.complexDataEmail.data(using: .utf8) else {
            fatalError("Failed to convert to UTF8")
        }
        return result
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
}
