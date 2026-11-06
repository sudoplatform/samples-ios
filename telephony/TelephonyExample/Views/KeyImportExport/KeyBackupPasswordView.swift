//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

/// Asks for the password protecting a key backup: a new one, entered twice, when exporting, or the existing one when importing.
struct KeyBackupPasswordView: View {

    // MARK: - Supplementary

    enum Mode {
        case export
        /// Importing a backup, described for the user, e.g. "Exported from iOS on 30 Oct 2026".
        case importBackup(description: String)
    }

    static let minimumPasswordLength = 8

    // MARK: - Properties

    let mode: Mode
    let isWorking: Bool

    /// Why the last attempt failed, e.g. a wrong password.
    let errorMessage: String?

    let onSubmit: (String) -> Void
    let onCancel: () -> Void

    @State private var password = ""
    @State private var confirmation = ""

    // MARK: - Properties: Computed

    private var isExport: Bool {
        if case .export = mode { return true }
        return false
    }

    private var isPasswordValid: Bool {
        if isExport {
            return password.count >= Self.minimumPasswordLength && password == confirmation
        }
        return !password.isEmpty
    }

    private var exportHint: String? {
        guard isExport else { return nil }
        if !password.isEmpty && password.count < Self.minimumPasswordLength {
            return "Use at least \(Self.minimumPasswordLength) characters."
        }
        if !confirmation.isEmpty && password != confirmation {
            return "The passwords don't match."
        }
        return nil
    }

    // MARK: - View

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Password", text: $password)
                        .textContentType(isExport ? .newPassword : .password)
                    if isExport {
                        SecureField("Confirm Password", text: $confirmation)
                            .textContentType(.newPassword)
                    }
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        switch mode {
                        case .export:
                            Text("You'll need this password to import the backup on another device. It can't be recovered if you forget it.")
                        case .importBackup(let description):
                            Text("Enter the password used when this backup was exported. \(description).")
                        }
                        if let message = exportHint ?? errorMessage {
                            Text(message)
                                .foregroundStyle(.red)
                        }
                    }
                }
                .disabled(isWorking)
            }
            .navigationTitle(isExport ? "Export Keys" : "Import Keys")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                        .disabled(isWorking)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isWorking {
                        ProgressView()
                    } else {
                        Button(isExport ? "Export" : "Import") {
                            onSubmit(password)
                        }
                        .disabled(!isPasswordValid)
                    }
                }
            }
        }
        .interactiveDismissDisabled(isWorking)
    }
}
