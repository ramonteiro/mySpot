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
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(Color(UIColor.secondarySystemBackground))
            searchBarContent
        }
        .frame(height: 40)
        .cornerRadius(13)
        .padding(.horizontal)
        .onChange(of: searchText) { text in
            toggleCancelButton(text: text)
        }
    }
    
    private var searchBarContent: some View {
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
                if hasSearched {
                    searching.toggle()
                }
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

