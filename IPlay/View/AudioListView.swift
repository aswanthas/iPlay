//
//  AudioListView.swift
//  IPlay
//
//  Created by Aswanth K on 01/07/25.
//

import SwiftUI

struct AudioListView: View {
    @StateObject private var viewModel = AudioViewModel()

    var body: some View {
        NavigationView {
            List(viewModel.tracks, id: \.self) { track in
                VStack(alignment: .leading) {
                    Text(track.title ?? "Untitled")
                        .font(.headline)
                    Text(track.artist ?? "Unknown Artist")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .onTapGesture {
                    viewModel.play(track: track)
                }
            }
            .navigationTitle("My Songs")
        }
    }
}


#Preview {
    AudioListView()
}
