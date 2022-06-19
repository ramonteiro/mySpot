//
//  DateToString.swift
//  My Spot
//
//  Created by Isaac Paschall on 6/18/22.
//

import Foundation

extension Date {
    
    func toString() -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "MMM d, yyyy"
        return timeFormatter.string(from: self)
    }
    
    func toStringWithTime() -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "MMM d, yyyy: HH:mm:ss"
        return timeFormatter.string(from: self)
    }
}
