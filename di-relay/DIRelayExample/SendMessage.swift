//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

class SendMessage {

    static func writeMessage(serviceEndpoint: String, messageContents: Data) async throws {
        let url = URL(string: serviceEndpoint)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let session = URLSession.shared

        (_, _) = try await session.upload(for: request, from: messageContents)

    }
}
