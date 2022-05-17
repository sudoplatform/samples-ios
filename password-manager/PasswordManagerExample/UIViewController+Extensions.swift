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

public extension UIColor {
    /// Will initialize a new color instance with the given hex string.
    /// - Parameter hexString: The raw hex string
    convenience init(hexString: String) {
        var hexString: String = hexString.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        if hexString.hasPrefix("#") {
            hexString = String(hexString.dropFirst())
        }
        var rgbValue: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgbValue)

        let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgbValue & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: 1)
    }

    /// Will return the RGB components of the color
    var rgb: (r: Int, g: Int, b: Int) {
        var red: CGFloat = 0
        var blue: CGFloat = 0
        var green: CGFloat = 0
        var alpha: CGFloat = 0

        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (r: (Int)(red * 255), g: (Int)(green * 255), b: (Int)(blue * 255))
    }

    /// Will convert the current color instance to a hex string
    /// - Returns: `String`
    var hexString: String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        getRed(&r, green: &g, blue: &b, alpha: &a)

        let rgb: Int = (Int)(r * 255) << 16 | (Int)(g * 255) << 8 | (Int)(b * 255) << 0

        return String(format: "#%06x", rgb)
    }
}
