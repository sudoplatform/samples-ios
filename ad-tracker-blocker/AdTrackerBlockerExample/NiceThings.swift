//
//  NiceThings.swift
//  AdTrackerBlockerExample
//
//  Copyright © 2020 Sudo Platform. All rights reserved.
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
