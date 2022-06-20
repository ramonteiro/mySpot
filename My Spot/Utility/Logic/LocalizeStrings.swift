//
//  LocalizeStrings.swift
//  My Spot
//
//  Created by Isaac Paschall on 6/18/22.
//

import Foundation

extension String {
    func localized() -> String {
        return NSLocalizedString(self, tableName: "Localizable", bundle: .main, value: self, comment: self)
    }
    subscript(offset: Int) -> Character { self[index(startIndex, offsetBy: offset)] }
}
