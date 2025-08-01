//
//  LibraryView.swift
//  IPlay
//
//  Created by Aswanth K on 11/07/25.
//

import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var viewModel: AudioViewModel
    @State private var showAddPlaylist = false
    @State private var newPlaylistName = ""
    @State private var selectedPlaylist: Playlist? = nil

    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(viewModel.playlists, id: \.self) { playlist in
                            NavigationLink {
                                PlaylistDetailView(playlist: playlist)
                                    .environmentObject(viewModel)
                            } label: {
                                VStack {
                                    Text(playlist.name ?? "Untitled")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                        .padding()
                                }
                                .frame(maxWidth: .infinity, minHeight: 100)
                                .background(Color.orange.opacity(0.15))
                                .cornerRadius(16)
                                .shadow(radius: 2)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Playlists")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddPlaylist = true }) {
                        Label("Add Playlist", systemImage: "plus")
                    }
                }
            }
            .alert("New Playlist", isPresented: $showAddPlaylist, actions: {
                TextField("Playlist Name", text: $newPlaylistName)
                Button("Create") {
                    if !newPlaylistName.trimmingCharacters(in: .whitespaces).isEmpty {
                        viewModel.createPlaylist(named: newPlaylistName)
                        newPlaylistName = ""
                    }
                }
                Button("Cancel", role: .cancel) {
                    newPlaylistName = ""
                }
            })
            .onAppear {
                viewModel.fetchPlaylists()
            }
        }
    }
}


struct PlaylistDetailView: View {
    @EnvironmentObject var viewModel: AudioViewModel
    var playlist: Playlist

    var body: some View {
        VStack {
            List {
                ForEach((playlist.tracks?.allObjects as? [AudioTrack]) ?? [], id: \.self) { track in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(track.title ?? "Untitled")
                                .font(.headline)
                                .lineLimit(1)
                            Text(track.fileName ?? "")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                        Spacer()
                        Button(action: {
                            viewModel.togglePlayback(for: track)
                        }) {
                            Image(systemName: (viewModel.currentlyPlayingFile == track.fileName && viewModel.isPlaying) ? "pause.fill" : "play.fill")
                                .foregroundColor(.orange)
                        }
                    }
                    .contentShape(Rectangle())
                    .padding(.vertical, 2)
                    .onTapGesture {
                        viewModel.togglePlayback(for: track)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle(playlist.name ?? "Playlist")
        }
        .toolbar(.hidden, for: .tabBar)
    }
}

#Preview {
    LibraryView().environmentObject(AudioViewModel())
}
