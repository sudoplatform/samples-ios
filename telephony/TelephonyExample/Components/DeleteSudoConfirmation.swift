//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

extension View {

    /// Asks the user to confirm deleting a Sudo, warning that its telephony data will be lost.
    func deleteSudoConfirmation(isPresented: Binding<Bool>, onConfirm: @escaping () -> Void) -> some View {
        alert("Delete Sudo", isPresented: isPresented) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive, action: onConfirm)
        } message: {
            Text("Deleting this Sudo will also delete its phone numbers, along with all of their SMS messages and call records. This cannot be undone.")
        }
    }
}
