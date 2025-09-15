//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit

extension UIStoryboard {

    /// Will attempt to resolve a view controller of the inferred type for the given identifier.
    /// - Parameter identifier: The identifier to instantiate.
    /// - Returns: `T` instance or fatal errors
    func resolveViewController<T: UIViewController>(identifier: String) -> T {
        guard let viewController = instantiateViewController(identifier: identifier) as? T else {
            fatalError("Error: Unable to resolve view controller of type `\(T.self)` for identifier: \(identifier)")
        }
        return viewController
    }

    /// Will attempt to resolve a navigation controller for the given identifier.
    /// - Parameter identifier: The identifier to instantiate.
    /// - Returns: `UINavigationController` instance or fatal errors
    func resolveNavigationController(identifier: String) -> UINavigationController {
        guard let result = instantiateViewController(identifier: identifier) as? UINavigationController else {
            fatalError("Error: Unable to resolve navigation controller for identifier: \(identifier)")
        }
        return result
    }
}
