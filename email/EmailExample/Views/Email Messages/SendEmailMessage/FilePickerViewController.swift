//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import UniformTypeIdentifiers
import SudoEmail

public class FilePickerViewController: UIDocumentPickerViewController, UIDocumentPickerDelegate {

    // MARK: - Properties

    var onFilePickedHandler: ((_ fileURL: URL) -> Void)?

    // MARK: - Lifecycle

    override public init(forOpeningContentTypes contentTypes: [UTType], asCopy: Bool) {
        super.init(forOpeningContentTypes: contentTypes, asCopy: asCopy)
    }

    convenience init(onFilePickedHandler: ((_ fileURL: URL) -> Void)?) {
        self.init(forOpeningContentTypes: [.data, .item, .content], asCopy: false)
        self.modalPresentationStyle = .overFullScreen
        self.onFilePickedHandler = onFilePickedHandler
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
    }

    // MARK: - Conformance: UIDocumentPickerDelegate

    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let url = urls.first,
           let onFilePickedHandler = onFilePickedHandler {
            onFilePickedHandler(url)
        }
    }
}
