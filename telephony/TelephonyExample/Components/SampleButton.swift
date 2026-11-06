//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

/// A capsule button with a consistent appearance for the sample app, showing a spinner while loading.
struct SampleButton: View {

    // MARK: - Properties

    let label: String
    var isLoading: Bool = false
    var minWidth: CGFloat = 100
    let action: () -> Void

    // MARK: - View

    var body: some View {
        Button(action: action) {
            if isLoading {
                ProgressView().tint(.white)
            } else {
                Text(label).bold()
            }
        }
        .padding()
        .frame(minWidth: minWidth, minHeight: 40, maxHeight: 40)
        .background(isLoading ? Color.secondary : Color.accentColor)
        .foregroundStyle(.white)
        .disabled(isLoading)
        .clipShape(.capsule)
        .buttonStyle(.borderless)
    }
}

#Preview {
    VStack {
        SampleButton(label: "Start") {}
        SampleButton(label: "Start", isLoading: true) {}
    }
}
