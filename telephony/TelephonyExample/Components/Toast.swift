//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

extension View {

    /// Shows `message` briefly at the bottom of the screen, e.g. to confirm something was copied, then clears it.
    func toast(_ message: Binding<String?>) -> some View {
        modifier(ToastModifier(message: message))
    }
}

private struct ToastModifier: ViewModifier {

    // MARK: - Properties

    @Binding var message: String?

    // MARK: - ViewModifier

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let message {
                    Text(message)
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .foregroundStyle(Color(uiColor: .systemBackground))
                        .background(Capsule().fill(Color(uiColor: .label).opacity(0.85)).shadow(radius: 6, y: 2))
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .accessibilityAddTraits(.isStaticText)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: message)
            .task(id: message) {
                guard message != nil else { return }
                try? await Task.sleep(for: .seconds(2))
                message = nil
            }
    }
}
