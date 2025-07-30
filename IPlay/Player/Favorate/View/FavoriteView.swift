//
//  FavoriteView.swift
//  IPlay
//
//  Created by Aswanth K on 26/07/25.
//

import SwiftUI

struct FavoriteView: View {
    @EnvironmentObject var viewModel: AudioViewModel
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.favoriteTracks, id: \.self) { track in
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
                            Image(systemName: (viewModel.currentlyPlayingFile == track.fileName && viewModel.isPlaying) ?
                                  "pause.fill" : "play.fill")
                            .foregroundStyle((viewModel.currentlyPlayingFile == track.fileName && viewModel.isPlaying) ?
                                .orange : .white)
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
            .navigationTitle("Favorite Songs")
        }
    }
}

#Preview {
    FavoriteView().environmentObject(AudioViewModel())
}
