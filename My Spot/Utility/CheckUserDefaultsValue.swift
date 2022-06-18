//
//  CheckUserDefaultsValue.swift
//  My Spot
//
//  Created by Isaac Paschall on 6/18/22.
//

import Foundation

extension UserDefaults {
    func valueExists(forKey key: String) -> Bool {
        return object(forKey: key) != nil
    }
}
