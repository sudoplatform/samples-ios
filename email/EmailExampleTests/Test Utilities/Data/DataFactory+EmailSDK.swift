//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoEmail

extension DataFactory {

    enum EmailSDK {

        static func randomEmailAddress() -> String {
            return  "\(UUID().uuidString)@\(UUID().uuidString)"
        }

        static func randomDate() -> Date {
            return Date(timeIntervalSince1970: Double.random(in: Range(uncheckedBounds: (1, 1000))))
        }

        static func generateEmailMessage(
            id: String = UUID().uuidString,
            owner: String = UUID().uuidString,
            owners: [Owner] = [Owner(id: "dummyOwnerId", issuer: "dummyIssuerId")],
            emailAddressId: String = UUID().uuidString,
            folderId: String = "dummyFolderId",
            previousFolderId: String? = nil,
            createdAt: Date = randomDate(),
            updatedAt: Date = randomDate(),
            direction: EmailMessage.Direction = .inbound,
            version: Int = 1,
            size: Double = 2,
            fromAddresses: [EmailAddressAndName] = [EmailAddressAndName(address: "from@example.com", displayName: "from")],
            toAddresses: [EmailAddressAndName] =  [EmailAddressAndName(address: "to@example.com", displayName: "to")],
            ccAddresses: [EmailAddressAndName] = [EmailAddressAndName(address: "cc@example.com", displayName: "cc")],
            bccAddresses: [EmailAddressAndName] = [EmailAddressAndName(address: "bcc@example.com", displayName: "bcc")],
            subject: String? = "Test Subject",
            hasAttachments: Bool = false,
            encryptionStatus: EncryptionStatus = EncryptionStatus.UNENCRYPTED
        ) -> EmailMessage {
            return EmailMessage(
                id: id,
                clientRefId: nil,
                owner: owner,
                owners: owners,
                emailAddressId: emailAddressId,
                folderId: folderId,
                previousFolderId: previousFolderId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                sortDate: createdAt,
                seen: false,
                direction: direction,
                state: .received,
                version: version,
                size: size,
                from: fromAddresses,
                replyTo: [],
                to: toAddresses,
                cc: ccAddresses,
                bcc: bccAddresses,
                subject: subject,
                hasAttachments: hasAttachments,
                encryptionStatus: encryptionStatus,
                date: createdAt
            )
        }

        static func generateDraftEmailMessage(
            id: String = UUID().uuidString,
            emailAddressId: String = UUID().uuidString,
            updatedAt: Date = randomDate(),
            rfc822Data: Data = Data("rfc822data".utf8)
        ) -> DraftEmailMessage {
            return DraftEmailMessage(
                id: id,
                emailAddressId: emailAddressId,
                updatedAt: updatedAt,
                rfc822Data: rfc822Data
            )
        }

        static func generateDraftEmailMessageMetadata(
            id: String = UUID().uuidString,
            emailAddressId: String = UUID().uuidString,
            updatedAt: Date = randomDate()
        ) -> DraftEmailMessageMetadata {
            return DraftEmailMessageMetadata(
                id: id,
                emailAddressId: emailAddressId,
                updatedAt: updatedAt
            )
        }

        static func generateEmailAddress(
            id: String = UUID().uuidString,
            owner: String = UUID().uuidString,
            owners: [Owner] = [Owner(id: "dummyOwnerId", issuer: "dummyIssuerId")],
            identityId: String = UUID().uuidString,
            keyRingId: String = UUID().uuidString,
            keyIds: [String] = [UUID().uuidString],
            address: String = randomEmailAddress(),
            folders: [EmailFolder] = [],
            size: Double = 2,
            version: Int = 1,
            createdAt: Date = randomDate(),
            updatedAt: Date = randomDate(),
            lastReceivedAt: Date? = nil,
            alias: String = "dummyAlias",
            numberOfMessages: Int = 1
        ) -> EmailAddress {
            return EmailAddress(
                id: id,
                owner: owner,
                owners: owners,
                identityId: identityId,
                keyRingId: keyRingId,
                keyIds: keyIds,
                emailAddress: address,
                folders: folders,
                size: size,
                numberOfEmailMessages: numberOfMessages,
                version: version,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastReceivedAt: lastReceivedAt,
                alias: alias
            )
        }

        static func generateEmailFolder(
            id: String = UUID().uuidString,
            owner: String = UUID().uuidString,
            owners: [Owner] = [Owner(id: "dummyOwnerId", issuer: "dummyIssuerId")],
            emailAddressId: String = UUID().uuidString,
            folderName: String = "dummyFolderName",
            size: Double = 2,
            unseenCount: Int = 1,
            ttl: Double? = nil,
            version: Int = 1,
            createdAt: Date = randomDate(),
            updatedAt: Date = randomDate()
        ) -> EmailFolder {
            return EmailFolder(
                id: id,
                owner: owner,
                owners: owners,
                emailAddressId: emailAddressId,
                folderName: folderName,
                size: size,
                unseenCount: unseenCount,
                ttl: ttl,
                version: version,
                createdAt: createdAt,
                updatedAt: updatedAt
            )
        }

        static func generateConfigurationData(
            deleteEmailMessagesLimit: Int = 1,
            updateEmailMessagesLimit: Int = 2,
            emailMessageMaxInboundMessageSize: Int = 3,
            emailMessageMaxOutboundMessageSize: Int = 4,
            emailMessageRecipientsLimit: Int = 2,
            encryptedEmailMessageRecipientsLimit: Int = 2
        ) -> ConfigurationData {
            return ConfigurationData(
                deleteEmailMessagesLimit: deleteEmailMessagesLimit,
                updateEmailMessagesLimit: updateEmailMessagesLimit,
                emailMessageMaxInboundMessageSize: emailMessageMaxInboundMessageSize,
                emailMessageMaxOutboundMessageSize: emailMessageMaxOutboundMessageSize,
                emailMessageRecipientsLimit: emailMessageRecipientsLimit,
                encryptedEmailMessageRecipientsLimit: encryptedEmailMessageRecipientsLimit
            )
        }

        static func generatePartialEmailMessageEntity(
            id: String = UUID().uuidString,
            clientRefId: String = UUID().uuidString,
            owner: String = UUID().uuidString,
            owners: [Owner] = [Owner(id: "dummyOwnerId", issuer: "dummyIssuerId")],
            emailAddressId: String = UUID().uuidString,
            folderId: String = "dummyFolderId",
            previousFolderId: String? = nil,
            seen: Bool = false,
            createdAt: Date = randomDate(),
            updatedAt: Date = randomDate(),
            sortDate: Date = randomDate(),
            direction: EmailMessage.Direction = .inbound,
            state: EmailMessage.State = .received,
            version: Int = 1,
            size: Double = 2,
            encryptionStatus: EncryptionStatus = EncryptionStatus.UNENCRYPTED
        ) -> PartialEmailMessage {
            return PartialEmailMessage(
                id: id,
                clientRefId: clientRefId,
                owner: owner,
                owners: owners,
                emailAddressId: emailAddressId,
                folderId: folderId,
                previousFolderId: previousFolderId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                sortDate: sortDate,
                seen: seen,
                direction: direction,
                state: state,
                version: version,
                size: size,
                encryptionStatus: encryptionStatus,
                date: createdAt
            )
        }

        static func generateEmailMessageWithBody(
            id: String = "dummyEmailMessageId",
            body: String = "dummyBody",
            attachments: [EmailAttachment] = [],
            inlineAttachments: [EmailAttachment] = []
        ) -> EmailMessageWithBody {
            return EmailMessageWithBody(
                id: id,
                body: body,
                attachments: attachments,
                inlineAttachments: inlineAttachments
            )
        }

        static func generateEmailAttachment() -> EmailAttachment {
            return EmailAttachment(
                filename: "dummyAttachment.png",
                contentId: "dummyContentId",
                mimetype: "dummyMimeType",
                inlineAttachment: false,
                data: "dummyAttachmentData"
            )
        }
    }
}
