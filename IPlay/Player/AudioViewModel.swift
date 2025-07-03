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
    @Published var currentlyPlayingFile: String?
    @Published var isPlaying: Bool = false

    private let context = PersistenceController.shared.container.viewContext

    init() {
        configureAudioSession()
        preloadFromDocumentsIfNeeded()
        fetchTracks()
        NotificationCenter.default.addObserver(self,
                                                   selector: #selector(handleAudioInterruption),
                                                   name: AVAudioSession.interruptionNotification,
                                                   object: nil)
    }
    
    @objc func handleAudioInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        if type == .ended {
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    currentPlayer?.play()
                    isPlaying = true
                }
            }
        }
    }

    func fetchTracks() {
        let request: NSFetchRequest<AudioTrack> = AudioTrack.fetchRequest()
        do {
            tracks = try context.fetch(request)
        } catch {
            print("Fetch error: \(error)")
        }
    }

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

    func togglePlayback(for track: AudioTrack) {
        let fileName = track.fileName ?? ""
        let fileURL = FileManagerHelper.shared.getDocumentsDirectory().appendingPathComponent(fileName)

        if currentlyPlayingFile == fileName, let player = currentPlayer {
            if player.isPlaying {
                player.pause()
                isPlaying = false
            } else {
                player.play()
                isPlaying = true
            }
        } else {
            stopPlayback()
            do {
                currentPlayer = try AVAudioPlayer(contentsOf: fileURL)
                currentPlayer?.prepareToPlay()
                currentPlayer?.play()
                currentlyPlayingFile = fileName
                isPlaying = true
            } catch {
                print("Playback error: \(error)")
                isPlaying = false
            }
        }
    }

    func stopPlayback() {
        currentPlayer?.stop()
        currentPlayer = nil
        currentlyPlayingFile = nil
        isPlaying = false
    }

    func importAudioFiles(from pickedURLs: [URL]) {
        let documents = FileManagerHelper.shared.getDocumentsDirectory()

        for pickedURL in pickedURLs {
            let destinationURL = documents.appendingPathComponent(pickedURL.lastPathComponent)

            do {
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                try FileManager.default.copyItem(at: pickedURL, to: destinationURL)

                let track = AudioTrack(context: context)
                track.id = UUID()
                track.title = destinationURL.deletingPathExtension().lastPathComponent
                track.artist = "Unknown"
                track.fileName = destinationURL.lastPathComponent

            } catch {
                print("❌ Failed to import \(pickedURL.lastPathComponent): \(error.localizedDescription)")
            }
        }

        do {
            try context.save()
            fetchTracks()
        } catch {
            print("❌ Core Data save failed: \(error.localizedDescription)")
        }
    }
    
    func deleteTracks(at offsets: IndexSet) {
        DispatchQueue.main.async { // Ensure on main thread
            for index in offsets {
                let trackToDelete = self.tracks[index]

                if self.currentlyPlayingFile == trackToDelete.fileName {
                    self.stopPlayback()
                }

                self.context.delete(trackToDelete)
            }

            do {
                try self.context.save()
                self.fetchTracks()
            } catch {
                print("Failed to delete tracks: \(error)")
            }
        }
    }
}


func configureAudioSession() {
    let session = AVAudioSession.sharedInstance()
    do {
        try session.setCategory(.playback, mode: .default, options: [])
        try session.setActive(true)
    } catch {
        print("Failed to configure audio session: \(error)")
    }
}


//class AudioTrackViewModel: ObservableObject {
//    @Published var tracks: [AudioTrack] = []
//    
//    private let viewContext = PersistenceController.shared.container.viewContext
//    private var player: AVAudioPlayer?
//
//    init() {
//        fetchTracks()
//    }
//    
//    func fetchTracks() {
//        let request: NSFetchRequest<AudioTrack> = AudioTrack.fetchRequest()
//        do {
//            tracks = try viewContext.fetch(request)
//        } catch {
//            print("Failed to fetch tracks: \(error.localizedDescription)")
//        }
//    }
//    
//    func addTrack(title: String, artist: String, fileName: String) {
//        let newTrack = AudioTrack(context: viewContext)
//        newTrack.id = UUID()
//        newTrack.title = title
//        newTrack.artist = artist
//        newTrack.fileName = fileName
//        
//        saveContext()
//        fetchTracks()
//    }
//    
//    func deleteTrack(_ track: AudioTrack) {
//        viewContext.delete(track)
//        saveContext()
//        fetchTracks()
//    }
//    
//    func saveContext() {
//        do {
//            try viewContext.save()
//        } catch {
//            print("Failed to save context: \(error.localizedDescription)")
//        }
//    }
//    
//    func play(track: AudioTrack) {
//        guard let fileName = track.fileName else { return }
//        
//        let url = getDocumentsDirectory().appendingPathComponent(fileName)
//        do {
//            player = try AVAudioPlayer(contentsOf: url)
//            player?.play()
//        } catch {
//            print("Error playing audio file \(fileName): \(error.localizedDescription)")
//        }
//    }
//    
//    private func getDocumentsDirectory() -> URL {
//        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//    }
//}
