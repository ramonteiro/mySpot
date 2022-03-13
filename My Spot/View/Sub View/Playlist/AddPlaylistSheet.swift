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
    @Environment(\.managedObjectContext) var moc
    
    @State private var showingAlert = false
    @State private var name = ""
    @State private var emoji = ""
    @State private var isEmoji: Bool = true
    
    enum Field {
        case emoji
        case name
    }
    
    @FocusState private var focusState: Field?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Playlist Name")) {
                    playlistNamePrompt
                }
                Section(header: Text("Emoji ID")) {
                    emojiPrompt
                }
            }
            .accentColor(.red)
            .navigationTitle("Create Playlist")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    doneButton
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    saveButton
                }
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    deleteButton
                }
            }
        }
        .interactiveDismissDisabled()
    }

    func close() {
        presentationMode.wrappedValue.dismiss()
    }
    
    func save() {
        let newPlaylist = Playlist(context: moc)
        newPlaylist.id = UUID()
        newPlaylist.name = name
        newPlaylist.emoji = emoji
        try? moc.save()
    }
    
    private var doneButton: some View {
        Button("Done") {
            focusState = nil
        }
    }
    
    private var saveButton: some View {
        Button("Save") {
            save()
            close()
        }
        .padding()
        .disabled(name == "" || emoji == "")
    }
    
    private var deleteButton: some View {
        Button("Delete") {
            showingAlert = true
        }
        .alert("Are you sure you want to delete playlist?", isPresented: $showingAlert) {
            Button("Yes", role: .destructive) { close() }
        }
        .padding()
        .accentColor(.red)
    }
    
    private var playlistNamePrompt: some View {
        TextField("Enter Playlist Name", text: $name)
            .focused($focusState, equals: .name)
            .submitLabel(.next)
            .onReceive(Just(name)) { _ in
                if (name.count > MaxCharLength.names) {
                    name = String(name.prefix(MaxCharLength.names))
                }
            }
    }
    
    private var emojiPrompt: some View {
        EmojiTextField(text: $emoji, placeholder: "Enter Emoji")
            .focused($focusState, equals: .emoji)
            .submitLabel(.done)
            .onReceive(Just(emoji), perform: { _ in
                self.emoji = String(self.emoji.onlyEmoji().prefix(MaxCharLength.emojis))
            })
    }
}
