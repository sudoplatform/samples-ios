//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoAdTrackerBlocker
import SafariServices

class ContentBlockerHelper {
    static func toggleContentBlockerFor(ruleset: Ruleset, enable: Bool) {
        if enable {
            // Add the ruleset data do the Content Blocker extension by storing it in group container
            addRulesetToSharedGroup(ruleset: ruleset)
        } else {
            // Remove the ruleset data from the group container
            let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Constants.GROUP_ID)
            let url = container?.appendingPathComponent(ruleset.type.extensionBundleId)
            if FileManager.default.fileExists(atPath: url?.path ?? "") {
                do {
                    try FileManager.default.removeItem(atPath: url?.path ?? "")
                    // notify the extension
                    SFContentBlockerManager.reloadContentBlocker(withIdentifier: ruleset.type.extensionBundleId) { (error) in
                        if let error = error {
                            print("Failed to reload Content Blocker: \(error)")
                        }
                    }
                } catch {
                    print("Failed to remove blockerlist file: \(error)")
                }
            }
        }
        // Save the enabled state in user defaults
        UserDefaults.standard.setValue(enable, forKey: ruleset.type.rawValue)
    }

    private static func addRulesetToSharedGroup(ruleset: Ruleset) {
        Clients.adTrackerBlockerClient.getContentBlocker(ruleset: ruleset) { (result) in
            switch result {
            case .success(let contentBlocker):
                // write the rules to a json file in the shared container
                let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Constants.GROUP_ID)
                let url = container?.appendingPathComponent(ruleset.type.extensionBundleId)
                if FileManager.default.fileExists(atPath: url?.path ?? "") {
                    writeJsonToFile(json: contentBlocker.rulesetData, url: url)
                } else {
                    do {
                        try FileManager.default.createDirectory(at: url!, withIntermediateDirectories: false, attributes: nil)
                        writeJsonToFile(json: contentBlocker.rulesetData, url: url)
                    } catch {
                        print("Failed to create directory: \(error)")
                    }
                }

                // notify the extension
                SFContentBlockerManager.reloadContentBlocker(withIdentifier: ruleset.type.extensionBundleId) { (error) in
                    if let error = error {
                        print("Failed to reload Content Blocker: \(error)")
                    }
                }
            case .failure(let error):
                print("Failed to get Content Blocker: \(error)")
            }
        }
    }

    // Writes a "blockerList.json" file with the given JSON string to the provided URL
    static func writeJsonToFile(json: String?, url: URL?) {
        if let json = json, let url = url {
            do {
                try json.write(to: url.appendingPathComponent(Constants.BLOCKER_LIST_FILE), atomically: true, encoding: .utf8)
            } catch {
                print("Failed to write ruleset data to file: \(error)")
            }
        }
    }
}

extension RulesetType {
    var extensionBundleId: String {
        switch self {
        case .adBlocking:
            return "com.sudoplatform.adtrackerblockerexample.AdTrackerBlockerExtensionAd"
        case .privacy:
            return "com.sudoplatform.adtrackerblockerexample.AdTrackerBlockerExtensionPrivacy"
        case .social:
            return "com.sudoplatform.adtrackerblockerexample.AdTrackerBlockerExtensionSocial"
        default:
            return ""
        }
    }
}
