//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit

extension UIImage {
    func resizeForMMS() -> UIImage? {
        guard var imageData = jpegData(compressionQuality: 1) else { return nil }
        let maxSize: CGFloat = 600000
        var resizedImage = self
        var imageSize = CGFloat(imageData.count)
        while imageSize > maxSize {
            // reduce the image down to 90% unless it's more than twice as large
            // as the desired size then reduce the size by half
            var ratio: CGFloat = 0.9
            if imageSize >= maxSize * 2 {
                ratio = 0.5
            }
            let rect = CGRect(x: 0.0, y: 0.0, width: CGFloat(resizedImage.size.width * ratio), height: CGFloat(resizedImage.size.height * ratio))
            UIGraphicsBeginImageContext(rect.size)
            draw(in: rect)
            resizedImage = UIGraphicsGetImageFromCurrentImageContext()!
            imageData = resizedImage.jpegData(compressionQuality: 1)!
            UIGraphicsEndImageContext()
            imageSize = CGFloat(imageData.count)
        }
        return resizedImage
    }

    func saveToTemporaryURL() -> URL? {
        // store the image in the documents directory
        // then return the URL of the stored file
        guard let imageData = jpegData(compressionQuality: 1) else { return nil }
        let imageUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("temp_image.jpeg")
        do {
            try imageData.write(to: imageUrl)
            return imageUrl
        } catch {
            print("Failed to save image to URL \(imageUrl.path), error: \(error)")
        }
        return nil
    }
}
