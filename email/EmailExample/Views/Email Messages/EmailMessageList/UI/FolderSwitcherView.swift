//
// Copyright © 2022 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit

enum FolderType: String, CaseIterable {
    case inbox
    case sent
    case drafts
    case trash
}

protocol FolderSwitcherViewDelegate: AnyObject {

    /// Called when the user selects a mailbox folder type from the control
    ///
    /// - Parameters:
    ///   - view: The view sending the event
    ///   - folderType: The selected folder type
    func folderSwitcherView(
        _ view: FolderSwitcherView,
        didSelectFolderType folderType: FolderType
    )

    /// Called when the user taps on the empty trash button
    func emptyTrash()
}

class FolderSwitcherView: UITableViewHeaderFooterView {

    // MARK: - Properties

    /// Button to select Email Folder
    let menuButton = UIButton()

    /// Button to permanently delete email messages from the Trash folder
    let emptyTrashButton = UIButton()

    let contentContainerView = UIStackView()

    /// The title of the currently selected Email Folder
    let title = UILabel()

    /// The menu image
    let image = UIImage(systemName: "questionmark.folder")

    /// The image for the empty Trash button
    let emptyTrashImage = UIImage(systemName: "trash.slash.fill")

    var currentFolder: FolderType = .inbox

    /// Optional delegate to handle mailbox selection types with
    weak var delegate: FolderSwitcherViewDelegate?

    // MARK: - Lifecycle

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        title.translatesAutoresizingMaskIntoConstraints = false

        let inboxAction = UIAction(title: "Inbox") { _ in
            self.currentFolder = .inbox
            self.delegate?.folderSwitcherView(self, didSelectFolderType: .inbox)
            self.title.text = self.titleForCurrentFolder()
            self.menuButton.sizeToFit()
            self.emptyTrashButton.isHidden = true
        }
        let sentAction = UIAction(title: "Sent") { _ in
            self.currentFolder = .sent
            self.delegate?.folderSwitcherView(self, didSelectFolderType: .sent)
            self.title.text = self.titleForCurrentFolder()
            self.menuButton.sizeToFit()
            self.emptyTrashButton.isHidden = true
        }
        let draftsAction = UIAction(title: "Drafts") { _ in
            self.currentFolder = .drafts
            self.delegate?.folderSwitcherView(self, didSelectFolderType: .drafts)
            self.title.text = self.titleForCurrentFolder()
            self.menuButton.sizeToFit()
            self.emptyTrashButton.isHidden = true
        }
        let trashAction = UIAction(title: "Trash") { _ in
            self.currentFolder = .trash
            self.delegate?.folderSwitcherView(self, didSelectFolderType: .trash)
            self.title.text = self.titleForCurrentFolder()
            self.menuButton.sizeToFit()
            self.emptyTrashButton.setImage(self.emptyTrashImage, for: .normal)
            self.emptyTrashButton.isHidden = false
            self.emptyTrashButton.sizeToFit()
            self.emptyTrashButton.addTarget(
                self,
                action: #selector(self.didTapEmptyTrashButton),
                for: .touchUpInside
            )
        }
        let menu = UIMenu(
            children: [
                inboxAction,
                sentAction,
                draftsAction,
                trashAction
            ]
        )
        contentContainerView.axis = .horizontal
        contentContainerView.translatesAutoresizingMaskIntoConstraints = false
        contentContainerView.spacing = 8
        contentView.addSubview(contentContainerView)
        menuButton.menu = menu
        menuButton.showsMenuAsPrimaryAction = true
        menuButton.setImage(image, for: .normal)
        title.text = titleForCurrentFolder()

        let spacer = UIView()
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        contentContainerView.addArrangedSubview(menuButton)
        contentContainerView.addArrangedSubview(title)
        contentContainerView.addArrangedSubview(spacer)
        contentContainerView.addArrangedSubview(emptyTrashButton)

        NSLayoutConstraint.activate([
            contentContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            contentContainerView.trailingAnchor.constraint(equalTo:
                   contentView.layoutMarginsGuide.trailingAnchor, constant: -8),
            contentContainerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func titleForCurrentFolder() -> String {
        switch currentFolder {
        case .inbox:
            return "Inbox"
        case .sent:
            return "Sent"
        case .drafts:
            return "Drafts"
        case .trash:
            return "Trash"
        }
    }

    // MARK: - Actions
    @objc func didTapEmptyTrashButton() {
        self.delegate?.emptyTrash()
    }
}
