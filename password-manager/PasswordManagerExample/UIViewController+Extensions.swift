//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit

extension UIViewController {
    /// Presents a `UIAlertController` containing a `UIActivityIndicatorView` and the given message.
    func presentActivityAlert(message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)

            let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
            activityIndicator.hidesWhenStopped = true
            activityIndicator.style = .medium
            activityIndicator.startAnimating()

            alert.view.addSubview(activityIndicator)

            self.present(alert, animated: true, completion: nil)
        }
    }

    /// Presents a `UIAlertController` containing the given error message along with a detailed description from the `Error`.
    func presentErrorAlert(message: String, error: Error) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Error", message: "\(message):\n\(error.localizedDescription)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }

    /// Presents a `UIAlertController` containing the given error message
    func presentErrorAlert(message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}
