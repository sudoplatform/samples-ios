//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit

extension UIViewController {

    /// Present a `UIAlertController` containing a `UIActivityIndicatorView` and the provided `message`.
    /// - Parameter message: message to display in the view.
    @MainActor func presentActivityAlert(message: String) async {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)

        let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        activityIndicator.hidesWhenStopped = true
        activityIndicator.style = .medium
        activityIndicator.startAnimating()

        alert.view.addSubview(activityIndicator)

        return await withCheckedContinuation { continuation in
            present(alert, animated: true) {
                continuation.resume()
            }
        }
    }

    /// Presents a `UIAlertController` containing the given error message along with a detailed description from the `Error` if present.
    /// - Parameters:
    ///   - message: message to present.
    ///   - error: error which contains a description to present.
    @MainActor func presentErrorAlert(message: String, error: Error? = nil) async {
        let alert: UIAlertController
        if error != nil  && error?.localizedDescription != nil {
            let detail = error.map { ":\n\($0.localizedDescription)" } ?? ""
            alert = UIAlertController(title: "Error", message: "\(message)\(detail)", preferredStyle: .alert)
        } else {
            alert = UIAlertController(title: "Error", message: "\(message)", preferredStyle: .alert)
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        return await withCheckedContinuation { continuation in
            self.present(alert, animated: true) {
                continuation.resume()
            }
        }
    }

    /// Present an error alert containing `message` and the `error` on the main thread.
    ///
    /// - Parameters:
    ///   - message: Message to display.
    ///   - error: Error containing a `localizedDescription` to display.
    @MainActor func presentErrorAlertOnMain(_ message: String, error: Error?) async {
        if presentedViewController != nil {
            await withCheckedContinuation { continuation in
                dismiss(animated: true) {
                    continuation.resume()
                }
            }
            await presentErrorAlert(message: message, error: error)
        } else {
            await presentErrorAlert(message: message, error: error)
        }
    }

    /// Present an activity alert containing `message` on the main thread.
    ///
    /// - Parameters:
    ///   - message: Message to display.
    @MainActor func presentActivityAlertOnMain(_ message: String) async {
        if presentedViewController != nil {
            await withCheckedContinuation { continuation in
                dismiss(animated: true) {
                    continuation.resume()
                }
            }
            await presentActivityAlert(message: message)
        } else {
            await presentActivityAlert(message: message)
        }
    }

    /// Dismisses an activity alert spawned using `presentActivityAlert(message:)`.
    ///
    /// - Parameter completion: The block to execute after the view controller is dismissed. This block has no return value and takes no parameters. You may
    ///     specify nil for this parameter.
    @MainActor func dismissActivityAlert() async {
        if self.presentedViewController as? UIAlertController == nil {
            print("No activity indicator found")
            return
        }
        return await withCheckedContinuation { continuation in
            self.dismiss(animated: false) {
                continuation.resume()
            }
        }
    }
}
