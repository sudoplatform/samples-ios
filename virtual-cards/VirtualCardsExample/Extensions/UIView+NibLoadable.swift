//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit

extension UIView {

    /// Will load a new instance of the inferred view class by attempting to load it from its associated `.xib` file
    ///
    /// - Parameters:
    ///   - bundle: Optional override to set the bundle to load from. Defaults to the sdk bundle.
    ///   - nibName: Optional override to set the nib name to load. Defaults to the class name.
    /// - Returns: Inferred `UIView` subclass
    static func fromNib<T: UIView>(bundle: Bundle? = nil, nibName: String? = nil) -> T {
        /// Ensure objects can be unpacked
        let targetBundle = bundle ?? Bundle.main
        let targetName = nibName ?? String(describing: self)
        guard let objects = targetBundle.loadNibNamed(targetName, owner: nil, options: [:]) else {
            fatalError("Can't load Xib: \(targetName)")
        }
        /// Ensure xib is not empty
        guard !objects.isEmpty else {
            fatalError("No top-level objects in Xib: \(targetName)")
        }
        /// Ensure first object is desired type
        guard let result = objects.first as? T else {
            fatalError("First top-level object in Xib \(targetName) is not of type \(T.self)")
        }
        result.translatesAutoresizingMaskIntoConstraints = false
        return result
    }
}
