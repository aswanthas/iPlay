//
//  AudioListView.swift
//  IPlay
//
//  Created by Aswanth K on 01/07/25.
//

import SwiftUI

struct AudioListView: View {
    @ObservedObject var viewModel: AudioViewModel
    @State private var showFilePicker = false
    @State private var showFullScreenPlayer = false

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                List {
                    ForEach(viewModel.tracks, id: \.self) { track in
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
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
//                        .listRowInsets(.init(top: 8, leading: 0, bottom: 8, trailing: 0))
                        .padding(.vertical, 2)
                        .onTapGesture {
                            viewModel.togglePlayback(for: track)
                        }
                    }
                    .onDelete(perform: viewModel.deleteTracks)
                }
                .listStyle(.plain)
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
            .fullScreenCover(isPresented: $showFullScreenPlayer) {
                FullScreenPlayerView(viewModel: viewModel)
                    .ignoresSafeArea()
                    .presentationDragIndicator(.visible) // shows the swipe-down indicator
            }
        }
    }
}




#Preview {
    AudioListView(viewModel: AudioViewModel())
}
