//
//  MiniPlayer.swift
//  IPlay
//
//  Created by Aswanth K on 07/07/25.
//

import SwiftUI

struct MiniPlayer: View {
    let track: AudioTrack
    let isPlaying: Bool
    let onPlayPause: () -> Void
    let onNext: () -> Void
    var body: some View {
        HStack {
            Image(systemName: "music.note") // or use Image("music_placeholder")
                .resizable()
                .scaledToFit()
                .frame(width: 25, height: 25)
                .padding(6)
                .background(Color.white.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.trailing, 8)
            Text(track.title ?? "Unknown")
                .font(.subheadline)
                .lineLimit(1)
            Spacer()
            Button(action: onPlayPause) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2)
                    .foregroundStyle(Color.white)
            }
            
            Button(action: onNext) {
                Image(systemName: "forward.fill")
                    .font(.title2)
                    .foregroundStyle(Color.white)
            }
        }
        .padding()
        .background(Color(.systemGray4))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
        .padding(.bottom, 10)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
