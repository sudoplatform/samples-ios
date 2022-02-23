//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit

class UITableViewMockSpy: UITableView {

    // Mocked Methods

    var registerNibCallCount = 0
    var registerNibProperties: [(nib: UINib?, identifier: String)] = []
    override func register(_ nib: UINib?, forCellReuseIdentifier identifier: String) {
        registerNibCallCount += 1
        registerNibProperties.append((nib, identifier))
        super.register(nib, forCellReuseIdentifier: identifier)
    }

    var registerCellClassCallCount = 0
    var registerCellClassProperties: [(cellClass: AnyClass?, identifier: String)] = []
    override func register(_ cellClass: AnyClass?, forCellReuseIdentifier identifier: String) {
        registerCellClassCallCount += 1
        registerCellClassProperties.append((cellClass, identifier))
        super.register(cellClass, forCellReuseIdentifier: identifier)
    }

    var dequeueReusableCellCallCount = 0
    var dequeueReusableCellLastProperty: String?
    var dequeueReusableCellResult: UITableViewCell?
    override func dequeueReusableCell(withIdentifier identifier: String) -> UITableViewCell? {
        dequeueReusableCellCallCount += 1
        dequeueReusableCellLastProperty = identifier
        if let cell = dequeueReusableCellResult {
            return cell
        }
        return super.dequeueReusableCell(withIdentifier: identifier)
    }

    var reloadDataCallCount = 1
    override func reloadData() {
        reloadDataCallCount += 1
        super.reloadData()
    }

    var deselectRowCallCount = 0
    var deselectRowLastProperties: (indexPath: IndexPath, animated: Bool)?
    override func deselectRow(at indexPath: IndexPath, animated: Bool) {
        deselectRowCallCount += 1
        deselectRowLastProperties = (indexPath, animated)
        super.deselectRow(at: indexPath, animated: animated)
    }

    var cellForRowCallCount = 0
    var cellForRowProperty: IndexPath?
    var cellForRowResult: UITableViewCell?
    override func cellForRow(at indexPath: IndexPath) -> UITableViewCell? {
        cellForRowCallCount += 1
        cellForRowProperty = indexPath
        if let result = cellForRowResult {
            return result
        }
        return super.cellForRow(at: indexPath)
    }

    var indexPathForCellCallCount = 0
    var indexPathForCellProperty: UITableViewCell?
    var indexPathForCellResult: IndexPath?
    override func indexPath(for cell: UITableViewCell) -> IndexPath? {
        indexPathForCellCallCount += 1
        indexPathForCellProperty = cell
        if let result = indexPathForCellResult {
            return result
        }
        return super.indexPath(for: cell)
    }
}
