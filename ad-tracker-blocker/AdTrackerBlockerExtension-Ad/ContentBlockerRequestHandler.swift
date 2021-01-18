//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import MobileCoreServices

class ContentBlockerRequestHandler: NSObject, NSExtensionRequestHandling {

    func beginRequest(with context: NSExtensionContext) {
        // Get the latest ContentBlocker rules from the app
        let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Constants.GROUP_ID)
        let url = container?.appendingPathComponent(Bundle.main.bundleIdentifier ?? "AdTrackerBlocker")
        if let fileUrl = url?.appendingPathComponent(Constants.BLOCKER_LIST_FILE) {
            if FileManager.default.fileExists(atPath: fileUrl.path) {
                let item = NSExtensionItem()
                let attachment = NSItemProvider(contentsOf: fileUrl)!
                item.attachments = [attachment]
                context.completeRequest(returningItems: [item], completionHandler: nil)
            } else {
                // replace the extension attachment with blockerlist.json which blocks nothing
                let attachment = NSItemProvider(contentsOf: Bundle.main.url(forResource: "blockerList", withExtension: "json"))!
                let item = NSExtensionItem()
                item.attachments = [attachment]
                context.completeRequest(returningItems: [item], completionHandler: nil)
            }
        }
    }

}
