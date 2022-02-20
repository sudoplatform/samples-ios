//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit

extension UIViewController {

    // MARK: - Supplementary

    typealias UIAlertPresentationCompletion = () -> Void

    /// Typealias for Alert Action OK Handler buttons.
    typealias UIAlertActionHandler = (UIAlertAction) -> Void

    // MARK: - Properties: Computed

    /// Accessibility Identifier assigned to activity alerts presented and dismissed via `presentActivityAlert(message:)` and `dismissActivityAlert(_:)`,
    /// respectively.
    private var activityIdentifier: String {
        return "activity-spinner"
    }

    /// Presents a `UIAlertController` containing a `UIActivityIndicatorView` and the given message.
    @MainActor func presentActivityAlert(message: String, completion: UIAlertPresentationCompletion? = nil) async {
        let alert = ActivityAlertViewController(message: message)
        alert.view.accessibilityIdentifier = self.activityIdentifier
        self.present(alert, animated: false, completion: completion)
    }

    @MainActor func presentCancellableActivityAlert(
        message: String,
        delegate: ActivityAlertViewControllerDelegate,
        completion: UIAlertPresentationCompletion? = nil
    ) {
        let alert = ActivityAlertViewController(message: message, cancellable: true, delegate: delegate)
        alert.view.accessibilityIdentifier = self.activityIdentifier
        self.present(alert, animated: false, completion: completion)
    }

    /// Dismisses an activity alert spawned using `presentActivityAlert(message:)`.
    ///
    /// - Parameter completion: The block to execute after the view controller is dismissed. This block has no return value and takes no parameters. You may
    ///     specify nil for this parameter.
    @MainActor func dismissActivityAlert(_ completion: (() -> Void)? = nil) async {
        guard
            let presentedAlert = self.presentedViewController as? ActivityAlertViewController,
            presentedAlert.view.accessibilityIdentifier == self.activityIdentifier
        else {
            print("No activity indicator found")
            return
        }
        self.dismiss(animated: false, completion: completion)
    }

    /// Presents a `UIAlertController` presenting with the `title` and `message`.
    @MainActor func presentAlert(title: String, message: String, confirm: UIAlertActionHandler? = nil) async {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: confirm)
        alert.addAction(okAction)
        self.present(alert, animated: true)
    }

    /// Presents a `UIAlertController` containing the given error message along with a detailed description from the `Error`.
    @MainActor func presentErrorAlert(message: String, error: Error? = nil, okHandler: UIAlertActionHandler? = nil) async {
        var message = message
        if let error = error {
            message = "\(message):\n\(error.localizedDescription)"
        }
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: okHandler))
        self.present(alert, animated: true)
    }
}
