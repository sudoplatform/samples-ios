//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

enum DeregisterAlert: String {
    case deregisterButton = "Deregister"
    case cancelButton = "Cancel"
    
    var element: XCUIElement {
        switch self {
        case .deregisterButton:
            return XCUIApplication().alerts["Deregister"].scrollViews.otherElements.buttons["Deregister"]
        case .cancelButton:
            return XCUIApplication().alerts["Deregister"].scrollViews.otherElements.buttons["Cancel"]
        }
    }
}
