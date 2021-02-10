//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit

@IBDesignable
class RadialButton: UIButton {

    // MARK: - Outlets

    @IBOutlet var powerImageView: UIImageView!

    // MARK: - Inspectables

    @IBInspectable var cornerRadius: CGFloat = 128 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = cornerRadius > 0
        }
    }

    // MARK: - UI Setup

    override func prepareForInterfaceBuilder() {
        layer.cornerRadius = cornerRadius
    }

    // MARK: - Lifecycle

    override func awakeAfter(using aDecoder: NSCoder) -> Any? {
        if subviews.isEmpty {
            let view: RadialButton = .fromNib()
            view.backgroundColor = backgroundColor
            view.frame = frame
            view.translatesAutoresizingMaskIntoConstraints = false
            view.setupView()
            return view
        }
        return super.awakeAfter(using: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func setupView() {
        self.powerImageView.image = UIImage(systemName: "power")
    }

}
