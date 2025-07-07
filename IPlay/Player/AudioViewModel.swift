//
//  AudioViewModel.swift
//  IPlay
//
//  Created by Aswanth K on 01/07/25.
//

import Foundation
import CoreData
import AVFoundation
import MediaPlayer

class AudioViewModel: NSObject, ObservableObject {
    @Published var tracks: [AudioTrack] = []
    @Published var currentPlayer: AVAudioPlayer?
    @Published var currentTrack: AudioTrack?
    @Published var currentlyPlayingFile: String?
    @Published var isPlaying: Bool = false

    private let context = PersistenceController.shared.container.viewContext

    override init() {
        super.init()
        configureAudioSession()
        setupRemoteTransportControls()
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
            // 🔁 Update Now Playing Info when resuming or pausing
            updateNowPlayingInfo(for: track)
        } else {
            stopPlayback()
            do {
                currentPlayer = try AVAudioPlayer(contentsOf: fileURL)
                currentPlayer?.delegate = self
                currentPlayer?.prepareToPlay()
                currentPlayer?.play()
                currentlyPlayingFile = fileName
                currentTrack = track
                isPlaying = true
                // 🔁 Update Now Playing Info when resuming or pausing
                updateNowPlayingInfo(for: track)
            } catch {
                print("Playback error: \(error)")
                isPlaying = false
            }
        }
    }
    
    func playNextTrack() {
        guard let current = currentTrack,
              let index = tracks.firstIndex(of: current),
              index + 1 < tracks.count else {
            return
        }
        let nextTrack = tracks[index + 1]
        togglePlayback(for: nextTrack)
    }
    
    func playPreviousTrack() {
        guard let current = currentTrack,
              let index = tracks.firstIndex(of: current),
              index > 0 else {
            return
        }

        let previousTrack = tracks[index - 1]
        togglePlayback(for: previousTrack)
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
    
    func updateNowPlayingInfo(for track: AudioTrack) {
        var nowPlayingInfo: [String: Any] = [:]

        nowPlayingInfo[MPMediaItemPropertyTitle] = track.title ?? "Unknown Title"
        nowPlayingInfo[MPMediaItemPropertyArtist] = track.artist ?? "Unknown Artist"

        if let player = currentPlayer {
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = player.duration
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.isPlaying ? 1.0 : 0.0
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    // handle the previous track button on the lock screen / Control Center:
    func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [weak self] event in
            guard let self = self,
                  let track = self.currentTrack else { return .commandFailed }
            self.currentPlayer?.play()
            self.isPlaying = true
            self.updateNowPlayingInfo(for: track)
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] event in
            self?.currentPlayer?.pause()
            self?.isPlaying = false
            if let track = self?.currentTrack {
                self?.updateNowPlayingInfo(for: track)
            }
            return .success
        }

        commandCenter.nextTrackCommand.addTarget { [weak self] event in
            self?.playNextTrack()
            return .success
        }

        commandCenter.previousTrackCommand.addTarget { [weak self] event in
            self?.playPreviousTrack()
            return .commandFailed
        }
    }

}

extension AudioViewModel: AVAudioPlayerDelegate {
    // MARK: - Auto-play Next Track
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard let currentFileName = currentlyPlayingFile else { return }
        
        if let currentIndex = tracks.firstIndex(where: { $0.fileName == currentFileName }),
           currentIndex + 1 < tracks.count {
            let nextTrack = tracks[currentIndex + 1]
            togglePlayback(for: nextTrack)
        } else {
            // No more tracks — stop
            stopPlayback()
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
