//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UserNotifications
import SudoNotificationExtension
import SudoVirtualCardsNotificationExtension

class VirtualCardsExampleNotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    var sudoNotifiableClient: DefaultSudoNotifiableClient!
    var sudoVirtualCardsNotifiableClient: SudoNotifiableClient!

    public override init() {
        super.init()
    }

    // For testing
    init(
        sudoVirtualCardsNotifiableClient: SudoNotifiableClient,
        bestAttemptContent: UNMutableNotificationContent? = nil,
        contentHandler: ((UNNotificationContent) -> Void)? = nil
    ) throws {
        try self.sudoNotifiableClient = DefaultSudoNotifiableClient(notifiableClients: [sudoVirtualCardsNotifiableClient])
        self.sudoVirtualCardsNotifiableClient = sudoVirtualCardsNotifiableClient
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
        
        if (self.sudoVirtualCardsNotifiableClient == nil) {
            self.sudoVirtualCardsNotifiableClient = DefaultSudoVirtualCardsNotifiableClient()
        }
        if (self.sudoNotifiableClient == nil) {
            do {
                self.sudoNotifiableClient = try DefaultSudoNotifiableClient(notifiableClients: [sudoVirtualCardsNotifiableClient])
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
        guard let decoded = sudoNotifiableClient.decodeData(data: data) as? VirtualCardsFundingSourceChangedNotification else {
            contentHandler(bestAttemptContent)
            return
        }

        bestAttemptContent.title = "Your \(decoded.fundingSourceType) funding source requires attention"
        bestAttemptContent.subtitle = ""
        bestAttemptContent.body = "Please take action regarding your funding source ending in \(decoded.last4)"

            
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
