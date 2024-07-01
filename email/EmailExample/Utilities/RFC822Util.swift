//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import MimeParser
import SudoEmail

enum RFC822Error: Error, LocalizedError, Equatable {
    case mimeParserError
    case contentDecoderError(_ cause: String?)

    var errorDescription: String? {
        switch self {
        case .mimeParserError:
            return "Mime Parser Error: Invalid message structure"
        case let .contentDecoderError(cause):
            var description = "Content could not be decoded"
            if let cause = cause {
                description += ": \(cause)"
            }
            return description
        }
    }
}

struct BasicRFC822Message {
    public var from: String
    public var to: [String]
    public var cc: [String] = []
    public var bcc: [String] = []
    public var subject: String
    public var body: String
    public var attachments: [EmailAttachment]?
}

class RFC822Util {

    static func fromPlainText(_ data: Data) throws -> BasicRFC822Message {
        let parser = MimeParser()
        let stringData = String(decoding: data, as: UTF8.self)
        guard let mime = try? parser.parse(stringData) else {
            throw RFC822Error.mimeParserError
        }
        /// Handle Headers.
        var from = ""
        var to: [String] = []
        var cc: [String] = []
        var bcc: [String]  = []
        var subject = ""
        for header in mime.header.other {
            let headerName = header.name.lowercased()
            switch headerName {
            case "from":
                from = header.body
            case "to":
                to = header.body.components(separatedBy: ",")
            case "cc":
                cc = header.body.components(separatedBy: ",")
            case "bcc":
                bcc = header.body.components(separatedBy: ",")
            case "subject":
                subject = header.body
            default:
                break
            }
        }
        /// Handle Body.
        var body = ""
        switch mime.content {
        case let .body(content):
            let decodedBodyData: Data
            do {
                decodedBodyData = try content.decodedContentData()
            } catch {
                throw RFC822Error.contentDecoderError(error.localizedDescription)
            }
            guard let decodedBody = String(data: decodedBodyData, encoding: .utf8) else {
                throw RFC822Error.contentDecoderError("Content data not UTF-8 encoded")
            }
            body = decodedBody
        case let .mixed(mimes):
            for mime in mimes {
                guard
                    mime.header.contentType?.type == "multipart",
                    mime.header.contentType?.subtype == "alternative",
                    case let .alternative(alternativeContentMimes) = mime.content
                else {
                    continue
                }
                if let bodyString = processAlternativeMimes(alternativeContentMimes) {
                    body = bodyString
                    break
                }
            }
        case let .alternative(mimes):
            if let string = processAlternativeMimes(mimes) {
                body = string
            }

        @unknown default:
            NSLog("Ignoring unknown mime content \(mime.content)")
        }
        return BasicRFC822Message(from: from, to: to, cc: cc, bcc: bcc, subject: subject, body: body)
    }

    static func fromBasicRFC822(_ message: BasicRFC822Message) -> Data? {
        let isNotEmpty: (String) -> Bool = { !$0.isEmpty }
        let toFormatted = message.to.filter(isNotEmpty).joined(separator: ",")
        let ccFormatted = message.cc.filter(isNotEmpty).joined(separator: ",")
        let bccFormatted = message.bcc.filter(isNotEmpty).joined(separator: ",")
        var formatted = """
        From: \(message.from)
        """
        if !toFormatted.isEmpty {
            formatted += """

            To: \(toFormatted)
            """
        }
        if !ccFormatted.isEmpty {
            formatted += """

            Cc: \(ccFormatted)
            """
        }
        if !bccFormatted.isEmpty {
            formatted += """

            Bcc: \(bccFormatted)
            """
        }
        formatted += """

        Subject: \(message.subject)
        Content-Type: text/plain

        \(message.body)
        """
        return formatted.data(using: .utf8)
    }

    static func processAlternativeMimes(_ mimes: [Mime]) -> String? {
        var body: String?
        for mime in mimes {
            if mime.header.contentType?.type == "text" && mime.header.contentType?.subtype == "plain" {
                if let content = try? mime.decodedContentData(), let s = String(data: content, encoding: .utf8) {
                    body = s
                    break
                }
            }
        }
        return body
    }

    static func toRfc822Address(messageAddresses: [EmailAddressAndName]) -> String {
        var rfc822Address: [String] = []
        messageAddresses.forEach {
            if let displayName = $0.displayName {
                rfc822Address.append(displayName + " <\($0.address)>")
            } else {
                rfc822Address.append($0.address)
            }
        }
        return rfc822Address.joined(separator: ", ")
    }

}
