//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import MimeParser

struct BasicRFC822Message {
    public var from: String
    public var to: [String]
    public var cc: [String] = []
    public var bcc: [String] = []
    public var subject: String
    public var body: String
}

class RFC822Util {

    static func fromPlainText(_ data: Data) -> BasicRFC822Message? {
        let parser = MimeParser()
        let stringData = String(decoding: data, as: UTF8.self)

        let mime: Mime
        do {
            mime = try parser.parse(stringData)
        } catch {
            NSLog("Parsing Failure: \(error)")
            return nil
        }

        var from = ""
        var to: [String] = []
        var cc: [String] = []
        var bcc: [String]  = []
        var subject = ""
        var body = ""

        for header in mime.header.other {
            if header.name.lowercased() == "from" {
                from = header.body
            }

            if header.name.lowercased() == "to" {
                header.body.split(separator: ",").forEach { s in
                    to.append(String(s))
                }
            }

            if header.name.lowercased() == "cc" {
                header.body.split(separator: ",").forEach { s in
                    cc.append(String(s))
                }
            }

            if header.name.lowercased() == "bcc" {
                header.body.split(separator: ",").forEach { s in
                    bcc.append(String(s))
                }
            }

            if header.name.lowercased() == "subject" {
                subject = header.body
            }
        }

        if case .body(let content) = mime.content {
            body = content.raw
        }

        if case .mixed(let mime) = mime.content {
            for m in mime {
                if m.header.contentType?.type == "multipart" && m.header.contentType?.subtype == "alternative" {
                    if case .alternative(let mime) = m.content {
                        if let s = self.processAlternative(mime: mime) {
                            body = s
                            break
                        }
                    }
                }
            }
        }

        if case .alternative(let mime) = mime.content {
            if let s = self.processAlternative(mime: mime) {
                body = s
            }
        }

        return BasicRFC822Message(from: from, to: to, cc: cc, bcc: bcc, subject: subject, body: body)
    }

    static func fromBasicRFC822(_ message: BasicRFC822Message) -> Data? {
        let toFormatted = message.to.reduce("", accumulate(accumulator:item:))
        let ccFormatted = message.cc.reduce("", accumulate(accumulator:item:))
        let bccFormatted = message.bcc.reduce("", accumulate(accumulator:item:))
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

    static func processAlternative(mime: [Mime]) -> String? {
        var body: String?
        for m in mime {
            if m.header.contentType?.type == "text" && m.header.contentType?.subtype == "plain" {
                if let content = try? m.decodedContentData(), let s = String(data: content, encoding: .utf8) {
                    body = s
                    break
                }
            }
        }
        return body
    }

    static func accumulate(accumulator: String, item: String) -> String {
        var accumulator = accumulator
        if !accumulator.isEmpty {
            accumulator.append(",")
        }
        return accumulator + item
    }
}
