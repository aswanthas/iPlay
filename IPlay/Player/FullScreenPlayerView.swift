//
//  FullScreenPlayerView.swift
//  IPlay
//
//  Created by Aswanth K on 08/07/25.
//

import SwiftUI

struct FullScreenPlayerView: View {
    @ObservedObject var viewModel: AudioViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var currentTime: TimeInterval = 0
    @State private var isSeeking = false

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Spacer()
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundStyle(.primary)
                        .padding()
                }
            }.padding(.horizontal)
            Spacer()

            // Album Art
            Image(systemName: "music.note")
                .resizable()
                .scaledToFit()
                .frame(width: 280, height: 280)
                .cornerRadius(12)
                .shadow(radius: 8)

            // Title & Artist
            VStack {
                Text(viewModel.currentTrack?.title ?? "Unknown Title")
                    .font(.title2)
                    .bold()
                    .lineLimit(1)

                Text(viewModel.currentTrack?.artist ?? "Unknown Artist")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Progress & Slider
            VStack(spacing: 4) {
                Slider(
                    value: Binding(
                        get: {
                            isSeeking ? currentTime : viewModel.currentPlayer?.currentTime ?? 0
                        },
                        set: { newValue in
                            currentTime = newValue
                            isSeeking = true
                        }
                    ),
                    in: 0...(viewModel.currentPlayer?.duration ?? 1),
                    onEditingChanged: { editing in
                        if !editing, let player = viewModel.currentPlayer {
                            player.currentTime = currentTime
                            viewModel.updateNowPlayingInfo(for: viewModel.currentTrack!)
                            isSeeking = false
                        }
                    }
                )

                HStack {
                    Text(timeString(viewModel.currentPlayer?.currentTime ?? 0))
                    Spacer()
                    Text(timeString(viewModel.currentPlayer?.duration ?? 0))
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            // Playback Controls
            HStack(spacing: 40) {
                Button(action: viewModel.playPreviousTrack) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 32))
                }

                Button(action: {
                    if let track = viewModel.currentTrack {
                        viewModel.togglePlayback(for: track)
                    }
                }) {
                    Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 52))
                }

                Button(action: viewModel.playNextTrack) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 32))
                }
            }
            .padding(.top, 16)

            Spacer()
        }
        .padding()
        .interactiveDismissDisabled(true)
        .onReceive(viewModel.currentPlayerTimer) { _ in
            if !isSeeking {
                currentTime = viewModel.currentPlayer?.currentTime ?? 0
            }
        }
    }

    func timeString(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
