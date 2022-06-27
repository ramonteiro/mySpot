//
//  AddPlaylistSheet.swift
//  mySpot
//
//  Created by Isaac Paschall on 2/23/22.
//

/*
 AddPlaylistSheet:
 Dsiplays prompts to create new playlist
 */

import SwiftUI
import Combine

struct AddPlaylistSheet: View {
    
    @Environment(\.presentationMode) var presentationMode
    @State private var showingAlert = false
    @State private var name = ""
    @State private var emoji = ""
    @State private var isEmoji: Bool = true
    @FocusState private var focusState: Field?
    
    private var disableSave: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        emoji.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    enum Field {
        case emoji
        case name
    }

    var body: some View {
        NavigationView {
            Form {
                nameSection
                emojiSection
            }
            .onSubmit {
                moveDown()
            }
            .navigationTitle("Create Playlist".localized())
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    keyboardButtons
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    saveButton
                }
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    deleteButton
                }
            }
        }
        .navigationViewStyle(.stack)
        .interactiveDismissDisabled()
    }
    
    // MARK: - Sub Views
    
    private var keyboardButtons: some View {
        HStack {
            upButton
            downButton
            Spacer()
            doneButton
        }
    }
    
    private var downButton: some View {
        Button {
            moveDown()
        } label: {
            Image(systemName: "chevron.down")
        }
        .disabled(focusState == .emoji)
    }
    
    private var upButton: some View {
        Button {
            moveUp()
        } label: {
            Image(systemName: "chevron.up")
        }
        .disabled(focusState == .name)
    }
    
    private var nameSection: some View {
        Section {
            playlistNamePrompt
        } header: {
            Text("Playlist Name*".localized())
        }
    }
    
    private var emojiSection: some View {
        Section {
            emojiPrompt
        } header: {
            Text("Emoji ID*".localized())
        }
    }
    
    private var doneButton: some View {
        Button("Done".localized()) {
            focusState = nil
        }
    }
    
    private var saveButton: some View {
        Button("Save".localized()) {
            save()
            presentationMode.wrappedValue.dismiss()
        }
        .tint(.blue)
        .padding()
        .disabled(disableSave)
    }
    
    private var deleteButton: some View {
        Button("Delete".localized()) {
            showingAlert = true
        }
        .alert("Are you sure you want to delete playlist?".localized(), isPresented: $showingAlert) {
            Button("Delete".localized(), role: .destructive) {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .padding()
    }
    
    private var playlistNamePrompt: some View {
        TextField("Enter Playlist Name".localized(), text: $name)
            .focused($focusState, equals: .name)
            .submitLabel(.next)
            .onReceive(Just(name)) { _ in
                if (name.count > MaxCharLength.names) {
                    name = String(name.prefix(MaxCharLength.names))
                }
            }
    }
    
    private var emojiPrompt: some View {
        EmojiTextField(text: $emoji, placeholder: "Enter Emoji".localized())
            .focused($focusState, equals: .emoji)
            .submitLabel(.done)
            .onReceive(Just(emoji), perform: { _ in
                self.emoji = String(self.emoji.onlyEmoji().prefix(MaxCharLength.emojis))
            })
    }
    
    // MARK: - Functions
    
    private func save() {
        let newPlaylist = Playlist(context: CoreDataStack.shared.context)
        newPlaylist.id = UUID()
        newPlaylist.name = name
        newPlaylist.emoji = emoji
        CoreDataStack.shared.save()
    }
    
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
}
