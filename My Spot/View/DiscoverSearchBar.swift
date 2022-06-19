//
//  DiscoverSearchBar.swift
//  My Spot
//
//  Created by Isaac Paschall on 6/18/22.
//

import SwiftUI

struct DiscoverSearchBar: View {
    
    @Binding var searchText: String
    @Binding var searching: Bool
    @Binding var searchName: String
    @Binding var hasSearched: Bool
    @State private var canCancel: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(Color(UIColor.secondarySystemBackground))
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search ".localized() + searchName, text: $searchText)
                    .submitLabel(.search)
                    .onSubmit {
                        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            searching.toggle()
                        }
                    }
                if (canCancel) {
                    Spacer()
                    Image(systemName: "xmark")
                        .padding(5)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .onTapGesture {
                            UIApplication.shared.dismissKeyboard()
                            searchText = ""
                            if hasSearched {
                                searching.toggle()
                            }
                        }
                        .padding(.trailing, 13)
                }
            }
            .foregroundColor(.gray)
            .padding(.leading, 13)
        }
        .frame(height: 40)
        .cornerRadius(13)
        .padding(.horizontal)
        .onChange(of: searchText) { newValue in
            if !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                withAnimation(.easeInOut(duration: 0.2)) {
                    canCancel = true
                }
            } else {
                withAnimation(.easeInOut(duration: 0.2)) {
                    canCancel = false
                }
            }
        }
    }
}

