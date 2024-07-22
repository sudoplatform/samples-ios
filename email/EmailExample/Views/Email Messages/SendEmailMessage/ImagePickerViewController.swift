//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import UniformTypeIdentifiers
import SudoEmail

public class ImagePickerViewController: UIImagePickerController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // MARK: - Properties

    var onImagePickedHandler: ((_ imageURL: URL) -> Void)?

    // MARK: - Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()
    }

    convenience init(onImagePickedHandler: ((_ imageURL: URL) -> Void)?) {
        self.init()
        delegate = self
        sourceType = .photoLibrary
        self.onImagePickedHandler = onImagePickedHandler
    }

    // MARK: - Conformance: UIImagePickerControllerDelegate

    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let imageURL = info[.imageURL] as? URL {
             onImagePickedHandler?(imageURL)
        }
        picker.dismiss(animated: true, completion: nil)
    }
}
