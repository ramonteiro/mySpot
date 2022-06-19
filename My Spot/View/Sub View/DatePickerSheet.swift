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
            Text(dateFound.toString())
            DatePicker("Date Found".localized(), selection: $dateFound, in: ...Date(), displayedComponents: [.date])
                .datePickerStyle(.graphical)
        }
    }
}
