//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoEmail

class EmailAttachmentsListController {

    // MARK: - Properties

    /// The parent container that contains the list item views that represent attachments.
    var attachmentsListView: UIStackView?

    /// Handler that is called if a list item is clicked.
    var onListItemClickedHandler: ((String) -> Void)?

    // MARK: - Lifecycle

    public init(
        containingView: UIView,
        siblingView: UIView?,
        onListItemClickedHandler: ((String) -> Void)?
    ) {
        let attachmentsListView = UIStackView()
        attachmentsListView.axis = .vertical
        attachmentsListView.distribution = .fillProportionally
        attachmentsListView.alignment = .fill
        attachmentsListView.spacing = 5.0
        attachmentsListView.translatesAutoresizingMaskIntoConstraints = false

        if let siblingView = siblingView {
            containingView.insertSubview(attachmentsListView, aboveSubview: siblingView)
        } else {
            containingView.addSubview(attachmentsListView)
        }
        let margin = containingView.layoutMarginsGuide
        NSLayoutConstraint.activate([
            attachmentsListView.topAnchor.constraint(equalTo: margin.topAnchor),
            attachmentsListView.leadingAnchor.constraint(equalTo: margin.leadingAnchor),
            attachmentsListView.trailingAnchor.constraint(equalTo: margin.trailingAnchor)
        ])

        self.attachmentsListView = attachmentsListView
        self.onListItemClickedHandler = onListItemClickedHandler
    }

    // MARK: - Utility

    /// Creates a UI view containing paperclip icon and extension name.
    /// The 'on click' action of the view is determined by the callback assigned to `onClickHandler` in init.
    private func attachmentListItem(attachmentName: String) -> UIView {
        let height = 20.0
        let listItem = UIView()
        listItem.translatesAutoresizingMaskIntoConstraints = false
        listItem.heightAnchor.constraint(equalToConstant: height).isActive = true
        listItem.isUserInteractionEnabled = true

        let labelString = NSMutableAttributedString()
        let attachmentImageString = UIImage.toAttributedString(systemName: "paperclip", withTintColor: .link)
        let labelTextString = NSAttributedString(string: " \(attachmentName)")
        labelString.append(attachmentImageString)
        labelString.append(labelTextString)

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.textAlignment = .left
        label.text = attachmentName
        label.attributedText = labelString
        label.textColor = .link
        listItem.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: listItem.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: listItem.trailingAnchor),
            label.topAnchor.constraint(equalTo: listItem.topAnchor),
            label.bottomAnchor.constraint(equalTo: listItem.bottomAnchor)
        ])

        return listItem
    }

    /// Re-render attachment items with values in updated `attachments` set.
    public func setAttachments(attachments: Set<EmailAttachment>) {
        if let attachmentsListView = self.attachmentsListView {
            attachmentsListView.subviews.forEach { $0.removeFromSuperview() }
            for attachment in attachments {
                let view = attachmentListItem(attachmentName: attachment.filename ?? "")
                if let onListItemClickHandler = self.onListItemClickedHandler {
                    view.setOnClickHandler(action: {
                        onListItemClickHandler(attachment.filename ?? "")
                    })
                }
                attachmentsListView.addArrangedSubview(view)
            }
            attachmentsListView.setNeedsLayout()
            attachmentsListView.layoutIfNeeded()
        }
    }

}
