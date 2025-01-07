//
// Copyright © 2025 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Folder data that can be pre-populated when updating.
struct UpdateCustomFolderInputData {
    /// The current name of the folder
    let customFolderName: String?

    init(customFolderName: String? = nil) {
        self.customFolderName = customFolderName
    }
}
