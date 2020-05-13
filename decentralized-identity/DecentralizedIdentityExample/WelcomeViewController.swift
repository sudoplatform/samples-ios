//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoDecentralizedIdentity
import Firebase

class WelcomeViewController: UIViewController {
    private func initializeWallet(walletId: String, onSuccess: @escaping (String) -> Void) {
        Dependencies.sudoDecentralizedIdentityClient.setupWallet(walletId: walletId) { result in
            switch result {
            case .success:
                onSuccess(walletId)
            case .failure(let error):
                DispatchQueue.main.async {
                    self.dismiss(animated: true) {
                        self.presentErrorAlert(message: "Failed to set up wallet", error: error)
                    }
                }
            }
        }
    }

    private func retrievePrimaryDid(walletId: String, onSuccess: @escaping (Did) -> Void) {
        Dependencies.sudoDecentralizedIdentityClient.listDids(walletId: walletId) { result in
            switch result {
            case .success(let dids):
                if let primaryDid = dids.first {
                    onSuccess(primaryDid)
                } else {
                    Dependencies.sudoDecentralizedIdentityClient.createDid(walletId: walletId, label: "primary") { result in
                        switch result {
                        case .success(let createdDid):
                            onSuccess(createdDid)
                        case .failure(let error):
                            DispatchQueue.main.async {
                                self.dismiss(animated: true) {
                                    self.presentErrorAlert(message: "Failed to create primary DID", error: error)
                                }
                            }
                        }
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.dismiss(animated: true) {
                        self.presentErrorAlert(message: "Failed to retrieve DIDs", error: error)
                    }
                }
            }
        }
    }

    @IBAction func getStartedTapped() {
        self.presentActivityAlert(message: "Initializing Wallet")

        initializeWallet(walletId: "my-wallet") { walletId in
            self.retrievePrimaryDid(walletId: walletId) { primaryDid in
                DispatchQueue.main.async {
                    self.dismiss(animated: true) {
                        self.performSegue(withIdentifier: "navigateToWallet", sender: (walletId, primaryDid))
                    }
                }
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "navigateToWallet":
            let navigationController = segue.destination as! UINavigationController
            let destination = navigationController.topViewController as! WalletViewController
            let (walletId, primaryDid) = sender as! (String, Did)
            destination.walletId = walletId
            destination.primaryDid = primaryDid
        default: break
        }
    }
}
