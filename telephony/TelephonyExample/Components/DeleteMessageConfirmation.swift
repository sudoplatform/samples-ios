//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

extension View {

    /// Asks the user to confirm deleting a message.
    func deleteMessageConfirmation(isPresented: Binding<Bool>, onConfirm: @escaping () -> Void) -> some View {
        alert("Delete Message?", isPresented: isPresented) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive, action: onConfirm)
        } message: {
            Text("This message will be deleted. This can't be undone.")
        }
    }
}
