//
//  AudioListView.swift
//  IPlay
//
//  Created by Aswanth K on 01/07/25.
//

import SwiftUI

struct AudioListView: View {
    @StateObject private var viewModel = AudioViewModel()
    @State private var showFilePicker = false

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.tracks, id: \.self) { track in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(track.title ?? "Untitled")
                                .font(.headline)
                            Text(track.fileName ?? "")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Button(action: {
                            viewModel.togglePlayback(for: track)
                        }) {
                            Image(systemName: (viewModel.currentlyPlayingFile == track.fileName && viewModel.isPlaying) ? "pause.fill" : "play.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .onDelete(perform: viewModel.deleteTracks)
            }
            .navigationTitle("My Audio Tracks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showFilePicker = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showFilePicker) {
                FilePicker { urls in
                    viewModel.importAudioFiles(from: urls)
                }
            }
        }
    }
}


#Preview {
    AudioListView()
}
