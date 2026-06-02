//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoEmail

/// This View Controller presents a form to update an existing `EmailMask`.
///
/// - Links From:
///     - `EmailMaskListViewController`: A user taps an existing mask row.
/// - Links To:
///     - `EmailMaskListViewController`: On successful update, navigates back via unwind segue.
@MainActor
class UpdateEmailMaskViewController: UIViewController {

    // MARK: - Outlets

    /// Text field for the user to edit the metadata (JSON string) of the email mask.
    @IBOutlet weak var metadataTextField: UITextField!

    /// Date picker for the user to set or change the expiry date of the email mask.
    @IBOutlet weak var expiryDatePicker: UIDatePicker!

    /// Switch to enable/disable the expiry date.
    @IBOutlet weak var expirySwitch: UISwitch!

    /// Button to initiate the mask update operation.
    @IBOutlet weak var saveButton: UIButton!

    // MARK: - Supplementary

    /// Segues that are performed in `UpdateEmailMaskViewController`.
    enum Segue: String {
        /// Used to navigate back to the `EmailMaskListViewController` (unwind).
        case returnToEmailMaskList
    }

    // MARK: - Properties

    /// The `EmailMask` being updated.
    var emailMask: EmailMask!

    /// Stores the original metadata string to detect changes.
    private var originalMetadataText: String = ""

    /// Stores the original expiry date to detect changes.
    private var originalExpiryDate: Date?

    /// Tracks whether the user has interacted with the date picker.
    private var expiryDateChanged: Bool = false

    // MARK: - Properties: Computed

    /// Email client used to manage email masks.
    var emailClient: SudoEmailClient {
        return AppDelegate.dependencies.emailClient
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Update Email Mask"
        metadataTextField.placeholder = "key1: value1, key2: value2"
        expiryDatePicker.addTarget(self, action: #selector(expiryDatePickerChanged), for: .valueChanged)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Preload existing metadata
        if let metadata = emailMask.metadata, !metadata.isEmpty {
            let metadataStr = metadata.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            metadataTextField.text = metadataStr
            originalMetadataText = metadataStr
        } else {
            metadataTextField.text = ""
            originalMetadataText = ""
        }

        // Preload existing expiry date
        originalExpiryDate = emailMask.expiresAt
        if let expiresAt = emailMask.expiresAt {
            expiryDatePicker.date = expiresAt
            expirySwitch.isOn = true
            expiryDatePicker.isHidden = false
            expiryDatePicker.isUserInteractionEnabled = true
            expiryDatePicker.alpha = 1.0
        } else {
            expirySwitch.isOn = false
            expiryDatePicker.isHidden = true
            expiryDatePicker.isUserInteractionEnabled = false
            expiryDatePicker.alpha = 0.4
        }
    }

    @objc private func expiryDatePickerChanged() {
        expiryDateChanged = true
    }

    @IBAction func expirySwitchChanged(_ sender: UISwitch) {
        expiryDateChanged = true
        if sender.isOn {
            expiryDatePicker.isHidden = false
            expiryDatePicker.isUserInteractionEnabled = true
            expiryDatePicker.alpha = 1.0
            // Default to tomorrow when enabling expiry for the first time
            if originalExpiryDate == nil {
                expiryDatePicker.date = Date().addingTimeInterval(86400)
            }
        } else {
            expiryDatePicker.isHidden = true
            expiryDatePicker.isUserInteractionEnabled = false
            expiryDatePicker.alpha = 0.4
        }
    }

    // MARK: - Actions

    /// Action associated with tapping the "Save" button.
    ///
    /// This action validates the form inputs, then calls `updateEmailMask()` with the
    /// updated metadata and expiry values.
    @IBAction func didTapSaveButton(_ sender: Any) {
        let metadataText = metadataTextField.text ?? ""

        // Only send metadata if it changed from the original
        var metadata: [String: String]? = nil
        if metadataText != originalMetadataText {
            if !metadataText.isEmpty {
                var parsed: [String: String] = [:]
                let pairs = metadataText.components(separatedBy: ",")
                for pair in pairs {
                    let parts = pair.components(separatedBy: ":")
                    if parts.count >= 2 {
                        let key = parts[0].trimmingCharacters(in: .whitespaces)
                        let value = parts.dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
                        if !key.isEmpty {
                            parsed[key] = value
                        }
                    }
                }
                metadata = parsed.isEmpty ? nil : parsed
            } else {
                // Text was cleared — send empty map to clear metadata on the service
                metadata = [:]
            }
        }

        // Only send expiresAt if the user actually changed the date picker or toggled the switch
        var expiresAt: Date? = nil
        if expiryDateChanged {
            if expirySwitch.isOn {
                // User wants to set/update an expiry date
                expiresAt = expiryDatePicker.date
            } else if originalExpiryDate != nil {
                // User turned off expiry that previously existed — send epoch 0 to clear it
                expiresAt = Date(timeIntervalSince1970: 0)
            }
        }

        // If nothing changed, no need to call the API
        if metadata == nil && expiresAt == nil {
            presentErrorAlert(message: "No changes detected", error: nil)
            return
        }

        presentActivityAlert(message: "Updating Email Mask")
        Task {
            do {
                let input = UpdateEmailMaskInput(
                    emailMaskId: self.emailMask.id,
                    metadata: metadata,
                    expiresAt: expiresAt
                )
                _ = try await self.emailClient.updateEmailMask(withInput: input)
                Task {
                    self.dismissActivityAlert {
                        self.performSegue(withIdentifier: Segue.returnToEmailMaskList.rawValue, sender: self)
                    }
                }
            } catch {
                Task {
                    self.dismissActivityAlert {
                        self.presentErrorAlert(message: "Failed to update email mask", error: error)
                    }
                }
            }
        }
    }
}
