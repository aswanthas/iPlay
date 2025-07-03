//
//  AudioViewModel.swift
//  IPlay
//
//  Created by Aswanth K on 01/07/25.
//

import Foundation
import CoreData
import AVFoundation

class AudioViewModel: ObservableObject {
    @Published var tracks: [AudioTrack] = []
    @Published var currentPlayer: AVAudioPlayer?

    private let context = PersistenceController.shared.container.viewContext

    init() {
        preloadFromDocumentsIfNeeded()
        fetchTracks()
    }

    /// Step 1: Fetch from Core Data
    func fetchTracks() {
        let request: NSFetchRequest<AudioTrack> = AudioTrack.fetchRequest()
        do {
            tracks = try context.fetch(request)
        } catch {
            print("Fetch error: \(error)")
        }
    }

    /// Step 2: First-time preload from `Documents` folder
    func preloadFromDocumentsIfNeeded() {
        let existingCount = (try? context.count(for: AudioTrack.fetchRequest())) ?? 0
        guard existingCount == 0 else { return }

        let audioFiles = FileManagerHelper.shared.listAudioFiles()

        for fileURL in audioFiles {
            let track = AudioTrack(context: context)
            track.id = UUID()
            track.title = fileURL.deletingPathExtension().lastPathComponent
            track.artist = "Unknown"
            track.fileName = fileURL.lastPathComponent
        }

        do {
            try context.save()
        } catch {
            print("CoreData Save error: \(error)")
        }
    }

    /// Step 3: Play audio file
    func play(track: AudioTrack) {
        let fileURL = FileManagerHelper.shared.getDocumentsDirectory().appendingPathComponent(track.fileName ?? "")
        do {
            currentPlayer = try AVAudioPlayer(contentsOf: fileURL)
            currentPlayer?.prepareToPlay()
            currentPlayer?.play()
        } catch {
            print("Playback error: \(error)")
        }
    }
}



class AudioTrackViewModel: ObservableObject {
    @Published var tracks: [AudioTrack] = []
    
    private let viewContext = PersistenceController.shared.container.viewContext
    private var player: AVAudioPlayer?

    init() {
        fetchTracks()
    }
    
    func fetchTracks() {
        let request: NSFetchRequest<AudioTrack> = AudioTrack.fetchRequest()
        do {
            tracks = try viewContext.fetch(request)
        } catch {
            print("Failed to fetch tracks: \(error.localizedDescription)")
        }
    }
    
    func addTrack(title: String, artist: String, fileName: String) {
        let newTrack = AudioTrack(context: viewContext)
        newTrack.id = UUID()
        newTrack.title = title
        newTrack.artist = artist
        newTrack.fileName = fileName
        
        saveContext()
        fetchTracks()
    }
    
    func deleteTrack(_ track: AudioTrack) {
        viewContext.delete(track)
        saveContext()
        fetchTracks()
    }
    
    func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Failed to save context: \(error.localizedDescription)")
        }
    }
    
    func play(track: AudioTrack) {
        guard let fileName = track.fileName else { return }
        
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
        } catch {
            print("Error playing audio file \(fileName): \(error.localizedDescription)")
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
