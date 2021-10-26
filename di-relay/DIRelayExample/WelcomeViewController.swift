//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit

class WelcomeViewController: UIViewController {

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "navigateToPostboxes":
            let navigationController = segue.destination as! UINavigationController
            let destination = navigationController.topViewController as! PostboxViewController
            let (postBoxIds) = sender as! [String]
            destination.postboxIds = postBoxIds
        default: break
        }
    }

    // MARK: - Actions

    /// When the 'Get Started' button is clicked, attempt to retrieve postboxes from cache.
    @IBAction func getStartedTapped() {
        presentActivityAlert(message: "Fetching Postboxes")

        if let postboxIds = retrievePostboxIdsFromCache() {
            DispatchQueue.main.async {
                self.dismiss(animated: true) {
                    self.performSegue(withIdentifier: "navigateToPostboxes", sender: postboxIds)
                }
            }
        }
    }

    // MARK: - Helpers

    /// Attempt to retrieve all postbox IDs stored in the cache.
    /// If unsuccessful, present an error alert on the UI.
    /// - Returns: Postbox IDs or nil.
    private func retrievePostboxIdsFromCache() -> [String]? {
        switch Result(catching: {
            try KeychainPostboxIdStorage().retrieve()
        }) {
        case .success(.some(let postboxIds)):
            return postboxIds
        case .success(.none):
            return []
        case .failure(let error):
            presentErrorAlert(message: "Failed to retrieve stored postboxes", error: error)
            return nil
        }
    }

}
