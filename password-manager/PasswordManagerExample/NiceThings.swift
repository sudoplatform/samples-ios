//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

@propertyWrapper struct UserDefaultsBacked<Value> {
    let key: String
    var storage: UserDefaults = .standard

    var wrappedValue: Value? {
        get { storage.value(forKey: key) as? Value}
        set { storage.setValue(newValue, forKey: key) }
    }
}

@propertyWrapper struct UserDefaultsBackedWithDefault<Value> {
    let key: String
    var storage: UserDefaults = .standard
    var defaultValue: Value

    var wrappedValue: Value {
        get { (storage.value(forKey: key) as? Value) ?? defaultValue }
        set { storage.setValue(newValue, forKey: key) }
    }
}
