//
//  ContentView.swift
//  IPlay
//
//  Created by Aswanth K on 01/07/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @StateObject private var vm = AudioTrackViewModel()
    
    @State private var title = ""
    @State private var artist = ""
    @State private var fileName = ""
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(vm.tracks, id: \.id) { track in
                        VStack(alignment: .leading) {
                            Text(track.title ?? "Unknown Title").font(.headline)
                            Text(track.artist ?? "Unknown Artist").font(.subheadline)
                            HStack {
                                Button("Play") {
                                    vm.play(track: track)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                
                                Button("Delete") {
                                    vm.deleteTrack(track)
                                }
                                .foregroundColor(.red)
                                .buttonStyle(BorderlessButtonStyle())
                            }
                        }
                    }
                }
                
                Form {
                    Section(header: Text("Add New Track")) {
                        TextField("Title", text: $title)
                        TextField("Artist", text: $artist)
                        TextField("File Name", text: $fileName)
                        Button("Add Track") {
                            guard !title.isEmpty, !artist.isEmpty, !fileName.isEmpty else { return }
                            vm.addTrack(title: title, artist: artist, fileName: fileName)
                            title = ""
                            artist = ""
                            fileName = ""
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("IPlay Audio Tracks")
        }
    }
}
