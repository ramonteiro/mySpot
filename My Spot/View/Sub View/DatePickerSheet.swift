//
//  DatePickerSheet.swift
//  My Spot
//
//  Created by Isaac Paschall on 6/11/22.
//

import SwiftUI

struct DatePickerSheet: View {
    
    @Binding var dateFound: Date
    private let dateFormatter = DateFormatter()
    
    var body: some View {
        VStack {
            Text("Date Found".localized())
                .font(.largeTitle)
            Text(dateFound.format())
            DatePicker("Date Found".localized(), selection: $dateFound, in: ...Date(), displayedComponents: [.date])
                .datePickerStyle(.graphical)
        }
    }
}

extension Date {
    
    func format() -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "MMM d, yyyy"
        return timeFormatter.string(from: self)
    }
    
    func formatWithTime() -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "MMM d, yyyy: HH:mm:ss"
        return timeFormatter.string(from: self)
    }
}
