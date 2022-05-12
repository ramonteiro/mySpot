//
//  PlaylistEditSheet.swift
//  My Spot
//
//  Created by Isaac Paschall on 3/15/22.
//

import SwiftUI
import Combine

struct PlaylistEditSheet: View {
    
    @ObservedObject var playlist: Playlist
    @Environment(\.managedObjectContext) var moc
    @Environment(\.presentationMode) var presentationMode
    @State private var name = ""
    @State private var emoji = ""
    @State private var exists = true
    
    private enum Field {
        case name
        case emoji
    }
    
    @FocusState private var focusState: Field?
    
    var body: some View {
        ZStack {
            if (exists) {
                NavigationView {
                    Form {
                        Section {
                            TextField("Enter Playlist Name".localized(), text: $name)
                                .onReceive(Just(name)) { _ in
                                    if (name.count > MaxCharLength.names) {
                                        name = String(name.prefix(MaxCharLength.names))
                                    }
                                }
                                .onAppear {
                                    name = playlist.name ?? ""
                                }
                                .focused($focusState, equals: .name)
                                .submitLabel(.next)
                        } header: {
                            Text("Playlist Name*".localized())
                        }
                        Section {
                            EmojiTextField(text: $emoji, placeholder: "Enter Emoji".localized())
                                .onReceive(Just(emoji), perform: { _ in
                                    self.emoji = String(self.emoji.onlyEmoji().prefix(MaxCharLength.emojis))
                                })
                                .onAppear {
                                    emoji = playlist.emoji ?? ""
                                }
                                .focused($focusState, equals: .emoji)
                                .submitLabel(.done)
                        } header: {
                            Text("Emoji*".localized())
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
                    .navigationTitle(name)
                    .toolbar {
                        ToolbarItemGroup(placement: .navigationBarLeading) {
                            Button("Cancel".localized()) {
                                name = ""
                                emoji = ""
                                presentationMode.wrappedValue.dismiss()
                            }
                            .padding(.leading)
                        }
                        ToolbarItemGroup(placement: .navigationBarTrailing) {
                            Button("Save".localized()) {
                                saveChanges()
                            }
                            .padding(.trailing)
                            .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || emoji.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .tint(.blue)
                        }
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
                                }
                                .disabled(focusState == .emoji)
                                Spacer()
                                Button("Done".localized()) {
                                    focusState = nil
                                }
                            }
                        }
                    }
                }
                .navigationViewStyle(.automatic)
            }
        }
        .onAppear {
            exists = checkExists()
        }
    }
    
    private func checkExists() -> Bool {
        guard let _ = playlist.name else {return false}
        guard let _ = playlist.emoji else {return false}
        return true
    }
 
    private func saveChanges() {
        playlist.name = name
        playlist.emoji = emoji
        CoreDataStack.shared.save()
        presentationMode.wrappedValue.dismiss()
    }
}
