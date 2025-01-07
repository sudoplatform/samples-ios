//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit

enum StandardFolders: String, CaseIterable {
    case inbox
    case outbox
    case sent
    case trash
}

enum SpecialLabels: String, CaseIterable {
    case drafts
    case blocklist
    case create
}

enum FolderSwitcherLabels: Equatable {
    case standard(StandardFolders)
    case special(SpecialLabels)
    case string(String)
}

protocol FolderSwitcherViewDelegate: AnyObject {

    /// Called when the user selects a mailbox folder type from the control
    ///
    /// - Parameters:
    ///   - view: The view sending the event
    ///   - folderType: The selected folder
    func folderSwitcherView(
        _ view: FolderSwitcherView,
        didSelectFolderType folderType: FolderSwitcherLabels
    )

    /// Called when the user taps on the empty trash button
    func emptyTrash()

    func unblockEmailAddresses()

    func deleteCustomFolder()
    
    func updateCustomFolder()
}

class FolderSwitcherView: UITableViewHeaderFooterView {

    // MARK: - Properties

    /// Button to select Email Folder
    let menuButton = UIButton()

    /// Button to permanently delete email messages from the Trash folder
    let emptyTrashButton = UIButton()

    let deleteCustomFolderButton = UIButton()
    
    let updateCustomFolderButton = UIButton()

    let unblockAddressesButton = UIButton()

    var contentContainerView = UIStackView()

    /// The title of the currently selected Email Folder
    let title = UILabel()

    /// The menu image
    let image = UIImage(systemName: "folder")

    /// The image for the empty Trash button
    let emptyTrashImage = UIImage(systemName: "trash.slash.fill")

    let deleteCustomFolderImage = UIImage(systemName: "trash.slash.fill")
    
    let updateCustomFolderImage = UIImage(systemName: "pencil")

    let unblockAddressesImage = UIImage(systemName: "trash.slash.fill")

    var folderNames: [String] = []

    var currentFolder: FolderSwitcherLabels = .standard(.inbox)

    /// Optional delegate to handle mailbox selection types with
    weak var delegate: FolderSwitcherViewDelegate?

    // MARK: - Lifecycle

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        title.translatesAutoresizingMaskIntoConstraints = false
        populateMenu()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func populateMenu() {
        self.contentContainerView = UIStackView()
        var uiActions: [UIAction] = []

        folderNames.forEach {
            var action: UIAction
            if $0.lowercased() == StandardFolders.inbox.rawValue.lowercased() {
                action = UIAction(title: "Inbox") { _ in
                    self.currentFolder = .standard(.inbox)
                    self.delegate?.folderSwitcherView(self, didSelectFolderType: .standard(.inbox))
                    self.title.text = self.titleForCurrentFolder()
                    self.menuButton.sizeToFit()
                    self.emptyTrashButton.isHidden = true
                    self.unblockAddressesButton.isHidden = true
                    self.deleteCustomFolderButton.isHidden = true
                    self.updateCustomFolderButton.isHidden = true
                }
            } else if $0.lowercased() == StandardFolders.trash.rawValue.lowercased() {
                action = UIAction(title: "Trash") { _ in
                    self.currentFolder = .standard(.trash)
                    self.delegate?.folderSwitcherView(self, didSelectFolderType: .standard(.trash))
                    self.title.text = self.titleForCurrentFolder()
                    self.menuButton.sizeToFit()
                    self.emptyTrashButton.setImage(self.emptyTrashImage, for: .normal)
                    self.emptyTrashButton.isHidden = false
                    self.unblockAddressesButton.isHidden = true
                    self.emptyTrashButton.sizeToFit()
                    self.emptyTrashButton.addTarget(
                        self,
                        action: #selector(self.didTapEmptyTrashButton),
                        for: .touchUpInside
                    )
                    self.deleteCustomFolderButton.isHidden = true
                    self.updateCustomFolderButton.isHidden = true
                }
            } else if $0.lowercased() == StandardFolders.sent.rawValue.lowercased() {
                action = UIAction(title: "Sent") { _ in
                    self.currentFolder = .standard(.sent)
                    self.delegate?.folderSwitcherView(self, didSelectFolderType: .standard(.sent))
                    self.title.text = self.titleForCurrentFolder()
                    self.menuButton.sizeToFit()
                    self.emptyTrashButton.isHidden = true
                    self.unblockAddressesButton.isHidden = true
                    self.deleteCustomFolderButton.isHidden = true
                    self.updateCustomFolderButton.isHidden = true
                }
            } else if $0.lowercased() == StandardFolders.outbox.rawValue.lowercased() {
                action = UIAction(title: "Outbox") { _ in
                    self.currentFolder = .standard(.sent)
                    self.delegate?.folderSwitcherView(self, didSelectFolderType: .standard(.outbox))
                    self.title.text = self.titleForCurrentFolder()
                    self.menuButton.sizeToFit()
                    self.emptyTrashButton.isHidden = true
                    self.unblockAddressesButton.isHidden = true
                    self.deleteCustomFolderButton.isHidden = true
                    self.updateCustomFolderButton.isHidden = true
                }
            } else {
                let label = $0
                action = UIAction(title: $0) { _ in
                    self.currentFolder = .string(label)
                    self.delegate?.folderSwitcherView(self, didSelectFolderType: .string(label))
                    self.title.text = self.titleForCurrentFolder()
                    self.menuButton.sizeToFit()
                    self.emptyTrashButton.isHidden = true
                    self.unblockAddressesButton.isHidden = true
                    self.deleteCustomFolderButton.isHidden = false
                    self.deleteCustomFolderButton.setImage(self.deleteCustomFolderImage, for: .normal)
                    self.deleteCustomFolderButton.sizeToFit()
                    self.deleteCustomFolderButton.addTarget(
                        self,
                        action: #selector(self.didTapDeleteCustomFolderButton),
                        for: .touchUpInside
                    )
                    self.updateCustomFolderButton.isHidden = false
                    self.updateCustomFolderButton.setImage(self.updateCustomFolderImage, for: .normal)
                    self.updateCustomFolderButton.sizeToFit()
                    self.updateCustomFolderButton.addTarget(
                        self,
                        action: #selector(self.didTapUpdateCustomFolderButton),
                        for: .touchUpInside
                    )
                }
            }
            uiActions.append(action)
        }
        uiActions.append(UIAction(title: "Drafts") { _ in
            self.currentFolder = .special(.drafts)
            self.delegate?.folderSwitcherView(self, didSelectFolderType: .special(.drafts))
            self.title.text = self.titleForCurrentFolder()
            self.menuButton.sizeToFit()
            self.emptyTrashButton.isHidden = true
            self.unblockAddressesButton.isHidden = true
            self.deleteCustomFolderButton.isHidden = true
            self.updateCustomFolderButton.isHidden = true
        })
        uiActions.append(UIAction(title: "Create Custom Folder") { _ in
            self.currentFolder = .special(.create)
            self.delegate?.folderSwitcherView(self, didSelectFolderType: .special(.create))
            self.title.text = self.titleForCurrentFolder()
            self.menuButton.sizeToFit()
            self.emptyTrashButton.isHidden = true
            self.unblockAddressesButton.isHidden = true
            self.deleteCustomFolderButton.isHidden = true
            self.updateCustomFolderButton.isHidden = true
        })
        uiActions.append(UIAction(title: "Blocklist") { _ in
            self.currentFolder = .special(.blocklist)
            self.delegate?.folderSwitcherView(self, didSelectFolderType: .special(.blocklist))
            self.title.text = self.titleForCurrentFolder()
            self.menuButton.sizeToFit()
            self.emptyTrashButton.isHidden = true
            self.unblockAddressesButton.setImage(self.emptyTrashImage, for: .normal)
            self.unblockAddressesButton.isHidden = false
            self.unblockAddressesButton.sizeToFit()
            self.unblockAddressesButton.addTarget(
                self,
                action: #selector(self.didTapUnblockEmailAddressesButton),
                for: .touchUpInside
            )
            self.deleteCustomFolderButton.isHidden = true
            self.updateCustomFolderButton.isHidden = true
        })
        let menu = UIMenu(
            children: uiActions
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
        contentContainerView.addArrangedSubview(unblockAddressesButton)
        contentContainerView.addArrangedSubview(deleteCustomFolderButton)
        contentContainerView.addArrangedSubview(updateCustomFolderButton)

        NSLayoutConstraint.activate([
            contentContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            contentContainerView.trailingAnchor.constraint(equalTo:
                   contentView.layoutMarginsGuide.trailingAnchor, constant: -8),
            contentContainerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    func titleForCurrentFolder() -> String {
        switch currentFolder {
        case .standard(.inbox):
            return "Inbox"
        case .standard(.sent):
            return "Sent"
        case .special(.drafts):
            return "Drafts"
        case .standard(.trash):
            return "Trash"
        case .standard(.outbox):
            return "Outbox"
        case .special(.blocklist):
            return "Blocklist"
        case .special(.create):
            return "Create Custom Folder"
        case .string(let str):
            return str
        }
    }

    // MARK: - Actions
    @objc func didTapEmptyTrashButton() {
        self.delegate?.emptyTrash()
    }

    @objc func didTapUnblockEmailAddressesButton() {
        self.delegate?.unblockEmailAddresses()
    }
    
    @objc func didTapDeleteCustomFolderButton() {
        self.delegate?.deleteCustomFolder()
    }
    
    @objc func didTapUpdateCustomFolderButton() {
        self.delegate?.updateCustomFolder()
    }
}
