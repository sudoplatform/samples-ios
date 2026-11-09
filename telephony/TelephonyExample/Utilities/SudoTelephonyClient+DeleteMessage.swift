//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@preconcurrency import SudoTelephony
@preconcurrency import SudoTelephonyCommon

enum DeletePhoneMessageError: LocalizedError {
    case notDeleted

    // MARK: - LocalizedError

    var errorDescription: String? {
        "The message couldn't be deleted. It may already have been deleted."
    }
}

extension SudoTelephonyClient {

    /// Deletes a single message. The SDK deletes in batches and reports messages it couldn't delete in `failedIds` rather than
    /// throwing, so this throws if the message wasn't deleted.
    func deletePhoneMessage(id: String) async throws {
        let result = try await deletePhoneMessages(withInput: DeletePhoneMessagesInput(ids: [id]))
        guard result.succeededIds.contains(id) else {
            throw DeletePhoneMessageError.notDeleted
        }
    }
}
