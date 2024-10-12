//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoUser
import SudoProfiles
import SudoEmail

class MockSubscriptionToken: SubscriptionToken {
    var cancelCallCount = 0
    func cancel() {
        cancelCallCount += 1
    }
}

class SudoEmailClientSpy: SudoEmailClient {
    var listEmailMessagesCalled: Bool = false
    var listEmailMessagesParameters: ListEmailMessagesInput?
    var listEmailMessagesResult: ListAPIResult<EmailMessage, PartialEmailMessage>?
    func listEmailMessages(withInput input: ListEmailMessagesInput) async throws -> ListAPIResult<EmailMessage, PartialEmailMessage> {
        listEmailMessagesCalled = true
        listEmailMessagesParameters = input
        if let result = listEmailMessagesResult {
            return result
        }
        let successResult = ListAPIResult<EmailMessage, PartialEmailMessage>.ListSuccessResult(
            items: [DataFactory.EmailSDK.generateEmailMessage()]
        )
        return ListAPIResult.success(successResult)
    }

    var getEmailAddressBlocklistCalled: Bool = false
    var getEmailAddressBlocklistResult: [UnsealedBlockedAddress]?
    func getEmailAddressBlocklist() async throws -> [UnsealedBlockedAddress] {
        getEmailAddressBlocklistCalled = true
        if let result = getEmailAddressBlocklistResult {
            return result
        } else {
            return []
        }
    }

    var getEmailMessageWithBodyCalled: Bool = false
    var getEmailMessageWithBodyParameters: GetEmailMessageWithBodyInput?
    var getEmailMessageWithBodyResult: EmailMessageWithBody?
    func getEmailMessageWithBody(withInput input: GetEmailMessageWithBodyInput) async throws -> EmailMessageWithBody? {
        getEmailMessageWithBodyCalled = true
        getEmailMessageWithBodyParameters = input
        if let result = getEmailMessageWithBodyResult {
            return result
        } else {
            return DataFactory.EmailSDK.generateEmailMessageWithBody()
        }
    }

    func blockEmailAddresses(addresses: [String]) async throws -> BatchOperationResult<String, String> {
        return BatchOperationResult<String, String>(status: .success)
    }

    func unblockEmailAddresses(addresses: [String]) async throws -> BatchOperationResult<String, String> {
        return BatchOperationResult<String, String>(status: .success)
    }

    func unblockEmailAddressesByHashedValue(hashedValues: [String]) async throws -> BatchOperationResult<String, String> {
        return BatchOperationResult<String, String>(status: .success)
    }

    func importKeys(archiveData: Data) throws {}

    func exportKeys() throws -> Data {
        return Data.init()
    }

    var updateEmailAddressMetadataCalled: Bool = false
    var updateEmailAddressMetadataParameter: SudoEmail.UpdateEmailAddressMetadataInput?
    func updateEmailAddressMetadata(
        withInput input: SudoEmail.UpdateEmailAddressMetadataInput
    ) async throws -> String {
        updateEmailAddressMetadataCalled = true
        updateEmailAddressMetadataParameter = input
        return "dummyAccountId"
    }

    var deleteEmailMessagesCalled: Bool = false
    var deleteEmailMessagesParameter: [String]?
    var deleteEmailMessagesWillThrow: Bool = false
    var deleteEmailMessagesResult: SudoEmail.BatchOperationResult<String, String>?
    func deleteEmailMessages(
        withIds ids: [String]
    ) async throws -> SudoEmail.BatchOperationResult<String, String> {
        deleteEmailMessagesCalled = true
        deleteEmailMessagesParameter = ids
        if deleteEmailMessagesWillThrow {
            throw AnyError("Test generated error")
        }
        if deleteEmailMessagesResult == nil {
            throw AnyError("Please add base result to `SudoEmailClientSpy.updateEmailMessages`")
        }
        return deleteEmailMessagesResult!
    }

    var updateEmailMessagesCalled: Bool = false
    var updateEmailMessagesParameter: SudoEmail.UpdateEmailMessagesInput?
    var updateEmailMessagesWillThrow: Bool = false
    var updateEmailMessagesResult: SudoEmail.BatchOperationResult<UpdatedEmailMessageSuccess, EmailMessageOperationFailureResult>?
    func updateEmailMessages(
        withInput input: SudoEmail.UpdateEmailMessagesInput
    ) async throws -> SudoEmail.BatchOperationResult<UpdatedEmailMessageSuccess, EmailMessageOperationFailureResult> {
        updateEmailMessagesCalled = true
        updateEmailMessagesParameter = input
        if updateEmailMessagesWillThrow {
            throw AnyError("Test generated error")
        }
        if updateEmailMessagesResult == nil {
            throw AnyError("Please add base result to `SudoEmailClientSpy.updateEmailMessages`")
        }
        return updateEmailMessagesResult!
    }

    var createDraftEmailMessageCalled: Bool = false
    var createDraftEmailMessageParameter: SudoEmail.CreateDraftEmailMessageInput?
    func createDraftEmailMessage(
        withInput input: SudoEmail.CreateDraftEmailMessageInput
    ) async throws -> SudoEmail.DraftEmailMessageMetadata {
        createDraftEmailMessageCalled = true
        createDraftEmailMessageParameter = input
        return SudoEmail.DraftEmailMessageMetadata(
            id: "dummyId",
            emailAddressId: input.senderEmailAddressId,
            updatedAt: Date()
        )
    }

    var updateDraftEmailMessageCalled: Bool = false
    var updateDraftEmailMessageParameter: SudoEmail.UpdateDraftEmailMessageInput?
    func updateDraftEmailMessage(
        withInput input: SudoEmail.UpdateDraftEmailMessageInput
    ) async throws -> SudoEmail.DraftEmailMessageMetadata {
        updateDraftEmailMessageCalled = true
        updateDraftEmailMessageParameter = input
        return SudoEmail.DraftEmailMessageMetadata(
            id: "dummyId",
            emailAddressId: input.senderEmailAddressId,
            updatedAt: Date()
        )
    }

    var deleteDraftEmailMessagesCalled: Bool = false
    var deleteDraftEmailMessagesParameter: SudoEmail.DeleteDraftEmailMessagesInput?
    var deleteDraftEmailMessagesWillThrow: Bool = false
    func deleteDraftEmailMessages(
        withInput input: SudoEmail.DeleteDraftEmailMessagesInput
    ) async throws -> SudoEmail.BatchOperationResult<String, EmailMessageOperationFailureResult> {
        deleteDraftEmailMessagesCalled = true
        deleteDraftEmailMessagesParameter = input
        if deleteDraftEmailMessagesWillThrow {
            throw AnyError("Test generated error")
        }
        return SudoEmail.BatchOperationResult(status: .success)
    }

    var listEmailAddressesForSudoIdCalled: Bool = false
    var listEmailAddressesForSudoIdParameter: SudoEmail.ListEmailAddressesForSudoIdInput?
    func listEmailAddressesForSudoId(
        withInput input: SudoEmail.ListEmailAddressesForSudoIdInput
    ) async throws -> SudoEmail.ListOutput<SudoEmail.EmailAddress> {
        listEmailAddressesForSudoIdCalled = true
        listEmailAddressesForSudoIdParameter = input
        let emailAddress = DataFactory.EmailSDK.generateEmailAddress()
        return SudoEmail.ListOutput<SudoEmail.EmailAddress>(
            items: [emailAddress]
        )
    }

    var listEmailFoldersForEmailAddressIdCalled: Bool = false
    var listEmailFoldersForEmailAddressIdParameter: SudoEmail.ListEmailFoldersForEmailAddressIdInput?
    func listEmailFoldersForEmailAddressId(
        withInput input: SudoEmail.ListEmailFoldersForEmailAddressIdInput
    ) async throws -> SudoEmail.ListOutput<SudoEmail.EmailFolder> {
        listEmailFoldersForEmailAddressIdCalled = true
        listEmailFoldersForEmailAddressIdParameter = input
        let emailFolder = DataFactory.EmailSDK.generateEmailFolder()
        return SudoEmail.ListOutput<SudoEmail.EmailFolder>(
            items: [emailFolder]
        )
    }

    var listEmailMessagesForEmailAddressIdCalled: Bool = false
    var listEmailMessagesForEmailAddressIdParameter: SudoEmail.ListEmailMessagesForEmailAddressInput?
    func listEmailMessagesForEmailAddressId(
        withInput input: SudoEmail.ListEmailMessagesForEmailAddressInput
    ) async throws -> SudoEmail.ListAPIResult<SudoEmail.EmailMessage, SudoEmail.PartialEmailMessage> {
        listEmailMessagesForEmailAddressIdCalled = true
        listEmailMessagesForEmailAddressIdParameter = input
        let successResult = ListAPIResult<EmailMessage, PartialEmailMessage>.ListSuccessResult(
            items: [DataFactory.EmailSDK.generateEmailMessage()]
        )
        return ListAPIResult.success(successResult)
    }

    var listEmailMessagesForEmailFolderIdCalled: Bool = false
    var listEmailMessagesForEmailFolderIdCalledCount: Int = 0
    var listEmailMessagesForEmailFolderIdParameters: [SudoEmail.ListEmailMessagesForEmailFolderIdInput] = []
    var listEmailMessagesForEmailFolderIdResult: ListAPIResult<EmailMessage, PartialEmailMessage>?
    func listEmailMessagesForEmailFolderId(
        withInput input: SudoEmail.ListEmailMessagesForEmailFolderIdInput
    ) async throws -> SudoEmail.ListAPIResult<SudoEmail.EmailMessage, SudoEmail.PartialEmailMessage> {
        listEmailMessagesForEmailFolderIdCalled = true
        listEmailMessagesForEmailFolderIdCalledCount += 1
        listEmailMessagesForEmailFolderIdParameters.append(input)
        if listEmailMessagesForEmailFolderIdResult != nil {
            return listEmailMessagesForEmailFolderIdResult!
        } else {
            throw AnyError(
                "Please add base result to `SudoEmailClientSpy.listEmailMessagesForEmailFolderId`"
            )
        }
    }

    var getDraftEmailMessageCalled: Bool = false
    var getDraftEmailMessageParameter: SudoEmail.GetDraftEmailMessageInput?
    func getDraftEmailMessage(
        withInput input: SudoEmail.GetDraftEmailMessageInput
    ) async throws -> SudoEmail.DraftEmailMessage? {
        getDraftEmailMessageCalled = true
        getDraftEmailMessageParameter = input
        let rfc822String = DataFactory.TestData.complexDataEmail
        guard let data = rfc822String.data(using: .utf8) else {
            throw AnyError("Unable to convert string to utf8 bytes")
        }
        return DataFactory.EmailSDK.generateDraftEmailMessage(rfc822Data: data)
    }

    var listDraftEmailMessagesCalled: Bool = false
    var listDraftEmailMessagesResult: [DraftEmailMessage]?
    func listDraftEmailMessages() async throws -> [DraftEmailMessage] {
        listDraftEmailMessagesCalled = true
        if let result = listDraftEmailMessagesResult {
            return result
        } else {
            return [DataFactory.EmailSDK.generateDraftEmailMessage()]
        }
    }

    var listDraftEmailMessagesForEmailAddressIdCalled: Bool = false
    var listDraftEmailMessagesForEmailAddressIdParameters: (String)?
    var listDraftEmailMessagesForEmailAddressIdResult: [DraftEmailMessage]?
    func listDraftEmailMessagesForEmailAddressId(emailAddressId: String) async throws -> [DraftEmailMessage] {
        listDraftEmailMessagesForEmailAddressIdCalled = true
        listDraftEmailMessagesForEmailAddressIdParameters = (emailAddressId)
        if let result = listDraftEmailMessagesForEmailAddressIdResult {
            return result
        } else {
            return [DataFactory.EmailSDK.generateDraftEmailMessage(emailAddressId: emailAddressId)]
        }
    }

    var listDraftEmailMessageMetadataCalled: Bool = false
    var listDraftEmailMessageMetadataReturnsEmpty: Bool = false
    func listDraftEmailMessageMetadata() async throws -> [SudoEmail.DraftEmailMessageMetadata] {
        listDraftEmailMessageMetadataCalled = true
        if listDraftEmailMessageMetadataReturnsEmpty {
            return []
        } else {
            return [DataFactory.EmailSDK.generateDraftEmailMessageMetadata()]
        }
    }

    var listDraftEmailMessageMetadataForEmailAddressIdCalled: Bool = false
    var listDraftEmailMessageMetadataForEmailAddressIdParameters: (String)?
    var listDraftEmailMessageMetadataForEmailAddressIdResult: [DraftEmailMessageMetadata]?
    var listDraftEmailMessageMetadataForEmailAddressIdReturnsEmpty: Bool = false
    func listDraftEmailMessageMetadataForEmailAddressId(emailAddressId: String) async throws -> [DraftEmailMessageMetadata] {
        listDraftEmailMessageMetadataForEmailAddressIdCalled = true
        listDraftEmailMessageMetadataForEmailAddressIdParameters = (emailAddressId)
        if listDraftEmailMessageMetadataForEmailAddressIdReturnsEmpty {
            return []
        } else {
            if let result = listDraftEmailMessageMetadataForEmailAddressIdResult {
                return result
            } else {
                return [DataFactory.EmailSDK.generateDraftEmailMessageMetadata(emailAddressId: emailAddressId)]
            }
        }
    }

    var getConfigurationDataCalled: Bool = false
    func getConfigurationData() async throws -> SudoEmail.ConfigurationData {
        getConfigurationDataCalled = true
        return DataFactory.EmailSDK.generateConfigurationData()
    }

    var unsubscribeAllCalled: Bool = false
    func unsubscribeAll() {
        unsubscribeAllCalled = true
    }

    var subscribeToEmailMessageCreatedCalled: Bool = false
    var subscribeToEmailMessageCreatedParameters: (
        withDirection: EmailMessage.Direction?, resultHandler: ClientCompletion<EmailMessage>
    )?
    func subscribeToEmailMessageCreated(
        withDirection direction: EmailMessage.Direction?,
        resultHandler: @escaping ClientCompletion<EmailMessage>
    ) async throws -> SubscriptionToken? {
        subscribeToEmailMessageCreatedCalled = true
        subscribeToEmailMessageCreatedParameters = (direction, resultHandler)
        return MockSubscriptionToken()
    }

    var subscribeToEmailMessageDeletedCalled: Bool = false
    var subscribeToEmailMessageDeletedParameters: (
        id: String?, resultHandler: ClientCompletion<EmailMessage>?
    )
    func subscribeToEmailMessageDeleted(
        withId id: String?,
        resultHandler: @escaping ClientCompletion<EmailMessage>
    ) async throws -> SubscriptionToken? {
        subscribeToEmailMessageDeletedCalled = true
        subscribeToEmailMessageDeletedParameters = (id: id, resultHandler: resultHandler)
        return MockSubscriptionToken()
    }

    var subscribeToEmailMessageUpdatedCalled: Bool = false
    var subscribeToEmailMessageUpdatedParameters: (
        id: String?, resultHandler: ClientCompletion<EmailMessage>?
    )
    func subscribeToEmailMessageUpdated(
        withId id: String?,
        resultHandler: @escaping ClientCompletion<EmailMessage>
    ) async throws -> (any SudoEmail.SubscriptionToken)? {
        subscribeToEmailMessageUpdatedCalled = true
        subscribeToEmailMessageUpdatedParameters = (id: id, resultHandler: resultHandler)
        return MockSubscriptionToken()
    }

    var checkEmailAddressAvailabilityCalled: Bool = false
    var checkEmailAddressAvailabilityParameters: (localParts: [String], domains: [String]?)?
    var checkEmailAddressAvailabilityResult: [String]?
    var checkEmailAddressAvailabilityError = AnyError("Please add base result to `SudoEmailClientSpy.checkEmailAddressAvailability`")
    func checkEmailAddressAvailability(
        withInput input: CheckEmailAddressAvailabilityInput
    ) async throws -> [String] {
        checkEmailAddressAvailabilityCalled = true
        checkEmailAddressAvailabilityParameters = (input.localParts, input.domains)
        if checkEmailAddressAvailabilityResult != nil {
            return checkEmailAddressAvailabilityResult!
        }
        throw checkEmailAddressAvailabilityError
    }

    var provisionEmailAddressCalled: Bool = false
    var provisionEmailAddressParameters: (emailAddress: String, ownershipProofToken: String,
                                          alias: String?)?
    var provisionEmailAddressResult: EmailAddress?
    var provisionEmailAddressError = AnyError(
        "Please add base result to `SudoEmailClientSpy.provisionEmailAddress`"
    )
    func provisionEmailAddress(
        withInput input: ProvisionEmailAddressInput
    ) async throws -> EmailAddress {
        provisionEmailAddressCalled = true
        provisionEmailAddressParameters = (input.emailAddress, input.ownershipProofToken, input.alias)

        if provisionEmailAddressResult != nil {
            return provisionEmailAddressResult!
        }
        throw provisionEmailAddressError
    }

    var deprovisionEmailAddressCalled: Bool = false
    var deprovisionEmailAddressParameter: String?
    var deprovisionEmailAddressResult: EmailAddress?
    var deprovisionEmailAddressError = AnyError(
        "Please add base result to `SudoEmailClientSpy.deprovisionEmailAddress`"
    )
    func deprovisionEmailAddress(_ id: String) async throws -> EmailAddress {
        deprovisionEmailAddressCalled = true
        deprovisionEmailAddressParameter = id

        if deprovisionEmailAddressResult != nil {
            return deprovisionEmailAddressResult!
        }
        throw deprovisionEmailAddressError
    }

    var sendEmailMessageCalled: Bool = false
    var sendEmailMessageParameters: SendEmailMessageInput?
    var sendEmailMessageResult: SendEmailMessageResult?
    var sendEmailMessageError = AnyError(
        "Please add base result to `SudoEmailClientSpy.sendEmailMessage`"
    )
    func sendEmailMessage(withInput input: SendEmailMessageInput) async throws -> SendEmailMessageResult {
        sendEmailMessageCalled = true
        sendEmailMessageParameters = input

        if sendEmailMessageResult != nil {
            return sendEmailMessageResult!
        }
        throw sendEmailMessageError
    }

    var deleteEmailMessageCalled: Bool = false
    var deleteEmailMessageParameter: String?
    var deleteEmailMessageResult: String?
    var deleteEmailMessageError = AnyError(
        "Please add base result to `SudoEmailClientSpy.deleteEmailMessage`"
    )
    func deleteEmailMessage(withId id: String) async throws -> String? {
        deleteEmailMessageCalled = true
        deleteEmailMessageParameter = id

        if deleteEmailMessageResult != nil {
            return deleteEmailMessageResult!
        }
        throw deleteEmailMessageError
    }

    var getSupportedEmailDomainsCalled: Bool = false
    var getSupportedEmailDomainsParameter: SudoEmail.CachePolicy?
    var getSupportedEmailDomainsResult: [String]?
    var getSupportedEmailDomainsError = AnyError(
        "Please add base result to `SudoEmailClientSpy.getSupportedEmailDomains`"
    )
    func getSupportedEmailDomains(_ cachePolicy: CachePolicy) async throws -> [String] {
        getSupportedEmailDomainsCalled = true
        getSupportedEmailDomainsParameter = cachePolicy

        if getSupportedEmailDomainsResult != nil {
            return getSupportedEmailDomainsResult!
        }
        throw getSupportedEmailDomainsError
    }

    var getConfiguredEmailDomainsCalled: Bool = false
    var getConfiguredEmailDomainsParameter: SudoEmail.CachePolicy?
    var getConfiguredEmailDomainsResult: [String]?
    var getConfiguredEmailDomainsError = AnyError(
        "Please add base result to `SudoEmailClientSpy.getConfiguredEmailDomains`"
    )
    func getConfiguredEmailDomains(_ cachePolicy: CachePolicy) async throws -> [String] {
        getConfiguredEmailDomainsCalled = true
        getConfiguredEmailDomainsParameter = cachePolicy

        if getConfiguredEmailDomainsResult != nil {
            return getConfiguredEmailDomainsResult!
        }
        throw getConfiguredEmailDomainsError
    }

    var getEmailAddressCalled: Bool = false
    var getEmailAddressParameters: (id: String, cachePolicy: SudoEmail.CachePolicy?)?
    var getEmailAddressResult: EmailAddress?
    var getEmailAddressError = AnyError(
        "Please add base result to `SudoEmailClientSpy.getEmailAddress`"
    )
    func getEmailAddress(withInput input: GetEmailAddressInput) async throws -> EmailAddress? {
        getEmailAddressCalled = true
        getEmailAddressParameters = (id: input.id, cachePolicy: input.cachePolicy)

        if getEmailAddressResult != nil {
            return getEmailAddressResult!
        }
        throw getEmailAddressError
    }

    var listEmailAddressesCalled: Bool = false
    var listEmailAddressesParameters: ListEmailAddressesInput?
    var listEmailAddressesResult: ListOutput<EmailAddress>?
    var listEmailAddressesError = AnyError(
        "Please add base result to `SudoEmailClientSpy.listEmailAddresses`"
    )
    func listEmailAddresses(
        withInput input: ListEmailAddressesInput
    ) async throws -> ListOutput<EmailAddress> {
        listEmailAddressesCalled = true
        listEmailAddressesParameters = input

        if listEmailAddressesResult != nil {
            return listEmailAddressesResult!
        }
        throw listEmailAddressesError
    }

    var getEmailMessageCalled: Bool = false
    var getEmailMessageCallCount = 0
    var getEmailMessageParameters: [(id: String, cachePolicy: SudoEmail.CachePolicy?)]? = []
    var getEmailMessageResult: EmailMessage?
    var getEmailMessageError = AnyError(
        "Please add base result to `SudoEmailClientSpy.getEmailMessage`"
    )

    @MainActor
    func getEmailMessage(withInput input: GetEmailMessageInput) async throws -> EmailMessage? {
        getEmailMessageCalled = true
        getEmailMessageCallCount += 1
        getEmailMessageParameters?.append((id: input.id, cachePolicy: input.cachePolicy))

        if getEmailMessageResult != nil {
            return getEmailMessageResult!
        }
        throw getEmailMessageError
    }

    var getEmailMessageRFC822DataCalled: Bool = false
    var getEmailMessageRFC822DataParameters: (id: String, emailAddressId: String)?
    var getEmailMessageRfc822DataResult: Data?
    var getEmailMessageRfc822DataError = AnyError(
        "Please add base result to `SudoEmailClientSpy.getEmailMessageRfc822Data`"
    )
    func getEmailMessageRfc822Data(
        withInput input: GetEmailMessageRfc822DataInput
    ) async throws -> Data {
        getEmailMessageRFC822DataCalled = true
        getEmailMessageRFC822DataParameters = (input.id, input.emailAddressId)

        if getEmailMessageRfc822DataResult != nil {
            return getEmailMessageRfc822DataResult!
        }
        throw getEmailMessageRfc822DataError
    }

    var lookupEmailAddressesPublicInfoCalled: Bool = false
    var lookupEmailAddressesPublicInfoParameter: LookupEmailAddressesPublicInfoInput?
    var lookupEmailAddressesPublicInfoResult: [EmailAddressPublicInfo]? = []
    var lookupEmailAddressesPublicInfoError = AnyError(
        "Please add base result to `SudoEmailClientSpy.lookupEmailAddressesPublicInfo`"
    )

    func lookupEmailAddressesPublicInfo(
        withInput input: LookupEmailAddressesPublicInfoInput
    ) async throws -> [EmailAddressPublicInfo] {
        lookupEmailAddressesPublicInfoCalled = true
        lookupEmailAddressesPublicInfoParameter = input

        if let lookupEmailAddressesPublicInfoResult = lookupEmailAddressesPublicInfoResult {
            return lookupEmailAddressesPublicInfoResult
        }
        throw lookupEmailAddressesPublicInfoError
    }

    var resetCalled: Bool = false
    func reset() throws {
        resetCalled = true
    }
}
