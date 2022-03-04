//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit

@MainActor
class SecretCodeViewController: UIViewController {
    
    @IBOutlet weak var secretCode: UILabel!

    let client = Clients.passwordManagerClient!

    override func viewDidLoad() {
        super.viewDidLoad()
        let code = self.client.getSecretCode()
        secretCode.text = code
        secretCode.adjustsFontSizeToFitWidth = true
    }
    
    @IBAction func download(_ sender: Any) {
        guard let client = Clients.passwordManagerClient else { return }
        guard let pdf = client.renderRescueKit() else { return }
        let pdfData = pdf.dataRepresentation()
        let vc = UIActivityViewController(
            activityItems: [pdfData as Any],
            applicationActivities: []
        )
        present(vc, animated: true, completion: nil)

        // Write to the documents directory on simulator because the share sheet doesn't appear to
        // make it easy to get files off it.
        #if targetEnvironment(simulator)
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let rescueKitURL = documentsDirectory.appendingPathComponent("RescueKit.pdf")
            print("Writing rescue kit to: \(rescueKitURL.absoluteString)")
            try? pdfData?.write(to: rescueKitURL)
        }
        #endif

    }
    
    @IBAction func copyToClipboard(_ sender: Any) {
        UIPasteboard.general.string = self.secretCode.text
    }
}
