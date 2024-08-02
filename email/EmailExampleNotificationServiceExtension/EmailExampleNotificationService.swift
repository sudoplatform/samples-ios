//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UserNotifications
import SudoNotificationExtension
import SudoEmailNotificationExtension

class EmailExampleNotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    var sudoNotifiableClient: DefaultSudoNotifiableClient!
    var sudoEmailNotifiableClient: SudoNotifiableClient!

    public override init() {
        super.init()
    }

    // For testing
    init(
        sudoEmailNotifiableClient: SudoNotifiableClient,
        bestAttemptContent: UNMutableNotificationContent? = nil,
        contentHandler: ((UNNotificationContent) -> Void)? = nil
    ) throws {
        try self.sudoNotifiableClient = DefaultSudoNotifiableClient(notifiableClients: [sudoEmailNotifiableClient])
        self.sudoEmailNotifiableClient = sudoEmailNotifiableClient
        self.bestAttemptContent = bestAttemptContent
        self.contentHandler = contentHandler
    }

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        guard let bestAttemptContent = bestAttemptContent else {
            contentHandler(request.content)
            return
        }
        
        if (self.sudoEmailNotifiableClient == nil) {
            self.sudoEmailNotifiableClient = DefaultSudoEmailNotifiableClient(keyNamespace: "eml")
        }
        if (self.sudoNotifiableClient == nil) {
            do {
                self.sudoNotifiableClient = try DefaultSudoNotifiableClient(notifiableClients: [sudoEmailNotifiableClient])
            }
            catch {
                contentHandler(bestAttemptContent)
                return
            }
        }

        guard let data = sudoNotifiableClient.extractData(fromNotificationContent: bestAttemptContent) else {
            contentHandler(bestAttemptContent)
            return
        }

        guard let decoded = sudoNotifiableClient.decodeData(data: data) as? EmailMessageReceivedNotification else {
            contentHandler(bestAttemptContent)
            return
        }

        bestAttemptContent.title = decoded.from.displayName == nil ? decoded.from.address : decoded.from.displayName!
        if (decoded.subject != nil) {
            bestAttemptContent.subtitle = decoded.subject!
        }
        else {
            bestAttemptContent.subtitle = ""
        }
        bestAttemptContent.body = ""
            
        contentHandler(bestAttemptContent)
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}
