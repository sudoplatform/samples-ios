//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

private class DataFactoryBundleLoader {}

extension DataFactory {

    enum TestData {

        private static let bundle = Bundle(for: DataFactoryBundleLoader.self)

        private static func loadFileString(forResource resource: String, withExtension ext: String?) -> String {
            guard let url = bundle.url(forResource: resource, withExtension: ext) else {
                fatalError("Failed to load file from bundle: \(resource).\(ext ?? "")")
            }
            do {
                return try String(contentsOf: url)
            } catch {
                fatalError("Failed to load file from bundle: \(resource).\(ext ?? ""). Error: \(error.localizedDescription)")
            }
        }

        private static var _complexBase64Email: String?
        static var complexBase64Email: String {
            if let complexBase64Email = _complexBase64Email {
                return complexBase64Email
            }
            return loadFileString(forResource: "ComplexBase64Email", withExtension: "txt")
        }

        private static var _complexDataEmail: String?
        static var complexDataEmail: String {
            if let complexDataEmail = _complexDataEmail {
                return complexDataEmail
            }
            return loadFileString(forResource: "ComplexDataEmail", withExtension: "txt")
        }

        private static var _base64EncodedBodyEmail: String?
        static var base64EncodedBodyEmail: String {
            if let base64EncodedBodyEmail = _base64EncodedBodyEmail {
                return base64EncodedBodyEmail
            }
            return loadFileString(forResource: "Base64EncodedBody", withExtension: "txt")
        }
    }
}
