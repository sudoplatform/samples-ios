//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// A "just good enough" function to format phone numbers used in the app without adding a third party dependency.
func formatAsUSNumber(number: String) -> String {

    var phoneNumber = number

    if !phoneNumber.contains("+") {
        phoneNumber = "+1" + phoneNumber
    }

    var s: String = ""

    for (pos, char) in phoneNumber.enumerated() {
        if pos == 2 {
            s.append(" (")
        }
        if pos == 5 {
            s.append(") ")
        }
        if pos == 8 {
            s.append(" ")
        }

        s.append(char)
    }
    return s
}
