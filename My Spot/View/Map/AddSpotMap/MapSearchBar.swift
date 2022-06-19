//
//  MapSearchBar.swift
//  My Spot
//
//  Created by Isaac Paschall on 6/18/22.
//

import SwiftUI

struct MapSearchBar: View {
    
    @Binding var searchText: String
    @State private var canCancel: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(Color(UIColor.secondarySystemBackground))
            searchBarContent
        }
        .frame(height: 40)
        .cornerRadius(13)
        .padding(.horizontal)
        .onAppear {
            if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                canCancel = true
            }
        }
        .onChange(of: searchText) { text in
            toggleCancelButton(text: text)
        }
    }
    
    private var searchBarContent: some View {
        HStack {
            Image(systemName: "magnifyingglass")
            TextField("Search ".localized(), text: $searchText)
                .submitLabel(.search)
            if (canCancel) {
                Spacer()
                xMarkImage
            }
        }
        .foregroundColor(.gray)
        .padding(.leading, 13)
    }
    
    private var xMarkImage: some View {
        Image(systemName: "xmark")
            .padding(5)
            .background(.ultraThinMaterial)
            .clipShape(Circle())
            .onTapGesture {
                UIApplication.shared.dismissKeyboard()
                searchText = ""
            }
            .padding(.trailing, 13)
    }
    
    private func toggleCancelButton(text: String) {
        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
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
