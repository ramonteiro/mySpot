//
//  PlaylistEditSheet.swift
//  My Spot
//
//  Created by Isaac Paschall on 3/15/22.
//

import SwiftUI
import Combine

struct PlaylistEditSheet: View {
    
    let playlist: Playlist
    @Environment(\.presentationMode) var presentationMode
    @State private var nameChecked = false
    @State private var emojiChecked = false
    @State private var name = ""
    @State private var emoji = ""
    
    private enum Field {
        case name
        case emoji
    }
    
    @FocusState private var focusState: Field?
    
    var body: some View {
        NavigationView {
            Form {
                nameTextField
                emojiTextField
            }
            .onSubmit {
                moveDown()
            }
            .navigationTitle(name)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    cancelButton
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    saveButton
                }
                ToolbarItemGroup(placement: .keyboard) {
                    keyboardButtons
                }
            }
            .navigationViewStyle(.stack)
        }
    }
    
    // MARK: - Sub Views
    
    private var upButton: some View {
        Button {
            moveUp()
        } label: {
            Image(systemName: "chevron.up")
        }
        .disabled(focusState == .name)
    }
    
    private var downButton: some View {
        Button {
            moveDown()
        } label: {
            Image(systemName: "chevron.down")
        }
        .disabled(focusState == .emoji)
    }
    
    private var keyboardButtons: some View {
        HStack {
            upButton
            downButton
            Spacer()
            Button("Done".localized()) {
                focusState = nil
            }
        }
    }
    
    private var saveButton: some View {
        Button("Save".localized()) {
            saveChanges()
        }
        .padding(.trailing)
        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || emoji.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .tint(.blue)
    }
    
    private var cancelButton: some View {
        Button("Cancel".localized()) {
            name = ""
            emoji = ""
            presentationMode.wrappedValue.dismiss()
        }
        .padding(.leading)
    }
    
    private var nameTextField: some View {
        Section {
            TextField("Enter Playlist Name".localized(), text: $name)
                .onReceive(Just(name)) { _ in
                    if (name.count > MaxCharLength.names) {
                        name = String(name.prefix(MaxCharLength.names))
                    }
                }
                .onAppear {
                    if !nameChecked {
                        name = playlist.name ?? ""
                        nameChecked = true
                    }
                }
                .focused($focusState, equals: .name)
                .submitLabel(.next)
        } header: {
            Text("Playlist Name*".localized())
        }
    }
    
    private var emojiTextField: some View {
        Section {
            EmojiTextField(text: $emoji, placeholder: "Enter Emoji".localized())
                .onReceive(Just(emoji)) { _ in
                    self.emoji = String(self.emoji.onlyEmoji().prefix(MaxCharLength.emojis))
                }
                .onAppear {
                    if !emojiChecked {
                        emoji = playlist.emoji ?? ""
                        emojiChecked = true
                    }
                }
                .focused($focusState, equals: .emoji)
                .submitLabel(.done)
        } header: {
            Text("Emoji*".localized())
        }
    }
    
    // MARK: - Functions
    
    private func moveDown() {
        switch focusState {
        case .name:
            focusState = .emoji
        default:
            focusState = nil
        }
    }
    
    private func moveUp() {
        switch focusState {
        case .emoji:
            focusState = .name
        default:
            focusState = nil
        }
    }
    
    private func saveChanges() {
        playlist.name = name
        playlist.emoji = emoji
        CoreDataStack.shared.save()
        presentationMode.wrappedValue.dismiss()
    }
}
