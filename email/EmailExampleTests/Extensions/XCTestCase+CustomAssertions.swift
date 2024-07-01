//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

/// Extension that contains custom assertions to use throughout unit test cases
extension XCTestCase {

    /// Will assess the currently assigned segue identifiers for the view controller and assert that the given identifier exists in the set.
    /// This should be used when you want to ensure that a `UIStoryBoard` driven view controller has expected segues assigned
    /// - Parameters:
    ///   - identifier: The raw segue identifier
    ///   - viewController: The view controller the segue should be listed in
    func XCTAssertSegueIdentifierExists(
        identifier: String,
        in viewController: UIViewController,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard let rawIdentifierArray = viewController.value(forKey: "storyboardSegueTemplates") as? [AnyObject] else {
            return XCTFail("Error: unable to resolve segue identifiers from view contoller", file: file, line: line)
        }
        let identifiers = rawIdentifierArray.compactMap { $0.value(forKey: "identifier") as? String }
        let failureMessage = "\(identifier) is not present in segue identifier set: \(identifiers)"
        XCTAssertTrue(identifiers.contains(identifier), failureMessage, file: file, line: line)
    }
}
