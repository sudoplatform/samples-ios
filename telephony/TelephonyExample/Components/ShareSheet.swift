//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI
import UIKit

/// The system share sheet, for sharing a file through AirDrop, Files, Mail and so on.
struct ShareSheet: UIViewControllerRepresentable {

    // MARK: - Properties

    let url: URL

    /// Called once the user has shared the file or closed the sheet.
    let onComplete: () -> Void

    // MARK: - Conformance: UIViewControllerRepresentable

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in
            onComplete()
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
