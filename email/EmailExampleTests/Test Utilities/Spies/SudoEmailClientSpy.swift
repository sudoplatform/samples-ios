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

    func blockEmailAddresses(
        addresses: [String],
        action: UnsealedBlockedAddress.BlockedAddressAction,
        emailAddressId: String?,
        blockLevel: BlockedEmailAddressLevel
    ) async throws -> BatchOperationResult<String, String> {
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
    var deleteEmailMessagesResult: SudoEmail.BatchOperationResult<SudoEmail.DeleteEmailMessageSuccessResult, SudoEmail.EmailMessageOperationFailureResult>?
    func deleteEmailMessages(
        withIds ids: [String]
    ) async throws -> SudoEmail.BatchOperationResult<SudoEmail.DeleteEmailMessageSuccessResult, SudoEmail.EmailMessageOperationFailureResult> {
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

    var deleteMessagesForFolderIdCalled: Bool = false
    var deleteMessagesForFolderIdParameter: SudoEmail.DeleteMessagesForFolderIdInput?
    var deleteMessagesForFolderIdWillThrow: Bool = false
    var deleteMessagesForFolderIdResult: String?
    func deleteMessagesForFolderId(withInput input: SudoEmail.DeleteMessagesForFolderIdInput) async throws -> String {
        deleteMessagesForFolderIdCalled = true
        deleteMessagesForFolderIdParameter = input
        if deleteMessagesForFolderIdWillThrow {
            throw AnyError("Test generated error")
        }
        if deleteMessagesForFolderIdResult == nil {
            throw AnyError("Please add base result to `SudoEmailClientSpy.deleteMessagesForFolderId`")
        }
        return deleteMessagesForFolderIdResult!
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
    ) async throws -> SudoEmail.BatchOperationResult<SudoEmail.DeleteEmailMessageSuccessResult, SudoEmail.EmailMessageOperationFailureResult> {
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
    var listDraftEmailMessageMetadataForEmailAddressIdParameters: ListDraftEmailMessageMetadataForEmailAddressIdInput?
    var listDraftEmailMessageMetadataForEmailAddressIdResult: ListOutput<DraftEmailMessageMetadata>?
    var listDraftEmailMessageMetadataForEmailAddressIdReturnsEmpty: Bool = false
    func listDraftEmailMessageMetadataForEmailAddressId(
        withInput input: ListDraftEmailMessageMetadataForEmailAddressIdInput
    ) async throws -> ListOutput<DraftEmailMessageMetadata> {
        listDraftEmailMessageMetadataForEmailAddressIdCalled = true
        listDraftEmailMessageMetadataForEmailAddressIdParameters = input
        if listDraftEmailMessageMetadataForEmailAddressIdReturnsEmpty {
            return ListOutput<DraftEmailMessageMetadata>(items: [])
        } else {
            if let result = listDraftEmailMessageMetadataForEmailAddressIdResult {
                return result
            } else {
                return ListOutput<DraftEmailMessageMetadata>(
                    items: [DataFactory.EmailSDK.generateDraftEmailMessageMetadata(emailAddressId: input.emailAddressId)]
                )
            }
        }
    }

    var getConfigurationDataCalled: Bool = false
    func getConfigurationData() async throws -> SudoEmail.ConfigurationData {
        getConfigurationDataCalled = true
        return DataFactory.EmailSDK.generateConfigurationData()
    }

    var subscribeCalledTimes = 0
    var subscribeParameters: [(id: String, notificationType: SudoEmail.SubscriptionNotificationType, subscriber: any SudoEmail.Subscriber)] = []
    var subscribeShouldConnect: Bool = true
    func subscribe(id: String, notificationType: SudoEmail.SubscriptionNotificationType, subscriber: any SudoEmail.Subscriber) async throws {
        subscribeCalledTimes += 1
        subscribeParameters.append((id: id, notificationType: notificationType, subscriber: subscriber))
        if subscribeShouldConnect == true {
            subscriber.connectionStatusChanged(state: .connected)
        }
    }

    var unsubscribeCalled: Bool = false
    var unsubscribeIdParameter: String?
    func unsubscribe(id: String) async {
        unsubscribeIdParameter = id
        unsubscribeCalled = true
    }

    var unsubscribeAllCalled: Bool = false
    func unsubscribeAll() async {
        unsubscribeAllCalled = true
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
        provisionEmailAddressParameters = (input.emailAddress, input.ownershipProofToken, input.displayName)

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
    var deleteEmailMessageResult: SudoEmail.DeleteEmailMessageSuccessResult?
    var deleteEmailMessageError = AnyError(
        "Please add base result to `SudoEmailClientSpy.deleteEmailMessage`"
    )
    func deleteEmailMessage(withId id: String) async throws -> SudoEmail.DeleteEmailMessageSuccessResult? {
        deleteEmailMessageCalled = true
        deleteEmailMessageParameter = id

        if deleteEmailMessageResult != nil {
            return deleteEmailMessageResult!
        }
        throw deleteEmailMessageError
    }

    var getSupportedEmailDomainsCalled: Bool = false
    var getSupportedEmailDomainsResult: [String]?
    var getSupportedEmailDomainsError = AnyError(
        "Please add base result to `SudoEmailClientSpy.getSupportedEmailDomains`"
    )
    func getSupportedEmailDomains() async throws -> [String] {
        getSupportedEmailDomainsCalled = true

        if getSupportedEmailDomainsResult != nil {
            return getSupportedEmailDomainsResult!
        }
        throw getSupportedEmailDomainsError
    }

    var getConfiguredEmailDomainsCalled: Bool = false
    var getConfiguredEmailDomainsResult: [String]?
    var getConfiguredEmailDomainsError = AnyError(
        "Please add base result to `SudoEmailClientSpy.getConfiguredEmailDomains`"
    )
    func getConfiguredEmailDomains() async throws -> [String] {
        getConfiguredEmailDomainsCalled = true

        if getConfiguredEmailDomainsResult != nil {
            return getConfiguredEmailDomainsResult!
        }
        throw getConfiguredEmailDomainsError
    }

    var getEmailAddressCalled: Bool = false
    var getEmailAddressIdParameter: String?
    var getEmailAddressResult: EmailAddress?
    var getEmailAddressError = AnyError(
        "Please add base result to `SudoEmailClientSpy.getEmailAddress`"
    )
    func getEmailAddress(withInput input: GetEmailAddressInput) async throws -> EmailAddress? {
        getEmailAddressCalled = true
        getEmailAddressIdParameter = input.id

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
    var getEmailMessageIdParameter: String?
    var getEmailMessageResult: EmailMessage?
    var getEmailMessageError = AnyError(
        "Please add base result to `SudoEmailClientSpy.getEmailMessage`"
    )

    @MainActor
    func getEmailMessage(withInput input: GetEmailMessageInput) async throws -> EmailMessage? {
        getEmailMessageCalled = true
        getEmailMessageCallCount += 1
        getEmailMessageIdParameter = input.id

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

    var createCustomEmailFolderCalled: Bool = false
    var createCustomEmailFolderParameter: SudoEmail.CreateCustomEmailFolderInput?
    var createCustomEmailFolderResult: SudoEmail.EmailFolder?
    var createCustomEmailFolderError = AnyError(
      "Please add base result to `SudoEmailClientSpy.createCustomEmailFolder`"
    )
    func createCustomEmailFolder(withInput input: SudoEmail.CreateCustomEmailFolderInput) async throws -> SudoEmail.EmailFolder {
        createCustomEmailFolderCalled = true
        createCustomEmailFolderParameter = input

        if let createCustomEmailFolderResult = createCustomEmailFolderResult {
          return createCustomEmailFolderResult
        }
        throw createCustomEmailFolderError
    }

    var deleteCustomEmailFolderCalled: Bool = false
    var deleteCustomEmailFolderParameter: SudoEmail.DeleteCustomEmailFolderInput?
    var deleteCustomEmailFolderResult: SudoEmail.EmailFolder?
    var deleteCustomEmailFolderError = AnyError(
      "Please add base result to `SudoEmailClientSpy.deleteCustomEmailFolder`"
    )
    func deleteCustomEmailFolder(withInput input: SudoEmail.DeleteCustomEmailFolderInput) async throws -> SudoEmail.EmailFolder? {
        deleteCustomEmailFolderCalled = true
        deleteCustomEmailFolderParameter = input

        if let deleteCustomEmailFolderResult = deleteCustomEmailFolderResult {
          return deleteCustomEmailFolderResult
        }
        throw deleteCustomEmailFolderError
    }

    var updateCustomEmailFolderCalled: Bool = false
    var updateCustomEmailFolderParameter: SudoEmail.UpdateCustomEmailFolderInput?
    var updateCustomEmailFolderResult: SudoEmail.EmailFolder?
    var updateCustomEmailFolderError = AnyError(
      "Please add base result to `SudoEmailClientSpy.updateCustomEmailFolder`"
    )
    func updateCustomEmailFolder(withInput input: SudoEmail.UpdateCustomEmailFolderInput) async throws -> SudoEmail.EmailFolder {
        updateCustomEmailFolderCalled = true
        updateCustomEmailFolderParameter = input

        if let updateCustomEmailFolderResult = updateCustomEmailFolderResult {
          return updateCustomEmailFolderResult
        }
        throw updateCustomEmailFolderError
    }

    var scheduleSendDraftMessageCalled: Bool = false
    var scheduleSendDraftMessageParameter: SudoEmail.ScheduleSendDraftMessageInput?
    var scheduleSendDraftMessageResult: SudoEmail.ScheduledDraftMessage?
    var scheduleSendDraftMessageError = AnyError(
        "Please add base result to `SudoEmailClientSpy.scheduleSendDraftMessage`"
    )
    func scheduleSendDraftMessage(withInput input: SudoEmail.ScheduleSendDraftMessageInput) async throws -> SudoEmail.ScheduledDraftMessage {
        scheduleSendDraftMessageCalled = true
        scheduleSendDraftMessageParameter = input

        if let scheduleSendDraftMessageResult = scheduleSendDraftMessageResult {
            return scheduleSendDraftMessageResult
        }
        throw scheduleSendDraftMessageError
    }
    
    var cancelScheduledDraftMessageCalled: Bool = false
    var cancelScheduledDraftMessageParameter: SudoEmail.CancelScheduledDraftMessageInput?
    var cancelScheduledDraftMessageResult: String?
    var cancelScheduledDraftMessageError = AnyError(
        "Please add base result to `SudoEmailClientSpy.cancelScheduledDraftMessage`"
    )
    func cancelScheduledDraftMessage(withInput input: SudoEmail.CancelScheduledDraftMessageInput) async throws -> String {
        cancelScheduledDraftMessageCalled = true
        cancelScheduledDraftMessageParameter = input

        if let cancelScheduledDraftMessageResult = cancelScheduledDraftMessageResult {
            return cancelScheduledDraftMessageResult
        }
        throw cancelScheduledDraftMessageError
    }
    
    var listScheduledDraftMessagesForEmailAddressIdCalled: Bool = false
    var listScheduledDraftMessagesForEmailAddressIdParameter: SudoEmail.ListScheduledDraftMessagesForEmailAddressIdInput?
    var listScheduledDraftMessagesForEmailAddressIdResult: SudoEmail.ListOutput<SudoEmail.ScheduledDraftMessage>?
    var listScheduledDraftMessagesForEmailAddressIdError = AnyError(
        "Please add base result to `SudoEmailClientSpy.listScheduledDraftMessagesForEmailAddressId`"
    ) 
    func listScheduledDraftMessagesForEmailAddressId(
        withInput input: SudoEmail.ListScheduledDraftMessagesForEmailAddressIdInput
    ) async throws -> SudoEmail.ListOutput<SudoEmail.ScheduledDraftMessage> {
        listScheduledDraftMessagesForEmailAddressIdCalled = true
        listScheduledDraftMessagesForEmailAddressIdParameter = input

        if let listScheduledDraftMessagesForEmailAddressIdResult = listScheduledDraftMessagesForEmailAddressIdResult {
            return listScheduledDraftMessagesForEmailAddressIdResult
        }
        throw listScheduledDraftMessagesForEmailAddressIdError
    }
    

    var resetCalled: Bool = false
    func reset() async throws {
        resetCalled = true
    }

    var setCacheSizeLimitCalled: Bool = false
    func setCacheSizeLimit(bytes: Int64) async throws {
        setCacheSizeLimitCalled = true
    }

    var flushMessageBodyCacheCalled: Bool = false
    func flushMessageBodyCache(input: FlushMessageBodyCacheInput) async {
        flushMessageBodyCacheCalled = true
    }

    var getEncodedEmailMessageSizeCalled: Bool = false
    var getEncodedEmailMessageSizeResult: Int = 0
    func getEncodedEmailMessageSize(withInput input: SendEmailMessageInput) async throws -> Int {
        getEncodedEmailMessageSizeCalled = true
        return getEncodedEmailMessageSizeResult
    }

    // MARK: - Email Alias Methods

    var getEmailAliasDomainsCalled: Bool = false
    var getEmailAliasDomainsResult: [String]?
    var getEmailAliasDomainsError = AnyError(
        "Please add base result to `SudoEmailClientSpy.getEmailAliasDomains`"
    )
    func getEmailAliasDomains() async throws -> [String] {
        getEmailAliasDomainsCalled = true
        if let result = getEmailAliasDomainsResult {
            return result
        }
        throw getEmailAliasDomainsError
    }

    var listEmailDomainsCalled: Bool = false
    var listEmailDomainsResult: [EmailDomain]?
    var listEmailDomainsError = AnyError(
        "Please add base result to `SudoEmailClientSpy.listEmailDomains`"
    )
    func listEmailDomains() async throws -> [EmailDomain] {
        listEmailDomainsCalled = true
        if let result = listEmailDomainsResult {
            return result
        }
        throw listEmailDomainsError
    }

    var provisionEmailAliasCalled: Bool = false
    var provisionEmailAliasParameter: ProvisionEmailAliasInput?
    var provisionEmailAliasResult: EmailAlias?
    var provisionEmailAliasError = AnyError(
        "Please add base result to `SudoEmailClientSpy.provisionEmailAlias`"
    )
    func provisionEmailAlias(withInput input: ProvisionEmailAliasInput) async throws -> EmailAlias {
        provisionEmailAliasCalled = true
        provisionEmailAliasParameter = input
        if let result = provisionEmailAliasResult {
            return result
        }
        throw provisionEmailAliasError
    }

    var deprovisionEmailAliasCalled: Bool = false
    var deprovisionEmailAliasParameter: DeprovisionEmailAliasInput?
    var deprovisionEmailAliasResult: EmailAlias?
    var deprovisionEmailAliasError = AnyError(
        "Please add base result to `SudoEmailClientSpy.deprovisionEmailAlias`"
    )
    func deprovisionEmailAlias(withInput input: DeprovisionEmailAliasInput) async throws -> EmailAlias {
        deprovisionEmailAliasCalled = true
        deprovisionEmailAliasParameter = input
        if let result = deprovisionEmailAliasResult {
            return result
        }
        throw deprovisionEmailAliasError
    }

    var updateEmailAliasCalled: Bool = false
    var updateEmailAliasParameter: UpdateEmailAliasInput?
    var updateEmailAliasResult: EmailAlias?
    var updateEmailAliasError = AnyError(
        "Please add base result to `SudoEmailClientSpy.updateEmailAlias`"
    )
    func updateEmailAlias(withInput input: UpdateEmailAliasInput) async throws -> EmailAlias {
        updateEmailAliasCalled = true
        updateEmailAliasParameter = input
        if let result = updateEmailAliasResult {
            return result
        }
        throw updateEmailAliasError
    }

    var enableEmailAliasCalled: Bool = false
    var enableEmailAliasParameter: EnableEmailAliasInput?
    var enableEmailAliasResult: EmailAlias?
    var enableEmailAliasError = AnyError(
        "Please add base result to `SudoEmailClientSpy.enableEmailAlias`"
    )
    func enableEmailAlias(withInput input: EnableEmailAliasInput) async throws -> EmailAlias {
        enableEmailAliasCalled = true
        enableEmailAliasParameter = input
        if let result = enableEmailAliasResult {
            return result
        }
        throw enableEmailAliasError
    }

    var disableEmailAliasCalled: Bool = false
    var disableEmailAliasParameter: DisableEmailAliasInput?
    var disableEmailAliasResult: EmailAlias?
    var disableEmailAliasError = AnyError(
        "Please add base result to `SudoEmailClientSpy.disableEmailAlias`"
    )
    func disableEmailAlias(withInput input: DisableEmailAliasInput) async throws -> EmailAlias {
        disableEmailAliasCalled = true
        disableEmailAliasParameter = input
        if let result = disableEmailAliasResult {
            return result
        }
        throw disableEmailAliasError
    }

    var verifyExternalEmailAddressCalled: Bool = false
    var verifyExternalEmailAddressParameter: VerifyExternalEmailAddressInput?
    var verifyExternalEmailAddressResult: VerifyExternalEmailAddressResult?
    var verifyExternalEmailAddressError = AnyError(
        "Please add base result to `SudoEmailClientSpy.verifyExternalEmailAddress`"
    )
    func verifyExternalEmailAddress(withInput input: VerifyExternalEmailAddressInput) async throws -> VerifyExternalEmailAddressResult {
        verifyExternalEmailAddressCalled = true
        verifyExternalEmailAddressParameter = input
        if let result = verifyExternalEmailAddressResult {
            return result
        }
        throw verifyExternalEmailAddressError
    }

    var listEmailAliasesForOwnerCalled: Bool = false
    var listEmailAliasesForOwnerParameter: ListEmailAliasesForOwnerInput?
    var listEmailAliasesForOwnerResult: ListOutput<EmailAlias>?
    var listEmailAliasesForOwnerError = AnyError(
        "Please add base result to `SudoEmailClientSpy.listEmailAliasesForOwner`"
    )
    func listEmailAliasesForOwner(withInput input: ListEmailAliasesForOwnerInput) async throws -> ListOutput<EmailAlias> {
        listEmailAliasesForOwnerCalled = true
        listEmailAliasesForOwnerParameter = input
        if let result = listEmailAliasesForOwnerResult {
            return result
        }
        throw listEmailAliasesForOwnerError
    }

    var sendEmailMessageViaAliasCalled: Bool = false
    var sendEmailMessageViaAliasParameter: SendEmailMessageInput?
    var sendEmailMessageViaAliasResult: SendEmailMessageResult?
    var sendEmailMessageViaAliasError = AnyError(
        "Please add base result to `SudoEmailClientSpy.sendEmailMessageViaAlias`"
    )
    func sendEmailMessageViaAlias(withInput input: SendEmailMessageInput) async throws -> SendEmailMessageResult {
        sendEmailMessageViaAliasCalled = true
        sendEmailMessageViaAliasParameter = input
        if let result = sendEmailMessageViaAliasResult {
            return result
        }
        throw sendEmailMessageViaAliasError
    }

    var setSignInDelegateCalled: Bool = false
    func setSignInDelegate(_ delegate: SudoPlatformSignInDelegate?) async {
        setSignInDelegateCalled = true
    }
}
