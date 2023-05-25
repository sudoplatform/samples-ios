//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

private final class BundleLocator {}

extension Bundle {

    /// To support consumers who need to consume the UI library via cocoapods as a static library we
    /// need to ensure that the bundle is loaded from the main bundle if possible.
    internal static var sdkBundle: Bundle {
        let bundleForClass = Bundle(for: BundleLocator.self)
        guard
            let path = bundleForClass.path(forResource: "SudoDIRelay", ofType: "bundle"),
            let resolvedBundle = Bundle(path: path)
        else {
            return bundleForClass
        }
        return resolvedBundle
    }
}
