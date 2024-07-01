//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit

extension UIImage {

    public static func toAttributedString(systemName: String, withTintColor color: UIColor = .black) -> NSAttributedString {
        guard let image = UIImage(systemName: systemName)?.withTintColor(color) else {
            return NSAttributedString(string: "invalid image")
        }
        let imageAttachment = NSTextAttachment(image: image)
        let stringifiedImage = NSAttributedString(attachment: imageAttachment)

        return stringifiedImage
    }

}
