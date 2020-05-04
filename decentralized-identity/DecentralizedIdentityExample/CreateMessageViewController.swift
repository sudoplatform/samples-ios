//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoDecentralizedIdentity

class CreateMessageViewController: UIViewController, UITextViewDelegate {
    // MARK: Data

    var walletId: String!
    var pairwiseConnection: Pairwise!

    // MARK: Send Message

    override func viewDidLoad() {
        super.viewDidLoad()

        sendButton.isEnabled = false

        // make UITextView look like UITextField
        bodyTextView.layer.cornerRadius = 5
        bodyTextView.layer.borderWidth = 1
        bodyTextView.layer.borderColor = UIColor(named: "borderGray")?.cgColor
    }

    @IBAction func sendTapped(_ sender: UIBarButtonItem) {
        // Retrieve service URL from pairwise metadata
        guard let messageEndpointString = pairwiseConnection.metadataForKey(.serviceEndpoint),
            let messageEndpoint = URLComponents(string: messageEndpointString) else {
                DispatchQueue.main.async {
                    self.presentErrorAlert(message: "Failed to retrieve message endpoint")
                }
                return
        }
        assert(messageEndpoint.scheme == "samplefirebase")

        Dependencies.sudoDecentralizedIdentityClient.encryptPairwiseMessage(
            walletId: walletId,
            theirDid: pairwiseConnection.theirDid,
            message: bodyTextView.text ?? ""
        ) { result in
            switch result {
            case .success(let cipherText):
                // cipherText already represents textual data
                guard let cipherTextString = String(data: cipherText, encoding: .utf8) else {
                    DispatchQueue.main.async {
                        self.presentErrorAlert(message: "Failed to decode body ciphertext data")
                    }
                    return
                }

                FirebaseMessageTransport().sendMessage(pairwiseDid: messageEndpoint.path, body: cipherTextString)

                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "returnToConnection", sender: self)
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.presentErrorAlert(message: "Failed to encrypt message", error: error)
                }
            }
        }
    }

    @objc func textViewDidChange(_ textView: UITextView) {
        sendButton.isEnabled = !(bodyTextView.text?.isEmpty ?? true)
    }

    @IBOutlet weak var bodyTextView: UITextView!
    @IBOutlet weak var sendButton: UIBarButtonItem!
}
