//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit

extension UIViewController {

    // MARK: - Supplementary

    /// Typealias for Alert Action OK Handler buttons.
    typealias UIAlertActionHandler = (UIAlertAction) -> Void

    // MARK: - Properties: Computed

    /// Accessibility Identifier assigned to activity alerts presented and dismissed via `presentActivityAlert(message:)` and `dismissActivityAlert(_:)`,
    /// respectively.
    private var activityIdentifier: String {
        return "activity-spinner"
    }

    /// Presents a `UIAlertController` containing a `UIActivityIndicatorView` and the given message.
    func presentActivityAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.view.accessibilityIdentifier = activityIdentifier
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.frame = CGRect(x: -5, y: 5, width: 50, height: 50)
        activityIndicator.startAnimating()
        alert.view.addSubview(activityIndicator)
        present(alert, animated: true)
    }

    /// Dismisses an activity alert spawned using `presentActivityAlert(message:)`.
    ///
    /// - Parameter completion: The block to execute after the view controller is dismissed. This block has no return value and takes no parameters. You may
    ///     specify nil for this parameter.
    func dismissActivityAlert(_ completion: (() -> Void)? = nil) {
        guard
            let presentedAlert = presentedViewController as? UIAlertController,
            presentedAlert.view.accessibilityIdentifier == activityIdentifier
        else {
            print("No activity indicator found")
            return
        }
        dismiss(animated: true, completion: completion)
    }

    /// Presents a `UIAlertController` presenting with the `title` and `message`.
    func presentAlert(title: String, message: String, confirm: UIAlertActionHandler? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: confirm)
        alert.addAction(okAction)
        present(alert, animated: true)
    }

    /// Presents a `UIAlertController` containing the given error message along with a detailed description from the `Error`.
    func presentErrorAlert(message: String, error: Error? = nil, okHandler: UIAlertActionHandler? = nil) {
        var message = message
        if let error = error {
            message = "\(message):\n\(error.localizedDescription)"
        }
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: okHandler))
        self.present(alert, animated: true)
    }
}
