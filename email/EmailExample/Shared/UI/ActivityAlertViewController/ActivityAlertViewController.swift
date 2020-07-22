//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit

protocol ActivityAlertViewControllerDelegate: class {

    /// Cancel button on the Activity Alert overlay has been pressed by the user.
    func didTapAlertCancelButton()

}

/// Custom view controller to overlay an indicator to the user that an operation is occurring.
///
/// For example. "Creating a funding source", "Checking status" overlays use this view.
class ActivityAlertViewController: UIViewController {

    // MARK: - Outlets

    /// Box containing the whole activity box.
    @IBOutlet var activityBoxView: UIView!

    /// Bottom half of the activity box containing the separator and the cancel button.
    @IBOutlet var cancelView: UIStackView!

    /// Label of the view. Its text should be set by `message`.
    @IBOutlet var label: UILabel!

    @IBOutlet var cancelButton: UIButton!

    // MARK: - Properties

    var cancellable: Bool = false

    weak var delegate: ActivityAlertViewControllerDelegate?

    /// Message used for the label of the view.
    var message: String? {
        didSet {
            label.text = message
        }
    }

    // MARK: - Lifecycle

    /// Initialize a `ActivityAlertViewController` with a message.
    init(message: String, cancellable: Bool = false, delegate: ActivityAlertViewControllerDelegate? = nil) {
        self.message = message
        self.cancellable = cancellable
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    // MARK: - Lifecycle: UIViewController

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        modalPresentationStyle = .overCurrentContext
        view.backgroundColor = .clear
        activityBoxView.layer.cornerRadius = 10
        label.text = message
        cancelView.isHidden = !cancellable
    }

    // MARK: - Actions

    @IBAction func didTapCancelButton() {
        delegate?.didTapAlertCancelButton()
    }

}
