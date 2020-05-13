//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit

extension UIViewController {
    /// Presents a `UIAlertController` containing a `UIActivityIndicatorView` and the given message.
    @discardableResult func presentActivityAlert(message: String) -> UIAlertController {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)

        let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        activityIndicator.hidesWhenStopped = true
        activityIndicator.style = .medium
        activityIndicator.startAnimating()

        alert.view.addSubview(activityIndicator)

        present(alert, animated: true, completion: nil)

        return alert
    }

    /// Presents a `UIAlertController` containing the given error message along with a detailed description from the `Error` if present.
    func presentErrorAlert(message: String, error: Error? = nil) {
        let detail = error.map { ":\n\($0.localizedDescription)" } ?? ""
        let alert = UIAlertController(title: "Error", message: "\(message)\(detail)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
