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
    
    @FocusState private var nameIsFocused: Bool
    @FocusState private var emojiIsFocused: Bool

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Playlist Name")) {
                    displayPlaylistNamePrompt
                }
                Section(header: Text("Emoji ID")) {
                    displayEmojiPrompt
                }
            }
            .accentColor(.red)
            .navigationTitle("Create Playlist")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Button("Done") {
                        nameIsFocused = false
                        emojiIsFocused = false
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("Save") {
                        save()
                        close()
                    }
                    .padding()
                    .disabled(name == "" || emoji == "")
                }
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button("Delete") {
                        showingAlert = true
                    }
                    .alert("Are you sure you want to delete playlist?", isPresented: $showingAlert) {
                        Button("Yes", role: .destructive) { close() }
                    }
                    .padding()
                    .accentColor(.red)
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
    
    private var displayPlaylistNamePrompt: some View {
        TextField("Enter Playlist Name", text: $name)
            .focused($nameIsFocused)
            .onReceive(Just(name)) { _ in
                if (name.count > MaxCharLength.names) {
                    name = String(name.prefix(MaxCharLength.names))
                }
            }
    }
    
    private var displayEmojiPrompt: some View {
        EmojiTextField(text: $emoji, placeholder: "Enter Emoji")
            .onReceive(Just(emoji), perform: { _ in
                self.emoji = String(self.emoji.onlyEmoji().prefix(MaxCharLength.emojis))
            })
            .focused($emojiIsFocused)
    }
}
