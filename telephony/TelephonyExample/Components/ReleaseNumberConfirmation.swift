//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@preconcurrency import SudoTelephonyCommon
import SwiftUI

extension View {

    /// Asks the user to confirm releasing a phone number, warning that its messages will be lost.
    func releaseNumberConfirmation(isPresented: Binding<Bool>, phoneNumber: PhoneNumber?, onConfirm: @escaping () -> Void) -> some View {
        alert("Release Number?", isPresented: isPresented, presenting: phoneNumber) { _ in
            Button("Cancel", role: .cancel) {}
            Button("Release", role: .destructive, action: onConfirm)
        } message: { phoneNumber in
            Text(
                "Releasing \(PhoneNumberDisplay.number(phoneNumber.phoneNumber)) means you will lose access to the messages it has received, "
                + "and it will stop receiving new messages and calls."
            )
        }
    }
}
