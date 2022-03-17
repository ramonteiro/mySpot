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
    
    private var disableSave: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || emoji.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
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
            .onSubmit {
                switch focusState {
                case .name:
                    focusState = .emoji
                default:
                    focusState = nil
                }
            }
            .navigationTitle("Create Playlist")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    HStack {
                        Button {
                            switch focusState {
                            case .emoji:
                                focusState = .name
                            default:
                                focusState = nil
                            }
                        } label: {
                            Image(systemName: "chevron.up")
                                .tint(.blue)
                        }
                        .disabled(focusState == .name)
                        Button {
                            switch focusState {
                            case .name:
                                focusState = .emoji
                            default:
                                focusState = nil
                            }
                        } label: {
                            Image(systemName: "chevron.down")
                                .tint(.blue)
                        }
                        .disabled(focusState == .emoji)
                        Spacer()
                        doneButton
                            .tint(.blue)
                    }
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
        .tint(.blue)
        .padding()
        .disabled(disableSave)
    }
    
    private var deleteButton: some View {
        Button("Delete") {
            showingAlert = true
        }
        .alert("Are you sure you want to delete playlist?", isPresented: $showingAlert) {
            Button("Delete", role: .destructive) { close() }
                .tint(.blue)
        }
        .padding()
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
