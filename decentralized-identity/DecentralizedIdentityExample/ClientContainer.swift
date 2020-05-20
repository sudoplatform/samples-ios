//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// this would not be in the Protocols folder

import Foundation

protocol DIDCommFeature {
    static func register(to container: inout FeaturesContainer)
}

struct FeaturesContainer {
    typealias MessageDecoder = (JSONDecoder, _ data: Data) throws -> DIDCommMessage

    var typeToMessageInit: [String: MessageDecoder] = [:]

    mutating func register<T: DIDCommMessage>(message _: T.Type) {
        T.messageTypes.forEach { typeName in
            typeToMessageInit[typeName] = { decoder, data in
                return try decoder.decode(T.self, from: data)
            }
        }
    }

    func finalize() -> [String: MessageDecoder] {
        return typeToMessageInit
    }
}

struct ClientContainer {
    let typeToMessageInit: [String: FeaturesContainer.MessageDecoder]

    init() {
        var container = FeaturesContainer()

        BasicMessageFeature.register(to: &container)
        DIDExchangeFeature.register(to: &container)

        self.typeToMessageInit = container.finalize()
    }

    enum ParseDIDCommJSONError: Error {
        case notADIDCommMessage
        case unknownMessageType(DIDCommMessageBase)
        case failedToParseMessage(Error)
    }

    let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .customISO8601
        return decoder
    }()

    func parseDIDCommJSON(data: Data) -> Result<DIDCommMessage, ParseDIDCommJSONError> {
        let base: DIDCommMessageBase
        do {
            base = try jsonDecoder.decode(DIDCommMessageBase.self, from: data)
        } catch {
            return .failure(.notADIDCommMessage)
        }

        guard let messageInit = typeToMessageInit[base.type] else {
            return .failure(.unknownMessageType(base))
        }

        do {
            return .success(try messageInit(jsonDecoder, data))
        } catch let error {
            return .failure(.failedToParseMessage(error))
        }
    }
}

let AgentMessageDateFormatters: [ISO8601DateFormatter] = [
    {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withSpaceBetweenDateAndTime, .withFractionalSeconds]
        return formatter
    }(),
    {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withSpaceBetweenDateAndTime]
        return formatter
    }(),
    {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }(),
    {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }(),
]

extension JSONDecoder.DateDecodingStrategy {
    /// Attempts to parse dates in several ISO 8601 variations supported by RFC 3339.
    static var customISO8601: Self {
        return .custom({ (decoder) throws -> Date in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)

            for formatter in AgentMessageDateFormatters {
                if let date = formatter.date(from: string) {
                    return date
                }
            }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Date not in supported ISO8601 format \(string)")
        })
    }
}
